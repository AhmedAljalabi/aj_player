// screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../bootstrap.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool get _isDark => AppBootstrap.prefs.getBool('isDark') ?? true;
  bool get _shuffle => AppBootstrap.prefs.getBool('shuffle') ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark mode'),
            value: _isDark,
            onChanged: (v) {
              AppBootstrap.prefs.setBool('isDark', v);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('Shuffle by default'),
            value: _shuffle,
            onChanged: (v) {
              AppBootstrap.prefs.setBool('shuffle', v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
