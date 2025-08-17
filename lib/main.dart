import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/party_list_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/bill_book_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/passcode_lock_screen.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final passcode = await SecureStorageService.getPasscode();

  // ✅ Safely evaluate if passcode exists and is not empty
  final bool shouldShowLock = (passcode != null && passcode.isNotEmpty);

  runApp(MyApp(showLock: shouldShowLock));
}

class MyApp extends StatelessWidget {
  final bool showLock;

  const MyApp({super.key, required this.showLock});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Ledger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      initialRoute: showLock ? '/lock' : '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/parties': (context) => const PartyListScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/billbook': (context) => const BillBookScreen(),
        '/add-transaction': (context) => const AddTransactionScreen(transactionType: '',),
        '/settings': (context) => const SettingsScreen(),
        '/lock': (context) => const PasscodeLockScreen(),
      },
    );
  }
}