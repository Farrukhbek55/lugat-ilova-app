import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dictionary_entry.dart';
import '../services/favorites_service.dart';

class WordDetailScreen extends StatefulWidget {
  final DictionaryEntry entry;
  const WordDetailScreen({super.key, required this.entry});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final _favorites = FavoritesService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final f = await _favorites.isFavorite(widget.entry.id);
    if (mounted) setState(() => _isFavorite = f);
  }

  Future<void> _toggle() async {
    await _favorites.toggleFavorite(widget.entry.id);
    await _check();
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$text" nusxa olindi'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e  = widget.entry;
    final cs = Theme.of(context).colorScheme;
    final enDefs = e.enDefinitions;
    final ruDefs = e.ruDefinitions;
    final exDef  = e.definitions.firstWhere(
      (d) => d.exampleSource.isNotEmpty,
      orElse: () => const Definition(text: '', language: 'en'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("So'z tafsiloti"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.amber : null,
            ),
            onPressed: _toggle,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── 1. BOSH KARTA ─────────────────────────
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.word,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy,
                            color: cs.onPrimaryContainer, size: 20),
                        onPressed: () => _copy(e.word),
                      ),
                    ],
                  ),
                  if (e.wordCyrillic.isNotEmpty)
                    Text(
                      e.wordCyrillic,
                      style: TextStyle(
                        fontSize: 18,
                        color: cs.onPrimaryContainer.withOpacity(0.6),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (e.pronunciation.isNotEmpty)
                        _Badge(e.pronunciation, cs.primary, cs.onPrimary,
                            italic: true),
                      if (e.partOfSpeech.isNotEmpty)
                        _Badge(e.partOfSpeech, cs.secondary, cs.onSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── 2. INGLIZCHA ──────────────────────────
          if (enDefs.isNotEmpty) ...[
            _Header(
              icon: '🇬🇧',
              label: 'Inglizcha',
              color: cs.primary,
            ),
            const SizedBox(height: 6),
            ...enDefs.asMap().entries.map((e) => _DefCard(
              number: enDefs.length > 1 ? e.key + 1 : null,
              text: e.value.text,
              color: cs.primaryContainer,
              textColor: cs.onPrimaryContainer,
            )),
            const SizedBox(height: 12),
          ],

          // ── 3. RUSCHA ─────────────────────────────
          if (ruDefs.isNotEmpty) ...[
            _Header(
              icon: '🇷🇺',
              label: 'Ruscha',
              color: Colors.teal,
            ),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: ruDefs.map((d) => Chip(
                    label: Text(d.text),
                    backgroundColor: Colors.teal.withOpacity(0.1),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── 4. MISOL GAP ──────────────────────────
          if (exDef.exampleSource.isNotEmpty) ...[
            _Header(
              icon: '💬',
              label: 'Misol gap',
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🇺🇿 ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            exDef.exampleSource,
                            style: const TextStyle(
                                fontSize: 15, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                    if (exDef.exampleTarget.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🇬🇧 ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              exDef.exampleTarget,
                              style: TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── 5. SEVIMLILAR TUGMASI ─────────────────
          const SizedBox(height: 4),
          FilledButton.tonal(
            onPressed: _toggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isFavorite ? Icons.star : Icons.star_border,
                    color: _isFavorite ? Colors.amber : null),
                const SizedBox(width: 8),
                Text(_isFavorite
                    ? 'Sevimlilardan chiqarish'
                    : 'Sevimlilarga qo\'shish'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String icon, label;
  final Color color;
  const _Header({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(icon, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 14, color: color)),
    ],
  );
}

class _DefCard extends StatelessWidget {
  final int? number;
  final String text;
  final Color color, textColor;
  const _DefCard({this.number, required this.text,
      required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (number != null) ...[
          Text('$number. ',
              style: TextStyle(fontWeight: FontWeight.bold,
                  color: textColor, fontSize: 14)),
        ],
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 15, color: textColor)),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg, fg;
  final bool italic;
  const _Badge(this.text, this.bg, this.fg, {this.italic = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: TextStyle(
      fontSize: 13, color: bg,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      fontWeight: FontWeight.w600,
    )),
  );
}
