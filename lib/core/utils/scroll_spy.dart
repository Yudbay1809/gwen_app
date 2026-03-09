enum ScrollSection { overview, ingredients, reviews, qa }

ScrollSection pickBestSection(Map<ScrollSection, double> visibilityRatios) {
  if (visibilityRatios.isEmpty) return ScrollSection.overview;
  final entries = visibilityRatios.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.first.key;
}
