import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Feedback'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Documentation'),
            leading: const Icon(Icons.book),
            onTap: () =>
                launchUrl(Uri.parse('https://github.com/Felamande/aichat')),
          ),
          ListTile(
            title: const Text('Report an Issue'),
            leading: const Icon(Icons.bug_report),
            onTap: () => launchUrl(
                Uri.parse('https://github.com/Felamande/aichat/issues')),
          ),
          ListTile(
            title: const Text('Send Feedback'),
            leading: const Icon(Icons.feedback),
            onTap: () => launchUrl(
                Uri.parse('https://github.com/Felamande/aichat/discussions')),
          ),
        ],
      ),
    );
  }
}
