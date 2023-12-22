import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get account => 'Account';

  @override
  String get accountLoginName => 'Account login name';

  @override
  String get accountOrApplicationPasswordMustBeFilled => 'Account- or Apllication password must be filled';

  @override
  String get accountPassword => 'Account password';

  @override
  String get addAccount => 'Add Account';

  @override
  String get addComment => 'Add comment';

  @override
  String get address => 'Address';

  @override
  String get addService => 'Add Service';

  @override
  String get addValidLink => 'Please use valid Url';

  @override
  String get anErrorOccured => 'An error has occurred';

  @override
  String get appExtensionAPITest => 'App Extension API Test';

  @override
  String get applicationPassword => 'Application password';

  @override
  String get appName => 'CB App';

  @override
  String get articleInfo => 'Article Info';

  @override
  String askForDeletion(String topic) {
    return 'Do you really want to delete this $topic?';
  }

  @override
  String get availabilities => 'Availabilities';

  @override
  String get booking => 'Booking';

  @override
  String bookingCancelButton(String isHorizontal) {
    String _temp0 = intl.Intl.selectLogic(
      isHorizontal,
      {
        'true': 'Cancel\nbooking',
        'false': 'Cancel booking',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String get bookingComment => 'Comments for this Booking';

  @override
  String bookingConfirmButton(String isHorizontal) {
    String _temp0 = intl.Intl.selectLogic(
      isHorizontal,
      {
        'true': 'Confirm\nbooking',
        'false': 'Confirm booking',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String get bookinglimits => 'Bookinglimits';

  @override
  String get bookItem => 'Book item';

  @override
  String get calendar => 'Calendar';

  @override
  String get cancel => 'Cancel';

  @override
  String get cbAPITest => 'CommonsBooking API Test';

  @override
  String changeViewButtonTooltip(String isMainViewMap) {
    String _temp0 = intl.Intl.selectLogic(
      isMainViewMap,
      {
        'true': 'Switch to list view',
        'false': 'Switch to map view',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String get clearDateSelection => 'Clear date selection';

  @override
  String get close => 'Close';

  @override
  String get common => 'Common';

  @override
  String get confirm => 'confirm';

  @override
  String get contact => 'Contact';

  @override
  String get data => 'Data';

  @override
  String get delete => 'Delete';

  @override
  String get deleteOfflineData => 'Clear offline data';

  @override
  String get displayName => 'Displayname';

  @override
  String edit(String topic) {
    return 'edit $topic';
  }

  @override
  String get emptyBookingList => 'No current or future bookings available';

  @override
  String enableOfflineUse(String isOfflineEnabled) {
    String _temp0 = intl.Intl.selectLogic(
      isOfflineEnabled,
      {
        'true': 'enabled',
        'false': 'disabled',
        'other': '',
      },
    );
    return 'Offline use $_temp0';
  }

  @override
  String get english => 'english';

  @override
  String get errLoginFailed => 'Login failed';

  @override
  String get errNoConnectionCacheEmpty => 'No Service connection and empty cache';

  @override
  String get errRetrieveAppPassword => 'Error: Application password not determined\n';

  @override
  String get errSaveAccountAnyway => 'Application password error: Save account anyway?';

  @override
  String get fieldMustNotBeEmpty => 'Field must not be empty';

  @override
  String get filter => 'Filter';

  @override
  String get from => 'From';

  @override
  String get german => 'german';

  @override
  String get gotoCurrentLocation => 'Goto current location';

  @override
  String get hdrStartupAction => 'App startup action';

  @override
  String get imageDisplayNotPossible => 'Image display not possible';

  @override
  String get infoAppPassword => 'An application password is required to log in to the service provider.\n\nIf you have an account with the service provider, it is sufficient to enter your Accountpassword the application password will then be generated automatically.\n\nIf you have received an application password from the service provider, or if you have created on your own, you can enter it directly in the Application password field instead.';

  @override
  String get infoSelectServiceprovider => 'Select\nServiceprovider!';

  @override
  String get language => 'language';

  @override
  String lastUpdated(String dateTime) {
    return 'Last updated: $dateTime';
  }

  @override
  String get link => 'link';

  @override
  String get linkForInternettest => 'Url for testing Connectivity';

  @override
  String get logIn => 'Log in';

  @override
  String get loginname => 'Loginname';

  @override
  String get loginTest => 'Login Test';

  @override
  String get loginWithNewAccount => 'Do you want to log in with the new account now?';

  @override
  String get menu => 'Menu';

  @override
  String get msgAppAPIavailable => 'App Extension API available!';

  @override
  String get msgAppLoginAvailable => 'App Login active';

  @override
  String get msgCacheDeleted => 'Offline-Data deleted for this Serviceprovider';

  @override
  String get msgCbAPIAvailable => 'CommonsBooking API available!';

  @override
  String get msgCheckUrl => 'Check Url';

  @override
  String get msgDataModified => 'Data changed';

  @override
  String get msgFailed => 'Failed!';

  @override
  String get msgLinkAvailable => 'Url connected successfully!';

  @override
  String get msgNetworkAvailable => 'Network available';

  @override
  String get msgNetworkUnavailable => 'Network unavailable';

  @override
  String get msgRequestFinishedWithError => 'Request finished with error code: ';

  @override
  String get msgRestAPIAvailable => 'Rest API available!';

  @override
  String get netTimeoutInSeconds => 'Network timeout in seconds';

  @override
  String get netwokTest => 'Test Network Connectivity';

  @override
  String get newText => 'New';

  @override
  String get noRentalInThisPeriod => 'No rental in this period';

  @override
  String get noService => 'No service';

  @override
  String get notLoggedIn => 'not logged in';

  @override
  String get ok => 'OK';

  @override
  String get openBookingCalendar => 'Bookingcalendar';

  @override
  String get openInNewWindow => 'Open in new Window';

  @override
  String optStartupAction(String startupAction) {
    String _temp0 = intl.Intl.selectLogic(
      startupAction,
      {
        'none': 'None',
        'last': 'Last service/user (online)',
        'last_offline': 'Last service/user (offline)',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String get orAddAccountPassword => 'alternatively add Account password';

  @override
  String get orAddApplicationPassword => 'alternatively add Application password';

  @override
  String get pickupInstructions => 'Pickup Instructions';

  @override
  String get pleaseSelect => 'please select';

  @override
  String get questStillContinue => 'Changes exist do you still want to continue';

  @override
  String register(String topic) {
    return 'register $topic';
  }

  @override
  String get reload => 'Reload';

  @override
  String get reloadLocations => 'Reload ....';

  @override
  String get resetMapView => 'Reset Map View';

  @override
  String get restAPITest => 'REST API connectivity';

  @override
  String get save => 'Save';

  @override
  String get savedSuccessfully => 'Saved successfully';

  @override
  String get seconds => 'seconds';

  @override
  String select(String topic) {
    return 'select $topic';
  }

  @override
  String get service => 'Service';

  @override
  String get serviceprovider => 'Serviceprovider';

  @override
  String get setTimeoutUnlimited => 'Set timeout to unlimited';

  @override
  String get settings => 'Settings';

  @override
  String get shortInfo => 'Shortinfo';

  @override
  String get showBookingsList => 'Show Bookings List';

  @override
  String get showZoomButtons => 'Show zoom buttons on map';

  @override
  String get siteConnectionTest => 'Website connectivity';

  @override
  String get station => 'Station';

  @override
  String get stationInfo => 'Stationinfo';

  @override
  String get storno => 'cancel';

  @override
  String get titleCreateAccount => 'Create Account';

  @override
  String get tooltipFilter => 'Restrict display according to certain criteria';

  @override
  String get unknownHTTPStatus => 'unknown HTTP Status';

  @override
  String get unlimited => 'unlimited';

  @override
  String get until => 'Until';

  @override
  String get useNewServiceQuestion => 'Should the new service be used now?';

  @override
  String get yourBookings => 'Your Bookings';
}
