import 'package:intl/intl.dart';

class AppFormatters {
  static String currency(double amount, {String code = 'USD'}) {
    final symbol = switch (code.toUpperCase()) {
      'USD' => r'$',
      'ZAR' => 'R',
      'ZWL' || 'ZIG' => 'ZiG ',
      'GBP' => '£',
      'EUR' => '€',
      _ => '$code ',
    };
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String compactCurrency(double amount, {String code = 'USD'}) {
    final symbol = code.toUpperCase() == 'USD' ? r'$' : '$code ';
    if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  static String km(double distance) {
    return '${NumberFormat('#,##0.#').format(distance)} km';
  }

  static String date(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);

  static String shortDate(DateTime dt) => DateFormat('dd MMM').format(dt);

  static String monthYear(DateTime dt) => DateFormat('MMM yyyy').format(dt);

  static String invoiceNumber(int counter, DateTime date) {
    final padded = counter.toString().padLeft(4, '0');
    return 'INV-${date.year}-$padded';
  }
}
