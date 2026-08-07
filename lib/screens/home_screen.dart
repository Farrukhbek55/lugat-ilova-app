import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/translations.dart';
import '../models/dictionary_entry.dart';
import '../services/dictionary_service.dart';
import '../services/favorites_service.dart';
import '../widgets/word_tile.dart';
import 'word_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String lang;
  const HomeScreen({super.key, required this.lang});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dictionary = DictionaryService();
  final _favorites  = FavoritesService();
  final _controller = TextEditingController();

  List<DictionaryEntry> _results = [];
  Set<int> _favoriteIds = {};
  bool _isUzToEn = true;
  bool _loading   = false;
  bool _dbReady   = false;
  double _copyProgress = 0.0; // 0.0 - 1.0
  bool _isCopying = false;

  Timer? _debounce;
  StreamSubscription<double>? _progressSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _progressSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Progress stream ni tinglash
    _progressSub = _dictionary.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _copyProgress = progress;
          _isCopying = progress < 1.0;
        });
      }
    });

    setState(() => _isCopying = true);
    await _dictionary.load();
    _favoriteIds = await _favorites.getFavoriteIds();

    if (mounted) {
      setState(() {
        _dbReady  = true;
        _isCopying = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() { _results = []; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final res = await _dictionary.search(query, uzToEn: _isUzToEn);
      if (mounted) setState(() { _results = res; _loading = false; });
    });
  }

  void _swapDirection() {
    setState(() {
      _isUzToEn = !_isUzToEn;
      _controller.clear();
      _results = [];
    });
  }

  Future<void> _toggleFavorite(int id) async {
    await _favorites.toggleFavorite(id);
    _favoriteIds = await _favorites.getFavoriteIds();
    if (mounted) setState(() {});
  }

  void _openDetail(DictionaryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WordDetailScreen(entry: entry)),
    );
  }

  // ─── Loading ekrani ───────────────────────────────────────────
  Widget _buildLoading(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikonka
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.menu_book,
                  size: 44, color: cs.primary),
            ),
            const SizedBox(height: 24),

            Text(
              'LugHat',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              _isCopying
                  ? "Lug'at birinchi marta tayyorlanmoqda..."
                  : "Lug'at yuklanmoqda...",
              style: TextStyle(fontSize: 14, color: cs.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _isCopying && _copyProgress > 0
                    ? _copyProgress
                    : null, // indeterminate
                minHeight: 8,
                backgroundColor: cs.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
            const SizedBox(height: 12),

            // Foiz
            if (_isCopying && _copyProgress > 0)
              Text(
                '${(_copyProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 8),
            Text(
              'Bu faqat bir marta bo\'ladi',
              style: TextStyle(fontSize: 12, color: cs.outline),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Asosiy kontent ───────────────────────────────────────────
  Widget _buildContent(ColorScheme cs) {
    return Column(
      children: [
        // EN ↔ UZ yo'nalish
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Container(
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isUzToEn ? "O'ZBEKCHA" : 'ENGLISH',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _swapDirection,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: cs.primary, shape: BoxShape.circle),
                    child: Icon(Icons.swap_horiz,
                        color: cs.onPrimary, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isUzToEn ? 'ENGLISH' : "O'ZBEKCHA",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),

        // Qidiruv
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _controller,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: _isUzToEn
                  ? "O'zbekcha so'z yozing..."
                  : 'Type English word...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '${_dictionary.totalWords} ${t(widget.lang, 'total_words')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _controller.text.isEmpty
                  ? Center(child: Text(t(widget.lang, 'start_typing')))
                  : _results.isEmpty
                      ? Center(child: Text(t(widget.lang, 'no_results')))
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final entry = _results[i];
                            return WordTile(
                              entry: entry,
                              isFavorite: _favoriteIds.contains(entry.id),
                              onFavoriteToggle: () =>
                                  _toggleFavorite(entry.id),
                              onTap: () => _openDetail(entry),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(t(widget.lang, 'app_name')), centerTitle: true),
      body: !_dbReady ? _buildLoading(cs) : _buildContent(cs),
    );
  }
}
