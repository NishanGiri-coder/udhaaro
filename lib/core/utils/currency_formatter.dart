// lib/core/utils/currency_formatter.dart
class CurrencyFormatter {
  static String formatNPR(double amount) {
    String valueStr = amount.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))');
    String mathFunc(Match match) => '${match[1]},';
    String formatted = valueStr.replaceAllMapped(reg, mathFunc);
    return 'रु $formatted';
  }
}