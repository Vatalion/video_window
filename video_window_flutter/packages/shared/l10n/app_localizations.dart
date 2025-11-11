import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Status label when a capability is not yet enabled
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get capabilityStatusInactive;

  /// Status label when a capability request is being reviewed
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get capabilityStatusInReview;

  /// Status label when a capability is enabled and ready to use
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get capabilityStatusReady;

  /// Status label when a capability cannot be enabled due to blockers
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get capabilityStatusBlocked;

  /// Title for the Capability Center page
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get capabilityPageTitle;

  /// Headline text for capability center
  ///
  /// In en, this message translates to:
  /// **'Manage Your Capabilities'**
  String get capabilityPageHeadline;

  /// Description text explaining the capability center purpose
  ///
  /// In en, this message translates to:
  /// **'Enable capabilities to unlock publishing, payments, and fulfillment features.'**
  String get capabilityPageDescription;

  /// Title for the publish capability card
  ///
  /// In en, this message translates to:
  /// **'Publish Stories'**
  String get capabilityPublishTitle;

  /// Description for the publish capability
  ///
  /// In en, this message translates to:
  /// **'Share your video stories with the community'**
  String get capabilityPublishDescription;

  /// Title for the collect payments capability card
  ///
  /// In en, this message translates to:
  /// **'Collect Payments'**
  String get capabilityPaymentsTitle;

  /// Description for the collect payments capability
  ///
  /// In en, this message translates to:
  /// **'Accept payments from buyers through secure checkout'**
  String get capabilityPaymentsDescription;

  /// Title for the fulfill orders capability card
  ///
  /// In en, this message translates to:
  /// **'Fulfill Orders'**
  String get capabilityFulfillmentTitle;

  /// Description for the fulfill orders capability
  ///
  /// In en, this message translates to:
  /// **'Manage order fulfillment and shipping tracking'**
  String get capabilityFulfillmentDescription;

  /// Button label when capability is already enabled
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get capabilityActionEnabled;

  /// Button label to enable publishing capability
  ///
  /// In en, this message translates to:
  /// **'Enable Publishing'**
  String get capabilityActionEnablePublishing;

  /// Button label to enable payments capability
  ///
  /// In en, this message translates to:
  /// **'Enable Payments'**
  String get capabilityActionEnablePayments;

  /// Button label to enable fulfillment capability
  ///
  /// In en, this message translates to:
  /// **'Enable Fulfillment'**
  String get capabilityActionEnableFulfillment;

  /// Message shown when polling for capability status updates
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get capabilityPollingMessage;

  /// Error title when capability loading fails
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Capabilities'**
  String get capabilityErrorTitle;

  /// Button label to retry loading capabilities
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get capabilityErrorRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
