/// Formats a server-provided amount for display. Formatting only — the app
/// never calculates money.
String formatMoney(double amount, [String? currency]) {
  final code = (currency ?? 'usd').trim().toLowerCase();
  final fixed = amount.toStringAsFixed(2);
  switch (code) {
    case '':
    case 'usd':
      return '\$$fixed';
    case 'eur':
      return '€$fixed';
    case 'gbp':
      return '£$fixed';
    default:
      return '${code.toUpperCase()} $fixed';
  }
}

/// Formats a server percent value (e.g. 25 → "25%", 12.5 → "12.5%").
String formatPercent(double percent) {
  final whole = percent == percent.roundToDouble();
  return '${whole ? percent.toStringAsFixed(0) : percent.toString()}%';
}
