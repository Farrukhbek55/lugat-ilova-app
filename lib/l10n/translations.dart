// Uch tilli interfeys uchun tarjimalar (uz / ru / en)
// DoIt ilovasidagi TR + t(lang, key) andozasiga mos qilib yozilgan.

const Map<String, Map<String, String>> TR = {
  'app_name': {'uz': 'LugHat', 'ru': 'LugHat', 'en': 'LugHat'},
  'search_hint': {
    'uz': "So'z kiriting...",
    'ru': 'Введите слово...',
    'en': 'Type a word...'
  },
  'tab_dictionary': {'uz': "Lug'at", 'ru': 'Словарь', 'en': 'Dictionary'},
  'tab_favorites': {'uz': 'Sevimlilar', 'ru': 'Избранное', 'en': 'Favorites'},
  'tab_settings': {'uz': 'Sozlamalar', 'ru': 'Настройки', 'en': 'Settings'},
  'no_results': {
    'uz': "So'z topilmadi",
    'ru': 'Слово не найдено',
    'en': 'No word found'
  },
  'start_typing': {
    'uz': 'Qidirish uchun so\'z yozing',
    'ru': 'Введите слово для поиска',
    'en': 'Type a word to search'
  },
  'no_favorites': {
    'uz': "Hali sevimli so'zlar yo'q",
    'ru': 'Пока нет избранных слов',
    'en': 'No favorite words yet'
  },
  'category': {'uz': 'Toifa', 'ru': 'Категория', 'en': 'Category'},
  'total_words': {'uz': "so'z", 'ru': 'слов', 'en': 'words'},
  'theme': {'uz': 'Mavzu', 'ru': 'Тема', 'en': 'Theme'},
  'language': {'uz': 'Til', 'ru': 'Язык', 'en': 'Language'},
  'dark_mode': {'uz': 'Tungi rejim', 'ru': 'Тёмная тема', 'en': 'Dark mode'},
  'about': {'uz': "Ilova haqida", 'ru': 'О приложении', 'en': 'About'},
  'offline_note': {
    'uz': "100% oflayn ishlaydi, hech qanday limit yo'q",
    'ru': 'Работает на 100% офлайн, без ограничений',
    'en': 'Works 100% offline, no limits'
  },
  'clear': {'uz': 'Tozalash', 'ru': 'Очистить', 'en': 'Clear'},
};

String t(String lang, String key, {Map<String, String>? args}) {
  String value = TR[key]?[lang] ?? TR[key]?['uz'] ?? key;
  if (args != null) {
    args.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
  }
  return value;
}
