import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountLoginName.
  ///
  /// In en, this message translates to:
  /// **'Account login name'**
  String get accountLoginName;

  /// No description provided for @accountOrApplicationPasswordMustBeFilled.
  ///
  /// In en, this message translates to:
  /// **'Account- or Apllication password must be filled'**
  String get accountOrApplicationPasswordMustBeFilled;

  /// No description provided for @accountPassword.
  ///
  /// In en, this message translates to:
  /// **'Account password'**
  String get accountPassword;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Search address'**
  String get addAddress;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get addComment;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @addValidLink.
  ///
  /// In en, this message translates to:
  /// **'Please use valid Url'**
  String get addValidLink;

  /// No description provided for @adrChoice.
  ///
  /// In en, this message translates to:
  /// **'Select address'**
  String get adrChoice;

  /// No description provided for @anErrorOccured.
  ///
  /// In en, this message translates to:
  /// **'An error has occurred'**
  String get anErrorOccured;

  /// No description provided for @appExtensionAPITest.
  ///
  /// In en, this message translates to:
  /// **'App Extension API Test'**
  String get appExtensionAPITest;

  /// No description provided for @applicationPassword.
  ///
  /// In en, this message translates to:
  /// **'Application password'**
  String get applicationPassword;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CB App'**
  String get appName;

  /// Added from file location_info_dialog.dart
  ///
  /// In en, this message translates to:
  /// **'Article Info'**
  String get articleInfo;

  /// Ask if deletion is ok
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this {topic}?'**
  String askForDeletion(String topic);

  /// No description provided for @availabilities.
  ///
  /// In en, this message translates to:
  /// **'Availabilities'**
  String get availabilities;

  /// No description provided for @booking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get booking;

  /// A gendered message
  ///
  /// In en, this message translates to:
  /// **'{isHorizontal, select, true{Cancel\nbooking} false{Cancel booking} other{}}'**
  String bookingCancelButton(String isHorizontal);

  /// No description provided for @bookingComment.
  ///
  /// In en, this message translates to:
  /// **'Comments for this Booking'**
  String get bookingComment;

  /// A gendered message
  ///
  /// In en, this message translates to:
  /// **'{isHorizontal, select, true{Confirm\nbooking} false{Confirm booking} other{}}'**
  String bookingConfirmButton(String isHorizontal);

  /// No description provided for @bookinglimits.
  ///
  /// In en, this message translates to:
  /// **'Bookinglimits'**
  String get bookinglimits;

  /// No description provided for @bookItem.
  ///
  /// In en, this message translates to:
  /// **'Book item'**
  String get bookItem;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cbAPITest.
  ///
  /// In en, this message translates to:
  /// **'CommonsBooking API Test'**
  String get cbAPITest;

  /// No description provided for @changeViewButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'{isMainViewMap, select, true{Switch to list view} false{Switch to map view} other{}}'**
  String changeViewButtonTooltip(String isMainViewMap);

  /// No description provided for @clearDateSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear date selection'**
  String get clearDateSelection;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @common.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get common;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'confirm'**
  String get confirm;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteOfflineData.
  ///
  /// In en, this message translates to:
  /// **'Clear offline data'**
  String get deleteOfflineData;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Displayname'**
  String get displayName;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'edit {topic}'**
  String edit(String topic);

  /// No description provided for @emptyBookingList.
  ///
  /// In en, this message translates to:
  /// **'No current or future bookings available'**
  String get emptyBookingList;

  /// No description provided for @enableOfflineUse.
  ///
  /// In en, this message translates to:
  /// **'Offline use {isOfflineEnabled, select, true{enabled} false{disabled} other{}}'**
  String enableOfflineUse(String isOfflineEnabled);

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'english'**
  String get english;

  /// No description provided for @errLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get errLoginFailed;

  /// No description provided for @errNoConnectionCacheEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Service connection and empty cache'**
  String get errNoConnectionCacheEmpty;

  /// No description provided for @errRetrieveAppPassword.
  ///
  /// In en, this message translates to:
  /// **'Error: Application password not determined\n'**
  String get errRetrieveAppPassword;

  /// No description provided for @errSaveAccountAnyway.
  ///
  /// In en, this message translates to:
  /// **'Application password error: Save account anyway?'**
  String get errSaveAccountAnyway;

  /// No description provided for @fieldMustNotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Field must not be empty'**
  String get fieldMustNotBeEmpty;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'german'**
  String get german;

  /// No description provided for @gotoCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Show current location'**
  String get gotoCurrentLocation;

  /// No description provided for @hdrStartupAction.
  ///
  /// In en, this message translates to:
  /// **'App startup action'**
  String get hdrStartupAction;

  /// No description provided for @hintPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get hintPassword;

  /// No description provided for @imageDisplayNotPossible.
  ///
  /// In en, this message translates to:
  /// **'Image display not possible'**
  String get imageDisplayNotPossible;

  /// No description provided for @infoAppPassword.
  ///
  /// In en, this message translates to:
  /// **'An application password is required to log in to the service provider.\n\nIf you have an account with the service provider, it is sufficient to enter your Accountpassword the application password will then be generated automatically.\n\nIf you have received an application password from the service provider, or if you have created on your own, you can enter it directly in the Application password field instead.'**
  String get infoAppPassword;

  /// No description provided for @infoSelectServiceprovider.
  ///
  /// In en, this message translates to:
  /// **'Select\nServiceprovider!'**
  String get infoSelectServiceprovider;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'language'**
  String get language;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {dateTime}'**
  String lastUpdated(String dateTime);

  /// No description provided for @lblMarkerSize.
  ///
  /// In en, this message translates to:
  /// **'Map marker size (Reload map afterwards)'**
  String get lblMarkerSize;

  /// Added from file location_info_dialog.dart
  ///
  /// In en, this message translates to:
  /// **'link'**
  String get link;

  /// No description provided for @linkForInternettest.
  ///
  /// In en, this message translates to:
  /// **'Url for testing Connectivity'**
  String get linkForInternettest;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @loginname.
  ///
  /// In en, this message translates to:
  /// **'Loginname'**
  String get loginname;

  /// No description provided for @loginTest.
  ///
  /// In en, this message translates to:
  /// **'Login Test'**
  String get loginTest;

  /// No description provided for @loginWithNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Do you want to log in with the new account now?'**
  String get loginWithNewAccount;

  /// No description provided for @mapTools.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTools;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @msgAppAPIavailable.
  ///
  /// In en, this message translates to:
  /// **'App Extension API available!'**
  String get msgAppAPIavailable;

  /// No description provided for @msgAppLoginAvailable.
  ///
  /// In en, this message translates to:
  /// **'App Login active'**
  String get msgAppLoginAvailable;

  /// No description provided for @msgCacheDeleted.
  ///
  /// In en, this message translates to:
  /// **'Offline-Data deleted for this Serviceprovider'**
  String get msgCacheDeleted;

  /// No description provided for @msgCbAPIAvailable.
  ///
  /// In en, this message translates to:
  /// **'CommonsBooking API available!'**
  String get msgCbAPIAvailable;

  /// No description provided for @msgCheckUrl.
  ///
  /// In en, this message translates to:
  /// **'Check Url'**
  String get msgCheckUrl;

  /// No description provided for @msgDataModified.
  ///
  /// In en, this message translates to:
  /// **'Data changed'**
  String get msgDataModified;

  /// No description provided for @msgFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed!'**
  String get msgFailed;

  /// No description provided for @msgLinkAvailable.
  ///
  /// In en, this message translates to:
  /// **'Url connected successfully!'**
  String get msgLinkAvailable;

  /// No description provided for @msgNetworkAvailable.
  ///
  /// In en, this message translates to:
  /// **'Network available'**
  String get msgNetworkAvailable;

  /// No description provided for @msgNetworkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable'**
  String get msgNetworkUnavailable;

  /// No description provided for @msgNoAddress.
  ///
  /// In en, this message translates to:
  /// **'No suitable address was found'**
  String get msgNoAddress;

  /// No description provided for @msgRequestFinishedWithError.
  ///
  /// In en, this message translates to:
  /// **'Request finished with error code: '**
  String get msgRequestFinishedWithError;

  /// No description provided for @msgRestAPIAvailable.
  ///
  /// In en, this message translates to:
  /// **'Rest API available!'**
  String get msgRestAPIAvailable;

  /// No description provided for @netTimeoutInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Network timeout in seconds'**
  String get netTimeoutInSeconds;

  /// No description provided for @netwokTest.
  ///
  /// In en, this message translates to:
  /// **'Test Network Connectivity'**
  String get netwokTest;

  /// No description provided for @newText.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newText;

  /// No description provided for @noRentalInThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No rental in this period'**
  String get noRentalInThisPeriod;

  /// No description provided for @noService.
  ///
  /// In en, this message translates to:
  /// **'No service'**
  String get noService;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'not logged in'**
  String get notLoggedIn;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @openBookingCalendar.
  ///
  /// In en, this message translates to:
  /// **'Bookingcalendar'**
  String get openBookingCalendar;

  /// No description provided for @openInNewWindow.
  ///
  /// In en, this message translates to:
  /// **'Open in new Window'**
  String get openInNewWindow;

  /// No description provided for @optStartupAction.
  ///
  /// In en, this message translates to:
  /// **'{startupAction, select, none{None} last{Last service/user (online)} last_offline{Last service/user (offline)} other{}}'**
  String optStartupAction(String startupAction);

  /// No description provided for @orAddAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'alternatively add Account password'**
  String get orAddAccountPassword;

  /// No description provided for @orAddApplicationPassword.
  ///
  /// In en, this message translates to:
  /// **'alternatively add Application password'**
  String get orAddApplicationPassword;

  /// No description provided for @pickupInstructions.
  ///
  /// In en, this message translates to:
  /// **'Pickup Instructions'**
  String get pickupInstructions;

  /// No description provided for @pleaseSelect.
  ///
  /// In en, this message translates to:
  /// **'please select'**
  String get pleaseSelect;

  /// No description provided for @questStillContinue.
  ///
  /// In en, this message translates to:
  /// **'Changes exist do you still want to continue'**
  String get questStillContinue;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'register {topic}'**
  String register(String topic);

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @reloadLocations.
  ///
  /// In en, this message translates to:
  /// **'Reload ....'**
  String get reloadLocations;

  /// No description provided for @resetMapView.
  ///
  /// In en, this message translates to:
  /// **'Reset Map View'**
  String get resetMapView;

  /// No description provided for @restAPITest.
  ///
  /// In en, this message translates to:
  /// **'REST API connectivity'**
  String get restAPITest;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'select {topic}'**
  String select(String topic);

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @serviceprovider.
  ///
  /// In en, this message translates to:
  /// **'Serviceprovider'**
  String get serviceprovider;

  /// No description provided for @setTimeoutUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Set timeout to unlimited'**
  String get setTimeoutUnlimited;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @shortInfo.
  ///
  /// In en, this message translates to:
  /// **'Shortinfo'**
  String get shortInfo;

  /// No description provided for @showBookingsList.
  ///
  /// In en, this message translates to:
  /// **'Show Bookings List'**
  String get showBookingsList;

  /// No description provided for @showLocationRadius.
  ///
  /// In en, this message translates to:
  /// **'Show surrounding radius'**
  String get showLocationRadius;

  /// No description provided for @showZoomButtons.
  ///
  /// In en, this message translates to:
  /// **'Show zoom buttons on map'**
  String get showZoomButtons;

  /// No description provided for @siteConnectionTest.
  ///
  /// In en, this message translates to:
  /// **'Website connectivity'**
  String get siteConnectionTest;

  /// No description provided for @station.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get station;

  /// No description provided for @stationInfo.
  ///
  /// In en, this message translates to:
  /// **'Stationinfo'**
  String get stationInfo;

  /// No description provided for @storno.
  ///
  /// In en, this message translates to:
  /// **'cancel'**
  String get storno;

  /// No description provided for @titleCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get titleCreateAccount;

  /// No description provided for @tooltipFilter.
  ///
  /// In en, this message translates to:
  /// **'Restrict display according to certain criteria'**
  String get tooltipFilter;

  /// No description provided for @ttResetMarkerSize.
  ///
  /// In en, this message translates to:
  /// **'Reset marker size to original value'**
  String get ttResetMarkerSize;

  /// No description provided for @unknownHTTPStatus.
  ///
  /// In en, this message translates to:
  /// **'unknown HTTP Status'**
  String get unknownHTTPStatus;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'unlimited'**
  String get unlimited;

  /// No description provided for @until.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get until;

  /// No description provided for @useNewServiceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Should the new service be used now?'**
  String get useNewServiceQuestion;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get userName;

  /// Headline Bookings List
  ///
  /// In en, this message translates to:
  /// **'Your Bookings'**
  String get yourBookings;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
