import { handleReceipt } from "./index.ts";

function assert(
  condition: unknown,
  message = "Assertion failed",
): asserts condition {
  if (!condition) throw new Error(message);
}

const clearReceipt = {
  amount: 2480,
  currency: "JPY",
  date: "2026-10-26",
  merchant: "OK Store",
  category_id: "home-cooking",
  needs_review: false,
  review_reason: null,
};

async function withServer(test: () => Promise<void>, receipt = clearReceipt) {
  const originalFetch = globalThis.fetch;
  const variables = ["SUPABASE_URL", "SUPABASE_ANON_KEY", "OPENAI_API_KEY"];
  const before = variables.map((name) => Deno.env.get(name));
  Deno.env.set("SUPABASE_URL", "https://receipt-test.invalid");
  Deno.env.set("SUPABASE_ANON_KEY", "test-anon");
  Deno.env.set("OPENAI_API_KEY", "test-key");
  globalThis.fetch = (input, init) => {
    const url = String(input);
    if (url.endsWith("/auth/v1/user")) {
      return Promise.resolve(Response.json({ id: "user-1" }));
    }
    if (url.includes("/rest/v1/categories")) {
      assert(
        url.includes("user_id=eq.user-1"),
        "Categories must belong to the signed-in user",
      );
      assert(
        init?.headers &&
          (init.headers as Record<string, string>).Authorization ===
            "Bearer test-user",
      );
      return Promise.resolve(
        Response.json([{ id: "home-cooking", name: "Home Cooking" }]),
      );
    }
    if (url === "https://api.openai.com/v1/responses") {
      const body = JSON.parse(init!.body as string);
      assert(body.store === false);
      assert(body.text.format.strict === true);
      assert(
        body.text.format.schema.properties.category_id.enum.includes(
          "home-cooking",
        ),
      );
      return Promise.resolve(Response.json({
        status: "completed",
        output: [
          { content: [{ type: "output_text", text: JSON.stringify(receipt) }] },
        ],
      }));
    }
    throw new Error(`Unexpected request ${url}`);
  };
  try {
    await test();
  } finally {
    globalThis.fetch = originalFetch;
    variables.forEach((name, i) => {
      if (before[i] === undefined) Deno.env.delete(name);
      else Deno.env.set(name, before[i]!);
    });
  }
}

const photoRequest = (
  body: unknown = { image: "/9j/AA==", mime_type: "image/jpeg" },
) =>
  new Request("https://receipt-test.invalid/scan-receipt", {
    method: "POST",
    headers: {
      Authorization: "Bearer test-user",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

Deno.test("scan requires authentication", async () => {
  const result = await handleReceipt(
    new Request("https://receipt-test.invalid", { method: "POST" }),
  );
  assert(result.status === 401);
  await result.body?.cancel();
});

Deno.test("missing API key gives an actionable error", () =>
  withServer(async () => {
    Deno.env.delete("OPENAI_API_KEY");
    const result = await handleReceipt(photoRequest());
    assert(result.status === 503);
    assert((await result.json()).error.includes("not configured"));
  }));

Deno.test("complete receipt preserves category, date, note and exact total", () =>
  withServer(async () => {
    const result = await handleReceipt(photoRequest());
    assert(result.status === 200);
    const receipt = await result.json();
    assert(receipt.amount === 2480 && receipt.category_id === "home-cooking");
    assert(receipt.date === "2026-10-26" && receipt.merchant === "OK Store");
    assert(receipt.needs_review === false);
  }));

Deno.test("invalid photos are rejected before invoking the image reader", () =>
  withServer(async () => {
    const result = await handleReceipt(
      photoRequest({ image: "invalid!", mime_type: "image/jpeg" }),
    );
    assert(result.status === 400);
    await result.body?.cancel();
  }));

Deno.test("unknown category forces review instead of automatic insertion", () =>
  withServer(async () => {
    const result = await handleReceipt(photoRequest());
    const receipt = await result.json();
    assert(receipt.category_id === null && receipt.needs_review === true);
  }, { ...clearReceipt, category_id: "invented-category" }));

Deno.test("invalid date forces review", () =>
  withServer(async () => {
    const result = await handleReceipt(photoRequest());
    const receipt = await result.json();
    assert(receipt.date === null && receipt.needs_review === true);
  }, { ...clearReceipt, date: "2026-02-30" }));

Deno.test("fractional yen total forces review without rounding money", () =>
  withServer(async () => {
    const result = await handleReceipt(photoRequest());
    const receipt = await result.json();
    assert(receipt.amount === null && receipt.needs_review === true);
  }, { ...clearReceipt, amount: 2480.5 }));

Deno.test("mixed category review survives extraction", () =>
  withServer(async () => {
    const result = await handleReceipt(photoRequest());
    assert((await result.json()).needs_review === true);
  }, { ...clearReceipt, needs_review: true }));
