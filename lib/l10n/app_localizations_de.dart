import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get account => 'Account';

  @override
  String get accountLoginName => 'Account Login Name';

  @override
  String get accountOrApplicationPasswordMustBeFilled => 'Entweder Account- oder Awendungspasswort angeben';

  @override
  String get accountPassword => 'Accountpasswort';

  @override
  String get addAccount => 'Account neu';

  @override
  String get addComment => 'Bemerkung hinzufügen';

  @override
  String get address => 'Adresse';

  @override
  String get addService => 'Service neu';

  @override
  String get addValidLink => 'Bitte einen gültigen Link eingeben';

  @override
  String get anErrorOccured => 'Es ist ein Fehler aufgetreten';

  @override
  String get appExtensionAPITest => 'App Extension API Test';

  @override
  String get applicationPassword => 'Anwendungspassword';

  @override
  String get appName => 'CB App';

  @override
  String get articleInfo => 'Artikelinfo';

  @override
  String askForDeletion(String topic) {
    return '$topic wirklich endgültig löschen?';
  }

  @override
  String get availabilities => 'Verfügbarkeiten ';

  @override
  String get booking => 'Buchung';

  @override
  String bookingCancelButton(String isHorizontal) {
    String _temp0 = intl.Intl.selectLogic(
      isHorizontal,
      {
        'true': 'Buchung\nstornieren',
        'false': 'Buchung stornieren',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String get bookingComment => 'Anmerkung zu dieser Buchung';

  @override
  String bookingConfirmButton(String isHorizontal) {
    String _temp0 = intl.Intl.selectLogic(
      isHorizontal,
      {
        'true': 'Buchung\nbestätigen',
        'false': 'Buchung bestätigen',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String get bookinglimits => 'Buchungslimits';

  @override
  String get bookItem => 'Artikel buchen';

  @override
  String get calendar => 'Kalender';

  @override
  String get cancel => 'Abbruch';

  @override
  String get cbAPITest => 'CommonsBooking API Test';

  @override
  String changeViewButtonTooltip(String isMainViewMap) {
    String _temp0 = intl.Intl.selectLogic(
      isMainViewMap,
      {
        'true': 'Wechseln zur Listenansicht',
        'false': 'Wechseln zur Kartenansicht',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String get clearDateSelection => 'Datumsselektion aufheben';

  @override
  String get close => 'Schließen';

  @override
  String get common => 'Allgemein';

  @override
  String get confirm => 'bestätigen';

  @override
  String get contact => 'Kontakt';

  @override
  String get data => 'Daten';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteOfflineData => 'Offline-Daten löschen';

  @override
  String get displayName => 'Anzeigename';

  @override
  String edit(String topic) {
    return '$topic bearbeiten';
  }

  @override
  String get emptyBookingList => 'Keine aktuellen oder zukünftigen Buchungen vorhanden';

  @override
  String enableOfflineUse(String isOfflineEnabled) {
    String _temp0 = intl.Intl.selectLogic(
      isOfflineEnabled,
      {
        'true': 'aktiviert',
        'false': 'deaktiviert',
        'other': '',
      },
    );
    return 'Offline-Nutzung $_temp0';
  }

  @override
  String get english => 'englisch';

  @override
  String get errLoginFailed => 'Anmeldung fehlgeschlagen';

  @override
  String get errNoConnectionCacheEmpty => 'Keine Serviceverbindung und keine Cache Daten';

  @override
  String get errRetrieveAppPassword => 'Fehler: Anwendungspasswort nicht ermittelt\n';

  @override
  String get errSaveAccountAnyway => 'Anwendungspasswort Fehler: Account trotzdem speichern?';

  @override
  String get fieldMustNotBeEmpty => 'Feld darf nicht leer sein';

  @override
  String get filter => 'Filter';

  @override
  String get from => 'Von';

  @override
  String get german => 'deutsch';

  @override
  String get gotoCurrentLocation => 'Ihren Standort anzeigen';

  @override
  String get hdrStartupAction => 'Aktion beim Starten der App';

  @override
  String get imageDisplayNotPossible => 'Bildanzeige nicht möglich';

  @override
  String get infoAppPassword => 'Für die Anmeldung beim Serviceprovider wird ein Anwendungspasswort benötigt.\n\nWenn sie über einen Account beim Serviceanbieter verfügen reicht die Eingabe ihres Accountpassworts das Anwendungspasswort wird dann autom. erzeugt.\n\nSollten sie ein Anwendungspasswort vom Serviceprovider erhalten, oder dieses selbst angelegt haben, können sie es im Feld Anwendungspasswort stattdessen direkt eingeben.';

  @override
  String get infoSelectServiceprovider => 'Serviceanbieter\nauswählen!';

  @override
  String get language => 'sprache';

  @override
  String lastUpdated(String dateTime) {
    return 'Zuletzt aktualisiert: $dateTime';
  }

  @override
  String get link => 'link';

  @override
  String get linkForInternettest => 'Url für Internet Verbindungstest';

  @override
  String get logIn => 'Anmelden';

  @override
  String get loginname => 'Loginname';

  @override
  String get loginTest => 'Login Test';

  @override
  String get loginWithNewAccount => 'Wollen sie sich mit dem neuen Account jetzt anmelden?';

  @override
  String get menu => 'Menü';

  @override
  String get msgAppAPIavailable => 'App Extension API vorhanden!';

  @override
  String get msgAppLoginAvailable => 'App Login aktiviert';

  @override
  String get msgCacheDeleted => 'Offline-Daten für diesen Serviceprovider gelöscht';

  @override
  String get msgCbAPIAvailable => 'CommonsBooking API vorhanden!';

  @override
  String get msgCheckUrl => 'Teste Url';

  @override
  String get msgDataModified => 'Daten geändert';

  @override
  String get msgFailed => 'Fehler!';

  @override
  String get msgLinkAvailable => 'Link Adresse erreichbar!';

  @override
  String get msgNetworkAvailable => 'Netzwerk verfügbar';

  @override
  String get msgNetworkUnavailable => 'Kein Netzwerk verfügbar';

  @override
  String get msgRequestFinishedWithError => 'Anfrage beendet mit Fehlercode:';

  @override
  String get msgRestAPIAvailable => 'Rest API Adresse erreichbar!';

  @override
  String get netTimeoutInSeconds => 'Netzwerktimeout in Sekunden';

  @override
  String get netwokTest => 'Netzwerkverbindung testen';

  @override
  String get newText => 'Neu';

  @override
  String get noRentalInThisPeriod => 'Kein Verleih in diesem Zeitraum';

  @override
  String get noService => 'Kein Service';

  @override
  String get notLoggedIn => 'nicht angemeldet';

  @override
  String get ok => 'OK';

  @override
  String get openBookingCalendar => 'zur Buchung';

  @override
  String get openInNewWindow => 'In neuem Fenster öffnen';

  @override
  String optStartupAction(String startupAction) {
    String _temp0 = intl.Intl.selectLogic(
      startupAction,
      {
        'none': 'Keine',
        'last': 'Letzter Service/Benutzer (Online)',
        'last_offline': 'Letzter Service/Benutzer (Offline)',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String get orAddAccountPassword => 'Oder Accountpasswort eingeben';

  @override
  String get orAddApplicationPassword => 'Oder Anwendungspasswort eingeben';

  @override
  String get pickupInstructions => 'Abhol-Hinweise';

  @override
  String get pleaseSelect => 'bitte auswählen';

  @override
  String get questStillContinue => 'Es existieren Änderungen wollen sie trotzdem weiter?';

  @override
  String register(String topic) {
    return '$topic registrieren';
  }

  @override
  String get reload => 'Aktualisieren';

  @override
  String get reloadLocations => 'Neu laden ...';

  @override
  String get resetMapView => 'Kartenansicht zurücksetzen';

  @override
  String get restAPITest => 'REST API Verbindungstest';

  @override
  String get save => 'Speichern';

  @override
  String get savedSuccessfully => 'Erfolgreich gespeichert';

  @override
  String get seconds => ' Sekunden';

  @override
  String select(String topic) {
    return '$topic auswählen';
  }

  @override
  String get service => 'Service';

  @override
  String get serviceprovider => 'Serviceanbieter';

  @override
  String get setTimeoutUnlimited => 'Timeout auf unbegrenzt setzen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get shortInfo => 'Kurzinfo';

  @override
  String get showBookingsList => 'Buchungsliste anzeigen';

  @override
  String get showZoomButtons => 'Zoom Buttons auf Karte anzeigen';

  @override
  String get siteConnectionTest => 'Website Verbindungstest';

  @override
  String get station => 'Station';

  @override
  String get stationInfo => 'Stationsinfo';

  @override
  String get storno => 'stornieren';

  @override
  String get titleCreateAccount => 'Account anlegen';

  @override
  String get tooltipFilter => 'Anzeige nach best. Kriterien einschränken';

  @override
  String get unknownHTTPStatus => 'unbekannter HTTP Status';

  @override
  String get unlimited => 'unbegrenzt';

  @override
  String get until => 'Bis';

  @override
  String get useNewServiceQuestion => 'Soll der neue Service jetzt verwendet werden?';

  @override
  String get yourBookings => 'Ihre Buchungen';
}
