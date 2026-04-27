import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/theme_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _profileImagePath;
  String _userName = 'Abhishek';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profile_image');
      _userName = prefs.getString('user_name') ?? 'Abhishek';
    });
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.pushNamed(context, '/profile_edit');
    if (result == true) {
      _loadProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final primaryColor = const Color(0xFF6366F1);
    final accentColor = const Color(0xFFA855F7);

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildProfileHeader(primaryColor, accentColor),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  title: 'Home Interface',
                  color: primaryColor,
                  isDark: isDark,
                  onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                ),
                _buildDrawerItem(
                  icon: Icons.shield_rounded,
                  title: 'Secure Vault',
                  color: Colors.amber.shade700,
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/vault'),
                ),
                _buildDrawerItem(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'Activity Log',
                  color: Colors.green.shade600,
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/history'),
                ),
                _buildDrawerItem(
                  icon: Icons.language_rounded,
                  title: 'Web Share',
                  color: Colors.deepPurple,
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/web_share'),
                ),
                const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),
                _buildDrawerItem(
                  icon: Icons.settings_suggest_rounded,
                  title: 'Preferences',
                  color: Colors.blueGrey,
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                _buildDrawerItem(
                  icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  title: isDark ? 'Light Mode' : 'Dark Mode',
                  color: isDark ? Colors.orange : Colors.indigo,
                  isDark: isDark,
                  onTap: () => themeService.toggleTheme(),
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About UVShare',
                  color: Colors.blue,
                  isDark: isDark,
                  onTap: () {},
                ),
              ],
            ),
          ),
          _buildFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Color primary, Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, accent],
        ),
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(40)),
      ),
      child: InkWell(
        onTap: _navigateToEditProfile,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: _profileImagePath != null && File(_profileImagePath!).existsSync()
                    ? FileImage(File(_profileImagePath!))
                    : const NetworkImage('https://ui-avatars.com/api/?name=User&background=fff&color=6366F1') as ImageProvider,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Edit Identity',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.5), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.w800, 
          fontSize: 14, 
          color: isDark ? Colors.white : const Color(0xFF1F2937)
        )
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'UVShare Pro', 
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black, 
              fontWeight: FontWeight.w900, 
              fontSize: 14
            )
          ),
          Text('v2.0.4 - Premium', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
