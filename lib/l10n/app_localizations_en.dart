// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get changePin => 'Change App PIN';

  @override
  String get enterNewPin => 'Enter new PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get pinUpdated => 'PIN updated successfully';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get credit => 'Credit';

  @override
  String get cash => 'Cash';

  @override
  String get mostSoldItems => 'Most Sold Items';

  @override
  String get leastSoldItems => 'Least Sold Items';

  @override
  String get lowStockAlerts => 'Low Stock Alerts';

  @override
  String get qtySold => 'Qty Sold';

  @override
  String get qtyLeft => 'Qty Left';
}
