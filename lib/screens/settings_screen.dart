import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onLanguageChanged;

  const SettingsScreen({super.key, this.onLanguageChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAppLocked = false;
  final TextEditingController _passcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLockState();
  }

  Future<void> _loadLockState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAppLocked = prefs.getString('passcode')?.isNotEmpty ?? false;
    });
  }

  Future<void> _toggleLock() async {
    final prefs = await SharedPreferences.getInstance();

    if (_isAppLocked) {
      // Confirm before removing
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove App Lock?'),
          content: const Text('Are you sure you want to remove the passcode lock?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
          ],
        ),
      );

      if (confirm == true) {
        await prefs.remove('passcode');
        setState(() {
          _isAppLocked = false;
        });
      }
    } else {
      // Set passcode
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set App Passcode'),
          content: TextField(
            controller: _passcodeController,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Enter passcode'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final code = _passcodeController.text.trim();
                if (code.length >= 4) {
                  await prefs.setString('passcode', code);
                  setState(() => _isAppLocked = true);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            value: _isAppLocked,
            onChanged: (_) => _toggleLock(),
            title: const Text('App Lock'),
            subtitle: Text(_isAppLocked ? 'Enabled' : 'Disabled'),
          ),
          // You can add a language toggle here in the future.
        ],
      ),
    );
  }
}
