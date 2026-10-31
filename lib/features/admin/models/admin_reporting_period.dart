/// Source contract: inclusive calendar dates in Asia/Dubai (UTC+4).
class AdminReportingPeriod {
  const AdminReportingPeriod(this.from, this.to);
  final String from, to;

  static DateTime parse(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Use YYYY-MM-DD');
    }
    final date = DateTime.tryParse(value);
    if (date == null || format(date) != value) {
      throw const FormatException('Invalid calendar date');
    }
    return date;
  }

  static String format(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime dubaiToday() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 4));
    return DateTime(now.year, now.month, now.day);
  }

  static void validate(String? from, String? to) {
    final start = from == null ? null : parse(from);
    final end = to == null ? null : parse(to);
    if (start != null && end != null && start.isAfter(end)) {
      throw const FormatException('Start must precede end');
    }
  }
}
