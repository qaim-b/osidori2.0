import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/supabase_client.dart';

class ReceiptScan {
  final double? amount;
  final String currency;
  final DateTime? date;
  final String? categoryId;
  final String? merchant;
  final bool needsReview;
  final String? reviewReason;

  const ReceiptScan({
    required this.amount,
    required this.currency,
    required this.date,
    required this.categoryId,
    required this.merchant,
    required this.needsReview,
    required this.reviewReason,
  });

  factory ReceiptScan.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final amount = rawAmount is num ? rawAmount.toDouble() : null;
    if (amount != null && (!amount.isFinite || amount <= 0)) {
      throw const FormatException('The receipt total could not be read.');
    }
    final currency = json['currency'] as String? ?? '';
    if (!['JPY', 'MYR'].contains(currency)) {
      throw const FormatException(
        'This receipt currency is not supported yet.',
      );
    }
    final rawDate = json['date'] as String?;
    DateTime? date;
    if (rawDate != null) {
      date = DateTime.tryParse(rawDate);
      if (date == null || date.toIso8601String().substring(0, 10) != rawDate) {
        throw const FormatException('The receipt date could not be read.');
      }
    }
    return ReceiptScan(
      amount: amount,
      currency: currency,
      date: date,
      categoryId: json['category_id'] as String?,
      merchant: json['merchant'] as String?,
      needsReview: json['needs_review'] != false,
      reviewReason: json['review_reason'] as String?,
    );
  }
}

class ReceiptScanner {
  Future<ReceiptScan> scan(Uint8List bytes) async {
    if (bytes.length > 6 * 1024 * 1024) {
      throw const FormatException('Choose a receipt photo smaller than 6 MB.');
    }
    final mime = bytes.length >= 3 && bytes[0] == 0xff && bytes[1] == 0xd8
        ? 'image/jpeg'
        : bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50
        ? 'image/png'
        : bytes.length >= 12 &&
              ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP'
        ? 'image/webp'
        : null;
    if (mime == null) {
      throw const FormatException('Choose a JPEG, PNG, or WebP receipt photo.');
    }
    try {
      final response = await AppSupabase.client.functions.invoke(
        'scan-receipt',
        body: {'image': base64Encode(bytes), 'mime_type': mime},
      );
      return ReceiptScan.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map ? details['error'] : null;
      throw FormatException(
        message is String
            ? message
            : 'Receipt scanning is unavailable. You can still enter this purchase manually.',
      );
    }
  }
}
