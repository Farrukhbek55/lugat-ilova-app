import 'package:flutter/material.dart';
import '../models/dictionary_entry.dart';

class WordTile extends StatelessWidget {
  final DictionaryEntry entry;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final bool showUzFirst;
  final VoidCallback? onTap;

  const WordTile({
    super.key,
    required this.entry,
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.showUzFirst = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enDef = entry.mainDefinition;
    final ruDef = entry.ruDefinitions.isNotEmpty
        ? entry.ruDefinitions.first.text : '';

    // showUzFirst=true  → so'z o'zbekcha, tarjima inglizcha
    // showUzFirst=false → so'z inglizcha, tarjima o'zbekcha
    final mainWord   = entry.word;
    final mainDef    = showUzFirst ? enDef : entry.word;
    final secondDef  = showUzFirst ? ruDef : enDef;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // So'z + transkriptsiya + so'z turi
                    Row(
                      children: [
                        Text(
                          mainWord,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (entry.pronunciation.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            entry.pronunciation,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (entry.partOfSpeech.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.partOfSpeech,
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Inglizcha tarjima
                    if (enDef.isNotEmpty)
                      Text(
                        enDef,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Ruscha tarjima
                    if (ruDef.isNotEmpty)
                      Text(
                        ruDef,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Yulduzcha + o'q
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.amber : cs.outline,
                      size: 22,
                    ),
                    onPressed: onFavoriteToggle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: cs.outline, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
