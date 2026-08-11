import 'dart:async';
import 'dart:io';
import 'dart:isolate';
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

  Future<void> load() async {
    if (_db != null) return;
    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docDir.path, 'topsoz.db');
    final dbFile = File(dbPath);

    if (!dbFile.existsSync()) {
      // Birinchi marta: chunk-by-chunk yozish (tezroq va xotira tejamkor)
      _progressController.add(0.05);
      final data = await rootBundle.load('assets/topsoz.db');
      _progressController.add(0.2);

      final bytes = data.buffer.asUint8List();
      final file = dbFile.openSync(mode: FileMode.write);
      const chunkSize = 256 * 1024; // 256KB bo'laklar
      final total = bytes.length;

      for (int i = 0; i < total; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, total);
        file.writeFromSync(bytes, i, end);
        // Progress: 0.2 dan 0.95 gacha
        _progressController.add(0.2 + (end / total) * 0.75);
      }
      file.flushSync();
      file.closeSync();
      _progressController.add(1.0);
    }

    _db = await openDatabase(dbPath, readOnly: true);
    try {
      await _db!.execute('PRAGMA cache_size = 8000');
      await _db!.execute('PRAGMA temp_store = MEMORY');
      await _db!.execute('PRAGMA mmap_size = 134217728');
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
      // EN->UZ: so'z bo'yicha qidiruv (word ustunida indeks bor)
      rows = await _db!.rawQuery('''
        SELECT w.id, w.word, w.word_cyrillic,
               w.part_of_speech, w.pronunciation,
               d.definition as def_en
        FROM words w
        LEFT JOIN definitions d ON d.word_id = w.id
        WHERE w.word LIKE ?
        ORDER BY length(w.word), w.word
        LIMIT 30
      ''', [q]);
    } else {
      // UZ->EN: tarjima ichidan qidiruv
      rows = await _db!.rawQuery('''
        SELECT w.id, w.word, w.word_cyrillic,
               w.part_of_speech, w.pronunciation,
               d.definition as def_en
        FROM definitions d
        JOIN words w ON w.id = d.word_id
        WHERE d.definition LIKE ?
        ORDER BY length(w.word), w.word
        LIMIT 30
      ''', [q]);
    }

    return rows.map(_rowToEntry).where((e) => e.word.isNotEmpty).toList();
  }

  Future<DictionaryEntry?> getById(int id) async {
    if (_db == null) return null;
    final wordRows = await _db!.rawQuery(
        'SELECT * FROM words WHERE id = ?', [id]);
    if (wordRows.isEmpty) return null;

    final defRows = await _db!.rawQuery('''
      SELECT definition, target_language, example_source, example_target
      FROM definitions
      WHERE word_id = ? AND definition != ''
    ''', [id]);

    final defList = <Definition>[];
    for (final d in defRows) {
      final text = (d['definition'] as String).trim();
      if (text.isEmpty) continue;
      defList.add(Definition(
        text: text,
        language: 'uz',
        exampleSource: (d['example_source'] as String? ?? '').trim(),
        exampleTarget: (d['example_target'] as String? ?? '').trim(),
      ));
    }

    final row = wordRows.first;
    return DictionaryEntry(
      id: id,
      word: (row['word'] as String).trim(),
      wordCyrillic: (row['word_cyrillic'] as String? ?? '').trim(),
      partOfSpeech: (row['part_of_speech'] as String? ?? '').trim(),
      pronunciation: (row['pronunciation'] as String? ?? '').trim(),
      definitions: defList,
    );
  }

  DictionaryEntry _rowToEntry(Map<String, dynamic> row) {
    final defText = (row['def_en'] as String? ?? '').trim();
    return DictionaryEntry(
      id: row['id'] as int,
      word: (row['word'] as String).trim(),
      wordCyrillic: (row['word_cyrillic'] as String? ?? '').trim(),
      partOfSpeech: (row['part_of_speech'] as String? ?? '').trim(),
      pronunciation: (row['pronunciation'] as String? ?? '').trim(),
      definitions: [
        if (defText.isNotEmpty)
          Definition(text: defText, language: 'uz'),
      ],
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
