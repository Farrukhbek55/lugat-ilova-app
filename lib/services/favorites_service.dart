import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'lughat_favorites';

  Future<Set<int>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => int.parse(e)).toSet();
  }

  Future<void> toggleFavorite(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final set = list.map((e) => int.parse(e)).toSet();
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    await prefs.setStringList(_key, set.map((e) => e.toString()).toList());
  }

  Future<bool> isFavorite(int id) async {
    final ids = await getFavoriteIds();
    return ids.contains(id);
  }
}
