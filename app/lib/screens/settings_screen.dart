import 'package:flutter/material.dart';
import '../services/history_service.dart';

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
            icon: Icons.delete_forever,
            title: 'Clear History',
            subtitle: 'Permanently remove all past analyses',
            onTap: () => _confirmClearHistory(context),
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'About Palmistry AI',
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Clear History?', style: TextStyle(color: Colors.white)),
        content: const Text('This will delete all saved palm analyses.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              final db = await HistoryService().database;
              await db.delete('history');
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
            child: const Text('CLEAR ALL', style: TextStyle(color: Colors.redAccent)),
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
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white54)) : null,
      trailing: trailing,
      onTap: onTap ?? () {},
    );
  }
}
