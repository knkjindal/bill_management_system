import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _savedPasscode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPasscode();
  }

  Future<void> _loadPasscode() async {
    final saved = await SecureStorageService.getPasscode();
    setState(() {
      _savedPasscode = saved;
    });
  }

  void _verifyPasscode() async {
    if (_controller.text == _savedPasscode) {
      widget.onUnlocked();
    } else {
      setState(() => _error = 'Incorrect passcode');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_savedPasscode == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Set Passcode')),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Set a 4-digit Passcode', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_controller.text.length == 4) {
                    await SecureStorageService.setPasscode(_controller.text);
                    widget.onUnlocked();
                  } else {
                    setState(() => _error = 'Enter 4-digit passcode');
                  }
                },
                child: const Text('Set Passcode'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                )
            ],
          ),
        ),
      );
    }

    // If passcode exists, ask for unlock instead
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter Passcode', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
                onSubmitted: (_) => _verifyPasscode(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _verifyPasscode, child: const Text('Unlock')),
            ],
          ),
        ),
      ),
    );
  }
}
