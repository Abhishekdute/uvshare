import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _autoAccept = false;
  bool _highSpeedMode = true;
  String _discoveryMode = 'While App Open';

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Preferences', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader('APPEARANCE', isDark),
          _buildSettingsTile(
            isDark: isDark,
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Reduce eye strain in low light',
            trailing: Switch.adaptive(
              value: themeService.isDarkMode,
              activeColor: primaryColor,
              onChanged: (val) => themeService.toggleTheme(),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('TRANSFER ENGINE', isDark),
          _buildSettingsTile(
            isDark: isDark,
            icon: Icons.speed_rounded,
            title: 'High-Speed Mode',
            subtitle: 'Uses 5GHz band if available',
            trailing: Switch.adaptive(
              value: _highSpeedMode,
              activeColor: primaryColor,
              onChanged: (val) => setState(() => _highSpeedMode = val),
            ),
          ),
          _buildSettingsTile(
            isDark: isDark,
            icon: Icons.verified_user_rounded,
            title: 'Auto-Accept',
            subtitle: 'Accept files from trusted devices',
            trailing: Switch.adaptive(
              value: _autoAccept,
              activeColor: primaryColor,
              onChanged: (val) => setState(() => _autoAccept = val),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('DISCOVERY', isDark),
          _buildSettingsTile(
            isDark: isDark,
            icon: Icons.visibility_rounded,
            title: 'Visibility',
            subtitle: _discoveryMode,
            onTap: _showDiscoveryDialog,
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('STORAGE', isDark),
          _buildSettingsTile(
            isDark: isDark,
            icon: Icons.folder_open_rounded,
            title: 'Download Path',
            subtitle: '/Download/UVShare',
            onTap: () {},
          ),
          const SizedBox(height: 40),
          _buildAboutCard(primaryColor),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.05), 
            borderRadius: BorderRadius.circular(12)
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 22),
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black
          )
        ),
        subtitle: Text(
          subtitle, 
          style: TextStyle(
            fontSize: 12, 
            color: isDark ? Colors.grey[400] : Colors.grey.shade500
          )
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  Widget _buildAboutCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, Colors.purple.shade400]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text('UVShare Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          const Text('Version 2.0.4-stable', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 20),
          Text(
            'Made with ❤️ for high-performance sharing.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showDiscoveryDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Discovery Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            _buildModeOption('Always Visible'),
            _buildModeOption('While App Open'),
            _buildModeOption('Hidden'),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(String mode) {
    return ListTile(
      title: Text(mode, style: const TextStyle(fontWeight: FontWeight.bold)),
      leading: Radio<String>(
        value: mode,
        groupValue: _discoveryMode,
        activeColor: const Color(0xFF6366F1),
        onChanged: (val) {
          setState(() => _discoveryMode = val!);
          Navigator.pop(context);
        },
      ),
    );
  }
}
