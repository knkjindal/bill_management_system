import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';

class PasscodeLockScreen extends StatefulWidget {
  const PasscodeLockScreen({super.key});

  @override
  State<PasscodeLockScreen> createState() => _PasscodeLockScreenState();
}

class _PasscodeLockScreenState extends State<PasscodeLockScreen> {
  final _controller = TextEditingController();
  String? _error;
  String? _storedPasscode;

  @override
  void initState() {
    super.initState();
    _loadPasscode();
  }

  Future<void> _loadPasscode() async {
    final saved = await SecureStorageService.getPasscode();
    setState(() => _storedPasscode = saved);
  }

  void _unlock() {
    if (_controller.text == _storedPasscode) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() => _error = 'Incorrect passcode');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_storedPasscode == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Passcode')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔒 App Locked', style: TextStyle(fontSize: 22)),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Enter Passcode',
                errorText: _error,
              ),
              onSubmitted: (_) => _unlock(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _unlock, child: const Text('Unlock')),
          ],
        ),
      ),
    );
  }
}
