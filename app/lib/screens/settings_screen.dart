import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Notifications',
            trailing: Switch(value: true, onChanged: (_) {}, activeColor: Colors.blueAccent),
          ),
          _buildSettingItem(
            icon: Icons.psychology,
            title: 'AI Sensitivity',
            subtitle: 'Balance speed vs accuracy',
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
          ),
          _buildSettingItem(
            icon: Icons.palette,
            title: 'Theme',
            subtitle: 'Dark Mystique (Default)',
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
          ),
          const Divider(color: Colors.white10, height: 40),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'About Palmistry AI',
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
          ),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white54)) : null,
      trailing: trailing,
      onTap: () {},
    );
  }
}
