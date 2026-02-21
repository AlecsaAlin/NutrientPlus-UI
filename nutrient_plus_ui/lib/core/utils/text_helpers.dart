class TextHelpers {
  static String cleanText(String text) {
    String cleaned = text;
    if (cleaned.startsWith('c(') ||
        cleaned.startsWith('c"') ||
        cleaned.startsWith("c'")) {
      cleaned = cleaned.substring(1);
    }
    cleaned = cleaned.replaceAll('"', '').replaceAll("'", '');
    if (cleaned.startsWith('(') && cleaned.endsWith(')')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    return cleaned.trim();
  }

  static List<String> parseIngredients(String ingredients) {
    String cleaned = cleanText(ingredients);
    return cleaned
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String cleanIngredients(String ingredients) {
    final items = parseIngredients(ingredients);
    if (items.isEmpty) return '';
    return items.map((e) => '\u2022 $e').join('\n');
  }

  static String cleanInstructions(String instructions) {
    String cleaned = cleanText(instructions);
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\.\s*,?\s*'),
      (match) => '.\n\n',
    );
    return cleaned.trim();
  }
}
