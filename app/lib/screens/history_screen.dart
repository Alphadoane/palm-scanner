import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Analysis History'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // Mock data
        itemBuilder: (context, index) {
          return Card(
            color: Colors.white.withOpacity(0.05),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Colors.white10),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.history, color: Colors.white),
              ),
              title: Text(
                'Palm Reading ${5 - index}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'May ${1 + index}, 2026 • 94% Confidence',
                style: const TextStyle(color: Colors.white54),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () {
                // Future: show detailed result
              },
            ),
          );
        },
      ),
    );
  }
}
