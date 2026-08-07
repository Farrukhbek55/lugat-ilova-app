import 'package:flutter/material.dart';
import 'l10n/translations.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const LugHatApp());
}

class LugHatApp extends StatefulWidget {
  const LugHatApp({super.key});
  @override
  State<LugHatApp> createState() => _LugHatAppState();
}

class _LugHatAppState extends State<LugHatApp> {
  final _settings = SettingsService();
  String _lang = 'uz';
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lang = await _settings.getLanguage();
    final dark = await _settings.getDarkMode();
    setState(() { _lang = lang; _isDark = dark; });
  }

  Future<void> _setLanguage(String lang) async {
    await _settings.setLanguage(lang);
    setState(() => _lang = lang);
  }

  Future<void> _setDarkMode(bool value) async {
    await _settings.setDarkMode(value);
    setState(() => _isDark = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LugHat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: MainNav(
        lang: _lang,
        isDark: _isDark,
        onLanguageChanged: _setLanguage,
        onDarkModeChanged: _setDarkMode,
      ),
    );
  }
}

class MainNav extends StatefulWidget {
  final String lang;
  final bool isDark;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<bool> onDarkModeChanged;

  const MainNav({
    super.key,
    required this.lang,
    required this.isDark,
    required this.onLanguageChanged,
    required this.onDarkModeChanged,
  });

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _selectedIndex = 0;
  bool _permissionAsked = false;

  @override
  void initState() {
    super.initState();
    // Birinchi ochilganda ruxsat so'rash — kichik kechikish bilan
    // (UI to'liq yuklangandan keyin chiqsin)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askPermissionOnFirstLaunch();
    });
  }

  Future<void> _askPermissionOnFirstLaunch() async {
    // Faqat birinchi marta so'rash
    final alreadyAsked = await SettingsService().getPermissionAsked();
    if (alreadyAsked || _permissionAsked) return;
    _permissionAsked = true;
    await SettingsService().setPermissionAsked(true);

    if (!mounted) return;

    // Dialog ko'rsatish — tushuntirish bilan
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_active, size: 48, color: Colors.amber),
        title: const Text('Kunlik so\'z eslatmasi', textAlign: TextAlign.center),
        content: const Text(
          'Har kuni soat 9:00 da yangi inglizcha so\'z yuboriladi.\n\n'
          'Bu sizga har kuni yangi so\'z o\'rganishga yordam beradi! 📖',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kerak emas'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yoqish ✓'),
          ),
        ],
      ),
    );

    if (agreed == true) {
      await NotificationService().requestPermission();
      await NotificationService().scheduleDailyWordNotification();
      await SettingsService().setNotifications(true);

      // Foydalanuvchiga tasdiqlash
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Har kuni soat 9:00 da eslatma yuboriladi!'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    final screens = [
      HomeScreen(lang: lang),
      FavoritesScreen(lang: lang),
      SettingsScreen(
        lang: lang,
        isDark: widget.isDark,
        onLanguageChanged: widget.onLanguageChanged,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: t(lang, 'tab_dictionary'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_outline),
            selectedIcon: const Icon(Icons.star),
            label: t(lang, 'tab_favorites'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: t(lang, 'tab_settings'),
          ),
        ],
      ),
    );
  }
}
