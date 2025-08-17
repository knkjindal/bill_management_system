import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _storedPin = '';
  bool _isSettingUp = false;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storedPin = prefs.getString('app_pin') ?? '';
      _isSettingUp = _storedPin.isEmpty;
    });
  }

  Future<void> _savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin', pin);
  }

  void _verifyOrSetPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) return;

    if (_isSettingUp) {
      await _savePin(pin); if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      if (pin == _storedPin) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect PIN')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _isSettingUp ? 'Set 4-digit PIN' : 'Enter PIN';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 60, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text(prompt, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              TextField(
                controller: _pinController,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'PIN',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyOrSetPin,
                child: Text(_isSettingUp ? 'Set PIN' : 'Unlock'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
