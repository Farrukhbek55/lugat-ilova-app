class Definition {
  final String text;
  final String language; // 'en' yoki 'ru'
  final String exampleSource;
  final String exampleTarget;

  const Definition({
    required this.text,
    required this.language,
    this.exampleSource = '',
    this.exampleTarget = '',
  });
}

class DictionaryEntry {
  final int id;
  final String word;
  final String wordCyrillic;
  final String partOfSpeech;
  final String pronunciation;
  final List<Definition> definitions;

  DictionaryEntry({
    required this.id,
    required this.word,
    this.wordCyrillic = '',
    this.partOfSpeech = '',
    this.pronunciation = '',
    this.definitions = const [],
  });

  List<Definition> get enDefinitions =>
      definitions.where((d) => d.language == 'en').toList();

  List<Definition> get ruDefinitions =>
      definitions.where((d) => d.language == 'ru').toList();

  String get mainDefinition =>
      enDefinitions.isNotEmpty ? enDefinitions.first.text : '';

  Definition? get exampleDefinition => definitions.firstWhere(
        (d) => d.exampleSource.isNotEmpty,
        orElse: () => const Definition(text: '', language: 'en'),
      );
}
