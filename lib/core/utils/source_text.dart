/// Choose real localized source text without inventing or rewriting CMS content.
String firstSourceText(Iterable<Object?> candidates) {
  for (final value in candidates) {
    if (value is String && value.trim().isNotEmpty) return value;
  }
  return '';
}
