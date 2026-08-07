import 'package:flutter/material.dart';
import '../l10n/translations.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final String lang;
  final bool isDark;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<bool> onDarkModeChanged;

  const SettingsScreen({
    super.key,
    required this.lang,
    required this.isDark,
    required this.onLanguageChanged,
    required this.onDarkModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _notif    = NotificationService();
  final _settings = SettingsService();
  bool _notifEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotifSetting();
  }

  Future<void> _loadNotifSetting() async {
    final val = await _settings.getNotifications();
    if (mounted) setState(() => _notifEnabled = val);
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      // Ruxsat so'rash (toggle bosganda ham)
      final granted = await _notif.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Ruxsat berilmadi. Telefon sozlamalaridan yoqing.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return; // Ruxsat yo'q — toggle yoqilmaydi
      }
      await _notif.scheduleDailyWordNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Har kuni soat 9:00 da eslatma yuboriladi!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await _notif.cancelAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔕 Eslatmalar o\'chirildi'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() => _notifEnabled = value);
    await _settings.setNotifications(value);
  }

  Future<void> _sendTestNotification() async {
    // Random so'z emas, aniq namuna yuboramiz
    await _notif.showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📳 Test xabari yuborildi! Bildirishnomalar panelingizni oching.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang  = widget.lang;
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t(lang, 'tab_settings')), centerTitle: true),
      body: ListView(
        children: [

          // === TIL ===
          _SectionHeader(title: '🌐 ${t(lang, 'language')}', color: cs.primary),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(t(lang, 'language')),
            trailing: DropdownButton<String>(
              value: widget.lang,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'uz', child: Text("O'zbekcha")),
                DropdownMenuItem(value: 'ru', child: Text('Русский')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) { if (v != null) widget.onLanguageChanged(v); },
            ),
          ),

          const Divider(height: 1),

          // === MAVZU ===
          _SectionHeader(title: '🎨 ${t(lang, 'theme')}', color: cs.primary),
          SwitchListTile(
            title: Text(t(lang, 'dark_mode')),
            secondary: Icon(
              widget.isDark ? Icons.dark_mode : Icons.light_mode,
              color: cs.primary,
            ),
            value: widget.isDark,
            onChanged: widget.onDarkModeChanged,
          ),

          const Divider(height: 1),

          // === NOTIFICATION ===
          _SectionHeader(title: '🔔 Eslatmalar', color: cs.primary),

          // Tushuntirish kartasi
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Card(
              color: cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: cs.onPrimaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Har kuni soat 9:00 da yangi inglizcha so\'z '
                        'notification sifatida yuboriladi.',
                        style: TextStyle(color: cs.onPrimaryContainer, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SwitchListTile(
            title: const Text('Kunlik so\'z eslatmasi'),
            subtitle: Text(
              _notifEnabled ? '✅ Faol — har kuni 9:00' : '⏸ O\'chirilgan',
              style: TextStyle(
                color: _notifEnabled ? Colors.green : cs.outline,
                fontSize: 12,
              ),
            ),
            secondary: Icon(
              _notifEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: _notifEnabled ? Colors.amber : null,
            ),
            value: _notifEnabled,
            onChanged: _toggleNotifications,
          ),

          // Test tugmasi faqat yoqilganda ko'rinadi
          if (_notifEnabled)
            ListTile(
              leading: const Icon(Icons.send_outlined),
              title: const Text('Test xabari yuborish'),
              subtitle: const Text('Xabar qanday ko\'rinishini tekshirish'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _sendTestNotification,
            ),

          const Divider(height: 1),

          // === ILOVA HAQIDA ===
          _SectionHeader(title: 'ℹ️ ${t(lang, "about")}', color: cs.primary),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Jami so\'zlar'),
            trailing: Text(
              '16 387',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wifi_off),
            title: Text(t(lang, 'offline_note')),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versiya'),
            trailing: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
