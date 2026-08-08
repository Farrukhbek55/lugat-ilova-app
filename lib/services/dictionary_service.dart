import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/dictionary_entry.dart';

class DictionaryService {
  static final DictionaryService _instance = DictionaryService._internal();
  factory DictionaryService() => _instance;
  DictionaryService._internal();

  Database? _db;
  int _totalWords = 0;

  bool get isLoaded => _db != null;
  int get totalWords => _totalWords;

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  // Keraksiz ta'rif shablonlari
  static const _badPrefixes = [
    'Cyrillic', 'Synonym', 'Alternative', 'plural', 'plural of',
    'past tense', 'genitive', 'dative', 'accusative', 'locative',
  ];

  Future<void> load() async {
    if (_db != null) return;
    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docDir.path, 'topsoz.db');
    final dbFile = File(dbPath);

    final bool needsCopy = !dbFile.existsSync();

    if (needsCopy) {
      if (dbFile.existsSync()) await dbFile.delete();
      _progressController.add(0.1);
      final data = await rootBundle.load('assets/topsoz.db');
      _progressController.add(0.5);
      await File(dbPath).writeAsBytes(
          data.buffer.asUint8List(), flush: true);
      _progressController.add(1.0);
    }

    _db = await openDatabase(dbPath, readOnly: false);
    try {
      await _db!.execute('PRAGMA cache_size = 10000');
      await _db!.execute('PRAGMA temp_store = MEMORY');
      await _db!.execute('PRAGMA mmap_size = 268435456');
    } catch (_) {}

    final res = await _db!.rawQuery('SELECT COUNT(*) as c FROM words');
    _totalWords = (res.first['c'] as int?) ?? 0;
  }

  Future<List<DictionaryEntry>> search(String query,
      {bool uzToEn = true}) async {
    if (_db == null || query.trim().isEmpty) return [];
    final q = '${query.trim().replaceAll("'", "''")}%';

    List<Map<String, dynamic>> rows;

    if (uzToEn) {
      rows = await _db!.rawQuery('''
        SELECT MIN(w.id) as id, w.word, w.word_cyrillic,
               w.part_of_speech, w.pronunciation,
               MIN(CASE
                 WHEN d.target_language='en'
                   AND w.part_of_speech != ''
                   AND d.definition NOT LIKE 'Cyrillic%'
                   AND d.definition NOT LIKE 'Synonym%'
                   AND d.definition NOT LIKE 'Alternative%'
                   AND d.definition NOT LIKE 'plural%'
                 THEN d.definition END) as def_en,
               MIN(CASE WHEN d.target_language='ru'
                   THEN d.definition END) as def_ru
        FROM words w
        LEFT JOIN definitions d ON d.word_id = w.id AND d.definition != ''
        WHERE w.word LIKE ?
        GROUP BY w.word, w.part_of_speech
        ORDER BY
          CASE WHEN w.part_of_speech != '' THEN 0 ELSE 1 END,
          length(w.word), w.word
        LIMIT 30
      ''', [q]);
    } else {
      rows = await _db!.rawQuery('''
        SELECT MIN(w.id) as id, w.word, w.word_cyrillic,
               w.part_of_speech, w.pronunciation,
               MIN(CASE
                 WHEN d2.target_language='en'
                   AND d2.definition NOT LIKE 'Cyrillic%'
                   AND d2.definition NOT LIKE 'Synonym%'
                 THEN d2.definition END) as def_en,
               MIN(CASE WHEN d2.target_language='ru'
                   THEN d2.definition END) as def_ru
        FROM definitions d
        JOIN words w ON w.id = d.word_id
        LEFT JOIN definitions d2 ON d2.word_id = w.id AND d2.definition != ''
        WHERE d.target_language = 'en' AND d.definition LIKE ?
          AND d.definition NOT LIKE 'Cyrillic%'
          AND d.definition NOT LIKE 'Synonym%'
        GROUP BY w.word, w.part_of_speech
        ORDER BY length(w.word), w.word
        LIMIT 30
      ''', [q]);
    }

    // Dart da ham filterlash
    final entries = rows.map(_rowToEntry).toList();
    return entries.where((e) => _isGoodEntry(e)).toList();
  }

  bool _isGoodEntry(DictionaryEntry e) {
    if (e.word.isEmpty) return false;
    return true;
  }

  /// Tafsilot: so'zning barcha yaxshi ta'riflari
  Future<DictionaryEntry?> getById(int id) async {
    if (_db == null) return null;
    final wordRows = await _db!.rawQuery(
        'SELECT * FROM words WHERE id = ?', [id]);
    if (wordRows.isEmpty) return null;

    final word = (wordRows.first['word'] as String).trim();

    final defRows = await _db!.rawQuery('''
      SELECT DISTINCT d.definition, d.target_language,
             d.example_source, d.example_target
      FROM definitions d
      JOIN words w ON w.id = d.word_id
      WHERE w.word = ?
        AND d.definition != ''
        AND d.definition NOT LIKE 'Cyrillic%'
        AND d.definition NOT LIKE 'Synonym%'
        AND d.definition NOT LIKE 'Alternative%'
        AND d.definition NOT LIKE 'plural of%'
      ORDER BY
        CASE WHEN d.target_language='en' THEN 0 ELSE 1 END,
        length(d.definition)
    ''', [word]);

    final seenEn = <String>{};
    final seenRu = <String>{};
    final defList = <Definition>[];

    for (final d in defRows) {
      final text  = (d['definition'] as String).trim();
      final lang  = d['target_language'] as String;
      final exSrc = (d['example_source'] as String? ?? '').trim();
      final exTgt = (d['example_target'] as String? ?? '').trim();

      // Yomon ta'riflarni o'tkazib yuborish
      bool isBad = _badPrefixes.any(
          (p) => text.toLowerCase().startsWith(p.toLowerCase()));
      if (isBad) continue;

      if (lang == 'en' && seenEn.add(text)) {
        defList.add(Definition(text: text, language: 'en',
            exampleSource: exSrc, exampleTarget: exTgt));
      } else if (lang == 'ru' && seenRu.add(text)) {
        defList.add(Definition(text: text, language: 'ru',
            exampleSource: exSrc, exampleTarget: exTgt));
      }
    }

    final row = wordRows.first;
    return DictionaryEntry(
      id: id,
      word: word,
      wordCyrillic: (row['word_cyrillic'] as String? ?? '').trim(),
      partOfSpeech: (row['part_of_speech'] as String? ?? '').trim(),
      pronunciation: (row['pronunciation'] as String? ?? '').trim(),
      definitions: defList,
    );
  }

  DictionaryEntry _rowToEntry(Map<String, dynamic> row) {
    final defEn = (row['def_en'] as String? ?? '').trim();
    final defRu = (row['def_ru'] as String? ?? '').trim();

    return DictionaryEntry(
      id: row['id'] as int,
      word: (row['word'] as String).trim(),
      wordCyrillic: (row['word_cyrillic'] as String? ?? '').trim(),
      partOfSpeech: (row['part_of_speech'] as String? ?? '').trim(),
      pronunciation: (row['pronunciation'] as String? ?? '').trim(),
      definitions: [
        if (defEn.isNotEmpty)
          Definition(text: defEn, language: 'en'),
        if (defRu.isNotEmpty)
          Definition(text: defRu, language: 'ru'),
      ],
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
