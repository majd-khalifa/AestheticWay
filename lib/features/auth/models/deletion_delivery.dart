/// Show only server-provided masked destinations. Never derive one from profile
/// contact data or retain an unexpected raw destination/OTP in UI state.
class DeletionDelivery {
  const DeletionDelivery(this.channel, this.destination);
  final String channel, destination;
  static List<DeletionDelivery> parse(Map<String, dynamic> data) {
    final rows = data['deliveries'];
    final candidates = rows is List && rows.isNotEmpty
        ? rows
        : [
            {
              'channel': data['delivery_channel'],
              'masked_destination': data['masked_destination'],
            },
          ];
    final result = <DeletionDelivery>[];
    for (final raw in candidates) {
      if (raw is! Map || !['sms', 'email'].contains(raw['channel'])) continue;
      final value = raw['masked_destination'];
      if (value is! String ||
          value.length > 120 ||
          !RegExp(r'[*•…]{2,}').hasMatch(value) ||
          RegExp(
            r'[\x00-\x1F\x7F\u202A-\u202E\u2066-\u2069<>/\\]',
          ).hasMatch(value)) {
        continue;
      }
      if (!result.any(
        (d) => d.channel == raw['channel'] && d.destination == value,
      )) {
        result.add(DeletionDelivery(raw['channel'] as String, value));
      }
    }
    return result;
  }
}
