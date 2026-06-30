import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/localization/app_strings.dart';
import 'package:aqar/features/about/presentation/pages/about_page.dart';
import 'package:aqar/features/help/presentation/pages/help_page.dart';
import 'package:aqar/features/auth/presentation/pages/change_password_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _darkMode = false;
  String _currentLocale = AppStrings.locale;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _smsNotifications = prefs.getBool('sms_notifications') ?? false;
    });
  }

  void _toggleLocale() {
    final newLocale = _currentLocale == 'en' ? 'ar' : 'en';
    setState(() => _currentLocale = newLocale);
    AppStrings.locale = newLocale;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('locale', newLocale));
    setState(() {});
  }

  void _toggleDarkMode(bool v) {
    setState(() => _darkMode = v);
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('dark_mode', v));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Appearance'),
          _buildTile(
            Icons.dark_mode_outlined,
            'Dark Mode',
            'Switch to a darker color scheme',
            TrailingSwitch(
              value: _darkMode,
              onChanged: _toggleDarkMode,
            ),
          ),
          _buildTile(
            Icons.language_rounded,
            'Language',
            _currentLocale == 'en' ? 'English' : 'العربية',
            TrailingSwitch(
              value: _currentLocale == 'ar',
              onChanged: (_) => _toggleLocale(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('Notifications'),
          _buildTile(
            Icons.notifications_outlined,
            'Push Notifications',
            'Property updates, messages & alerts',
            TrailingSwitch(
              value: _notificationsEnabled,
              onChanged: (v) {
                setState(() => _notificationsEnabled = v);
                SharedPreferences.getInstance().then((prefs) => prefs.setBool('notifications_enabled', v));
              },
            ),
          ),
          _buildTile(
            Icons.email_outlined,
            'Email Notifications',
            'Invoices, confirmations & receipts',
            TrailingSwitch(
              value: _emailNotifications,
              onChanged: (v) {
                setState(() => _emailNotifications = v);
                SharedPreferences.getInstance().then((prefs) => prefs.setBool('email_notifications', v));
              },
            ),
          ),
          _buildTile(
            Icons.sms_outlined,
            'SMS Notifications',
            'OTP, alerts & important updates',
            TrailingSwitch(
              value: _smsNotifications,
              onChanged: (v) {
                setState(() => _smsNotifications = v);
                SharedPreferences.getInstance().then((prefs) => prefs.setBool('sms_notifications', v));
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('Account'),
          _buildTile(
            Icons.lock_outline_rounded,
            'Change Password',
            'Update your account password',
            const TrailingChevron(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('Support'),
          _buildTile(
            Icons.help_outline_rounded,
            'Help & FAQ',
            'Frequently asked questions',
            const TrailingChevron(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpPage()),
            ),
          ),
          _buildTile(
            Icons.info_outline_rounded,
            'About AQAR',
            'Version, terms & privacy',
            const TrailingChevron(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTile(
    IconData icon,
    String title,
    String subtitle,
    Widget trailing, {
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

}

class TrailingSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const TrailingSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
      activeThumbColor: AppColors.primary,
    );
  }
}

class TrailingChevron extends StatelessWidget {
  const TrailingChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.chevron_right, size: 20, color: AppColors.textHint);
  }
}
