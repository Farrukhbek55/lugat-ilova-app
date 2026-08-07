import 'package:flutter/material.dart';
import '../l10n/translations.dart';
import '../models/dictionary_entry.dart';
import '../services/dictionary_service.dart';
import '../services/favorites_service.dart';
import '../widgets/word_tile.dart';
import 'word_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final String lang;
  const FavoritesScreen({super.key, required this.lang});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _dictionary = DictionaryService();
  final _favorites  = FavoritesService();
  List<DictionaryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    await _dictionary.load();
    final ids = await _favorites.getFavoriteIds();
    final entries = <DictionaryEntry>[];
    for (final id in ids) {
      final entry = await _dictionary.getById(id);
      if (entry != null) entries.add(entry);
    }
    if (!mounted) return;
    setState(() { _entries = entries; _loading = false; });
  }

  Future<void> _toggleFavorite(int id) async {
    await _favorites.toggleFavorite(id);
    await _load();
  }

  void _openDetail(DictionaryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WordDetailScreen(entry: entry)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Scaffold(
      appBar: AppBar(
        title: Text(t(lang, 'tab_favorites')),
        centerTitle: true,
        actions: [
          if (_entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(label: Text('${_entries.length}')),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(t(lang, 'no_favorites'),
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return WordTile(
                      entry: entry,
                      isFavorite: true,
                      onFavoriteToggle: () => _toggleFavorite(entry.id),
                      onTap: () => _openDetail(entry),
                    );
                  },
                ),
    );
  }
}
