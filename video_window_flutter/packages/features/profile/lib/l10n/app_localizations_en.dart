// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get capabilityStatusInactive => 'Inactive';

  @override
  String get capabilityStatusInProgress => 'In Progress';

  @override
  String get capabilityStatusInReview => 'In Review';

  @override
  String get capabilityStatusReady => 'Ready';

  @override
  String get capabilityStatusBlocked => 'Blocked';
}
