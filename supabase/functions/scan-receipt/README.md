# Receipt scanning

The Flutter purchase screen sends a JPEG/PNG/WebP photo to this authenticated
Supabase Edge Function. It reads the signed-in user's enabled expense categories
under their existing RLS permissions, then uses OpenAI image input and structured
output. The response supplies the receipt total, purchase date, store name, and an
existing category ID. It never creates new categories or inserts transactions.

The app uses the existing transaction save path. Clear, complete results save
automatically; uncertain or mixed-category receipts open for review. The store is
saved in the existing note field, preserving monthly Excel exports. The original
photo is displayed during review but is not permanently stored as an attachment.

## Setup

Install and authenticate the Supabase CLI, link this project, then:

```powershell
supabase secrets set OPENAI_API_KEY=<your-server-side-key>
supabase functions deploy scan-receipt
```

Optionally set `RECEIPT_MODEL` to a model supporting image input and JSON Schema
structured output. The default is `gpt-4.1-mini`. Do not put the API key in Flutter
code or public build variables. The function explicitly verifies the user's access
token, as well as using the gateway's default JWT verification. No database
migration is needed for this feature.

Photos are sent to OpenAI for extraction with `store: false`. Review the deployment
and API account's usage limits before enabling scanning for a wider audience.

## Verification

Use a signed-in test account with enabled categories. Check Japanese receipts with
tax, discounts, cash tendered and change; the charged total must be selected.
Check mixed food/household receipts, unreadable dates, non-receipts, permission
denial, missing server configuration, cancellation, and unavailable network.
Do not auto-save an uncertain result. A retry after a scan failure must not insert
a transaction; insertion occurs only through the app's existing save method.

API references: [image inputs](https://developers.openai.com/api/docs/guides/images-vision)
and [structured output](https://developers.openai.com/api/docs/guides/structured-outputs).
