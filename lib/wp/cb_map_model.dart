// import 'dart:js_interop';
import 'dart:async';
import 'dart:convert';
// import 'dart:ffi';
// import 'dart:js_interop';
import 'package:cb_app/wp/cb_bookings_data.dart';
import 'package:dio/dio.dart';
import 'package:cb_app/wp/cb_map_list.dart';
import 'package:cb_app/wp/wp_api.dart';
import 'package:cb_app/main.dart';
import 'package:cb_app/wp/site_info.dart' as wpsite;
import 'package:cb_app/data/host_info_provider.dart';
import 'package:cb_app/parts/utils.dart';
import 'package:cb_app/data/booking_stats.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LoadingState {
  loading,
  loaded,
  failed,
  inactive,
  unknown,
}

class ModelMapData extends ChangeNotifier {
  CbAppService settings = CbAppService();

  CbMapList _mapList = CbMapList(mapLocations: <String, MapLocation>{});
  wpsite.SiteInfo? _siteInfo;
  HostInfoProvider? _hostCapabilities;
  final bool _isError = false;
  bool _noDispose = true;
  String? _currentLocationId;
  String? _currentItemId;

  static final ModelMapData _singleton = ModelMapData._internal();

  factory ModelMapData() {
    return _singleton;
  }

  void realDispose() {
    _noDispose = false;
    dispose();
  }

  @override
  // ignore: must_call_super
  void dispose() {
    if (_noDispose) return;
    super.dispose();
  }

  ModelMapData._internal() {
    onStartup();
  }

  bool filtersChanged = false;
  Map<dynamic, dynamic> filters = <dynamic, dynamic>{};
  void toggleFilter(dynamic key, [dynamic value = true]) {
    if (filters.containsKey(key)) {
      filters.remove(key);
    } else {
      filters[key] = value;
    }
    filtersChanged = true;
    onChange();
    filtersChanged = false;
  }

  bool hasCorsLimitation = false;
  LoadingState mapTilesAvailable = LoadingState.failed;

  bool isMainViewMap = true;
  void toggleMainView([bool? showMap]) {
    if (showMap != null) {
      isMainViewMap = showMap;
    } else {
      isMainViewMap = !isMainViewMap;
    }
    settings.putSetting("lastIsMainViewMap", isMainViewMap);
    onChange();
  }

  bool needsLogin = false;
  void fireLogin() {
    needsLogin = true;
    onChange();
    needsLogin = false;
  }

  bool doCacheLoading = false;
  void fireCacheLoading() {
    doCacheLoading = true;
    onChange();
    doCacheLoading = false;
  }

  bool registerNewHost = false;
  void fireRegisterNewHost() {
    registerNewHost = true;
    onChange();
    registerNewHost = false;
  }

  LatLng? _currentMapLocation;
  LatLng? get currentMapLocation => _currentMapLocation;
  set currentMapLocation(LatLng? value) {
    if (value != _currentMapLocation) {
      _currentMapLocation = value;
      onChange();
    }
  }

  int currentMapLocationType = 0;

  bool _showLocationRadius = false;
  bool get showLocationRadius => _showLocationRadius;
  set showLocationRadius(bool show) {
    if (show != _showLocationRadius) {
      _showLocationRadius = show;
      onChange();
    }
  }

  bool isInitiallyCentered = false;

  bool loadingPhasesFinished = false;
  bool openHostRunning = false;

  String mapDataErrMsg = "";
  LoadingState mapDataLoadingState = LoadingState.inactive;

  String siteInfoErrMsg = "";
  LoadingState siteInfoLoadingState = LoadingState.inactive;

  String _currentHost = "";
  String get currentHost => _currentHost;
  set currentHost(String hostId) {
    settings.putSetting('lastHost', <dynamic, dynamic>{
      'host': hostId,
      'user': '',
    });
    _currentHost = hostId;
  }

  bool deleteHost(String hostKey) {
    bool ret = settings.deleteHost(hostKey);
    if (ret && hostKey == _currentHost) {
      _currentHost = "";
      onChange();
    }

    return ret;
  }

  bool deleteUser(String hostKey, String userKey) {
    bool ret = settings.deleteUser(hostKey, userKey);
    if (ret && userKey == _currentUser) {
      _currentUser = "";
      onChange();
    }

    return ret;
  }

  Uri? get currentHostUri {
    if (currentHostMap.isEmpty) return null;
    Map<dynamic, dynamic> host = currentHostMap;
    return Uri(scheme: host['prot'], host: host['domain'], port: int.tryParse(host['port']));
  }

  Map<dynamic, dynamic> get currentHostMap {
    if (currentHost.isEmpty || !settings.hostList.containsKey(currentHost)) return <dynamic, dynamic>{};
    return settings.hostList[currentHost];
  }

  String _currentUser = "";
  String get currentUser => _currentUser;
  set currentUser(String userId) {
    settings.putSetting('lastHost', <dynamic, dynamic>{
      'host': _currentHost,
      'user': userId,
    });
    _currentUser = userId;
  }

  bool? _hasBookingCache;
  bool get hasBookingCache {
    _hasBookingCache ??= WpApi.hasBookingCache();

    return _hasBookingCache!;
  }

  bool isCache = false;
  bool isLoggedIn = false;
  LoadingState cacheLoad = LoadingState.inactive;

  // LoadingState bookingStatsLoad = LoadingState.inactive;
  BookingStats? bookingStats;
  void loadBookingStats([bool reload = false]) {
    if (bookingStats != null && !reload) return;
    if (!isLoggedIn) {
      bookingStats = BookingStats();
      onChange();
    } else {
      WpApi.getBookingStats().then((value) {
        bookingStats = value;
        onChange();
      });
    }
  }

  DateTime? get locationCacheDateTime => WpApi.locationCacheDateTime;
  DateTime? get bookingCacheDateTime => WpApi.bookingCacheDateTime;

  Map<dynamic, dynamic> get currentUserMap {
    if (currentUser.isEmpty || currentHostMap.isEmpty || currentHostMap['users'][currentUser] == null) {
      return <dynamic, dynamic>{};
    }
    return currentHostMap['users'][currentUser];
  }

  bool clearCache(dynamic hostKey) {
    String key = settings.urlFromHostKey(hostKey);
    if (key.isEmpty) return false;
    WpApi.clearCache(key);
    return true;
  }

  Future<void> addHost(Map<String, dynamic> params) async {
    bool isFirstHost = settings.hostList.isEmpty;
    currentHost = settings.addHostFromUrl(params["hostUrl"], params["title"]);
    WpApi.currentHost = Uri.parse(params['hostUrl']!);
    if (isFirstHost) {
      fireLogin();
    }
    onChange();
  }

  String addHostSync(Map<String, dynamic> params) {
    String hostKey = settings.addHostFromUrl(params["hostUrl"], params["title"]);
    return hostKey;
  }

  String get startupAction {
    return settings.getSetting("startupAction", "last").toString();
  }

  set startupAction(String startupAction) {
    settings.putSetting("startupAction", startupAction);
  }

  Future<void> onStartup() async {
    await settings.initStorages(); //initialize the service singleton
    isMainViewMap = settings.getSetting("lastIsMainViewMap", true);
    _markerIconSize = settings.getSetting("markerIconSize", 24.0);
    updateNetworkTimeout();
    if (CBApp.currentPlattform != "TargetPlatform.linux") {
      checkLocationService();
    } else {
      _locationServiceEnabled = false;
    }

    if (await onHostlistEmpty()) return;
    // if (settings.hostList.isEmpty) {
    //   fireRegisterNewHost();
    //   return;
    // }

    onChange();
    if (startupAction == "none") return;

    final Map<dynamic, dynamic>? lastHost = settings.getSetting('lastHost');
    if (lastHost == null) return;
    if (startupAction == "last_offline") {
      openHost(lastHost['host'], lastHost['user'], true);
    } else {
      openHost(lastHost['host'], lastHost['user']);
    }
  }

  Future<bool> onHostlistEmpty() async {
    if (settings.hostList.isNotEmpty) return false;
    // if (settings.hostList["cbappapi.rr.net.eu.org"] != null) return false;

    Map<dynamic, dynamic> demo;
    try {
      String demositeJsonStr =
          (await WpApi.dio.get("https://raw.githubusercontent.com/printpagestopdf/cb_app/main/samples/demosite.json"))
              .data;
      demo = jsonDecode(demositeJsonStr);
    } catch (_) {
      demo = {
        "hostUrl": "https://cbappapi.rr.net.eu.org",
        "title": "Demo Serviceanbieter",
        "user": {"name": "Demobenutzer 1", "key": "demo1", "login": "demo1", "appPassword": "EGF2xiTfxokFQnzxkwCUOxdJ"}
      };
    }

    String hostKey = addHostSync({"hostUrl": demo["hostUrl"], "title": demo["title"]});
    if (demo["user"] != null) {
      settings.addOrUpdateUser(
          hostKey, {"name": demo["user"]["name"], "key": demo["user"]["key"], "login": demo["user"]["login"]});
      updateAppPassword(demo["user"]["login"], demo["user"]["appPassword"], hostKey);
    }

    settings.putSetting('lastHost', <dynamic, dynamic>{
      'host': hostKey,
      'user': (demo["user"] != null) ? demo["user"]["key"] : '',
    });

    return false;
  }

  bool displayStartup = true;

  Locale? _currentLocale;
  Locale get currentLocale {
    if (_currentLocale == null) {
      try {
        Map<dynamic, dynamic> localeMap = settings.getSetting("locale", {"languageCode": "de", "countryCode": "DE"});
        _currentLocale = Locale(localeMap["languageCode"], localeMap["countryCode"]);
      } catch (_) {
        return const Locale("de", "DE");
      }
    }
    return _currentLocale!;
  }

  set currentLocale(Locale value) {
    if (value != currentLocale) {
      settings.putSetting(
          "locale", <dynamic, dynamic>{"languageCode": value.languageCode, "countryCode": value.countryCode});
      _currentLocale = value;
      onChange();
    }
  }

  bool get showZoom => (settings.getSetting("showZoom") as bool?) ?? false;
  set showZoom(bool value) {
    if (showZoom != value) {
      settings.putSetting("showZoom", value);
      onChange();
    }
  }

  double _mapRadiusMarker = 1000.0;
  double get mapRadiusMarker => _mapRadiusMarker;
  set mapRadiusMarker(double value) {
    if (value != _mapRadiusMarker) {
      _mapRadiusMarker = value;
      onChange();
    }
  }

  double _markerIconSize = 24.0;
  double get markerIconSize => _markerIconSize;
  set markerIconSize(double value) {
    if (value != _markerIconSize) {
      _markerIconSize = value;
      settings.putSetting("markerIconSize", value);
      // onChange();
    }
  }

  void updateNetworkTimeout([String? strTimeout]) {
    int? timeout;
    if (strTimeout != null) {
      timeout = int.tryParse(strTimeout);
      settings.putSetting("netTimeout", timeout);
    } else {
      timeout = settings.getSetting("netTimeout");
    }

    if (timeout == null) {
      WpApi.dio.options.connectTimeout = null;
      WpApi.dio.options.receiveTimeout = null;
    } else {
      WpApi.dio.options.connectTimeout = Duration(seconds: timeout);
      WpApi.dio.options.receiveTimeout = Duration(seconds: timeout);
    }
  }

  bool _locationServiceEnabled = false;
  bool get locationServiceEnabled => _locationServiceEnabled;
  set locationServiceEnabled(bool value) {
    if (value != _locationServiceEnabled) {
      _locationServiceEnabled = value;
      onChange();
    }
  }

  LocationPermission _locationPermission = LocationPermission.unableToDetermine;
  LocationPermission get locationPermission => _locationPermission;
  set locationPermission(LocationPermission value) {
    if (value != _locationPermission) {
      _locationPermission = value;
      onChange();
    }
  }

  Future<void> checkLocationService() async {
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }
  }

  Future<void> requestAppPassword(String userName, String password) async {
    String strHost =
        WpApi.currentHost.host + ((WpApi.currentHost.hasPort) ? ":${WpApi.currentHost.port.toString()}" : "");
    String encKey = "$strHost#$userName";

    if (settings.getEnc(encKey) == null) {
      String appPassword = await WpApi.registerUser(userName, password, settings.clientNanoId);
      settings.putEnc(encKey, appPassword);
    }

    await openHost(strHost, userName);
  }

  bool hasAppPassword(String hostKey, String userLogin) {
    ({String encKey, String hostPart, String userPart})? storageKey =
        settings.storagekeyForAppPassword(userLogin, hostKey);
    if (storageKey == null) return false;

    return settings.hasEnc(storageKey.encKey);
  }

  bool updateAppPassword(String userLogin, String appPassword, String hostKey) {
    ({String encKey, String hostPart, String userPart})? storageKey =
        settings.storagekeyForAppPassword(userLogin, hostKey);
    if (storageKey == null) return false;

    settings.putEnc(storageKey.encKey, appPassword);

    return true;
  }

  Future<String> retrieveAppPassword(String userName, String password, String hostKey) async {
    Uri? hostUri = settings.uriFromHostKey(hostKey);
    if (hostUri == null) throw Exception("Serviceanbieter nicht registriert");

    return await WpApi.registerUser(userName, password, settings.clientNanoId, hostUri: hostUri);
  }

  Future<bool> checkAuth(String loginName, String secret, Uri hostUri) async {
    return await WpApi.checkAuth(loginName: loginName, secret: secret, hostUri: hostUri);
  }

  Future<void> openHost(String strHost, [String? strUser, bool? forceOffline]) async {
    try {
      if (_mapList.mapLocations.isNotEmpty) {
        _mapList = CbMapList(mapLocations: <String, MapLocation>{});
        mapDataLoadingState = LoadingState.loaded;
      }
      if (_siteInfo != null) {
        _siteInfo = null;
        siteInfoLoadingState = LoadingState.loaded;
      }
      displayStartup = false;
      currentUser = "";
      isLoggedIn = false;
      isCache = false;
      WpApi.auth = null;

      openHostRunning = true;
      mapTilesAvailable = LoadingState.loaded;
      hasCorsLimitation = false;
      _hasBookingCache = null;
      bookingStats = null;
      isInitiallyCentered = false;
      onChange();

      final dynamic host = settings.hostList[strHost];
      if (host == null) throw Exception("Serviceprovider doesn't exists");
      Uri hostUri = Uri(scheme: host['prot'], host: host['domain'], port: int.tryParse(host['port']));
      currentHost = strHost;
      WpApi.auth = (user: strUser, secret: null);
      currentUser = (strUser ?? "");
      WpApi.useCache = (host?['cacheEnabled'] as bool?) ?? true;
      WpApi.currentHost = hostUri;

      if (forceOffline == true) {
        await loadSiteInfo(fromCache: true);
        await loadLocations(fromCache: true);
        isCache = true;

        return;
      }

      //Check host capabilities if we have a host
      _hostCapabilities = HostInfoProvider(hostUri,
          silent: true, connectionTestUri: Uri.tryParse(settings.getSetting("connectionTestUrl", "https://1.1.1.1/")));
      await WpApi.testHost(_hostCapabilities!);
      if (hostCapabilities?.mainUrlConnection == LoadingState.failed &&
          hostCapabilities?.hasCBAppApi == LoadingState.loaded) {
        hasCorsLimitation = true;
        WpApi.corsLimit = true;
      }

      // mapTilesAvailable = _hostCapabilities!.mapTilesAvailable;
      // mapTilesAvailable = LoadingState.loaded;

      if (hostCapabilities?.hasNetwork == LoadingState.failed ||
          (hostCapabilities?.hasCBApi == LoadingState.failed && hostCapabilities?.hasCBAppApi == LoadingState.failed)) {
        await loadSiteInfo(fromCache: true);
        await loadLocations(fromCache: true);
        isCache = true;

        return;
      }

      //Load Site if we have a host
      if (hostCapabilities?.restApiConnection == LoadingState.loaded) {
        await loadSiteInfo();
      }

      // if (strUser == "") {
      //   fireLogin();
      //   return;
      // }

      // if (strUser != null) {
      //   settings.addOrUpdateUser(currentHost, <dynamic, dynamic>{
      //     "key": strUser,
      //     "name": strUser,
      //     "login": strUser,
      //   });
      // } else {

      if (strUser == null || strUser.isEmpty) {
        if (hostCapabilities?.hasCBAppApi == LoadingState.loaded) {
          await loadLocations();
          if (WpApi.useCache) {
            fireCacheLoading();
          }
        } else if (hostCapabilities?.hasCBApi == LoadingState.loaded) {
          await loadLocationsCBAPI();
          if (WpApi.useCache) {
            fireCacheLoading();
          }
        } else {
          throw (Exception("Verbindung zum Service fehlgeschlagen"));
        }
        return;
      }

      currentUser = strUser;

      if (hostCapabilities?.supportsAuthentication != LoadingState.loaded ||
          hostCapabilities?.hasCBAppApi != LoadingState.loaded) {
        throw Exception("Keine Anmeldung möglich und/oder keine App API");
      }
      ({String encKey, String hostPart, String userPart})? storageKey =
          settings.storagekeyForAppPassword(strUser, strHost);
      String? secret = settings.getEnc(storageKey?.encKey ?? "");

      if (secret == null) {
        fireLogin();
        return;
      }

      // WpApi.appPassword = "$strUser:$secret";
      WpApi.auth = (user: strUser, secret: secret);

      isLoggedIn = await WpApi.checkAuth();

      await loadLocations();
      if (WpApi.useCache) {
        fireCacheLoading();
      }
    } on DioException catch (dEx) {
      if (WpApi.useCache) {
        await loadSiteInfo(fromCache: true);
        await loadLocations(fromCache: true);
        isCache = true;
        throw Exception(dEx.message);
      } else {
        mapDataLoadingState = LoadingState.failed;
        siteInfoLoadingState = LoadingState.failed;
        isLoggedIn = false;
        mapDataErrMsg = "An error occured!\n${dEx.toString()}";
      }
    } catch (ex) {
      mapDataLoadingState = LoadingState.failed;
      siteInfoLoadingState = LoadingState.failed;
      isLoggedIn = false;
      mapDataErrMsg = "An error occured!\n${ex.toString()}";
    } finally {
      openHostRunning = false;
      onChange();
    }
  }

  HostInfoProvider? get hostCapabilities => _hostCapabilities;
  wpsite.SiteInfo? get siteInfo => _siteInfo;

  CbMapList get mapList => _mapList;
  bool get isError => _isError;

  MapLocation? get currentLocation {
    if (_currentLocationId == null) return null;
    if (!mapList.mapLocations.containsKey(_currentLocationId)) return null;
    return mapList.mapLocations[_currentLocationId];
  }

  LocationItem? get currentItem {
    MapLocation? curLocation = currentLocation;
    if (curLocation == null || _currentItemId == null) return null;
    if (!curLocation.idxItems.containsKey(_currentItemId)) return null;
    return curLocation.idxItems[_currentItemId];
  }

  void setCurrent({String? locationId, String? itemId}) {
    _currentLocationId = locationId;
    _currentItemId = itemId;
  }

  Future<void> cacheLocationItemImages(BuildContext context) async {
    cacheLoad = LoadingState.loading;

    if (context.mounted) {
      List<String> thumbnails = <String>[];

      if (isLoggedIn) {
        //cache bookings list
        BookingResult result = await WpApi.getBookings({});
        if (result.bookingsData?.data != null) {
          for (BookingsItemData booking in result.bookingsData!.data!) {
            thumbnails.add(WpApi.getBookingItemThumbnailUrl(booking));
          }
        }
      }

      for (MapLocation mapLocation in mapList.mapLocations.values) {
        for (LocationItem locationItem in mapLocation.idxItems.values) {
          if (locationItem.thumbnail != null) {
            // thumbnails.add(locationItem.thumbnail!);
            thumbnails.add(WpApi.getItemThumbnailUrl(locationItem));
          }
        }
      }
      // ignore: use_build_context_synchronously
      await prefetchImageList(context, thumbnails);
    }

    cacheLoad = LoadingState.loaded;

    // onChange();
    return;
  }

  Future<void> loadSiteInfo({bool fromCache = false}) async {
    try {
      siteInfoLoadingState = LoadingState.loading;
      onChange();
      if (fromCache) {
        _siteInfo = await WpApi.siteInfo(null, true);
      } else {
        _siteInfo = await WpApi.siteInfo();
      }
      if (_siteInfo != null) {
      } else {
        _siteInfo = null;
      }
      siteInfoLoadingState = LoadingState.loaded;
      onChange();
    } catch (ex) {
      siteInfoLoadingState = LoadingState.failed;
      siteInfoErrMsg = ex.toString();
      _siteInfo = null;
      onChange();
    }
  }

  Future<void> loadLocations({bool fromCache = false}) async {
    _mapList = CbMapList(mapLocations: <String, MapLocation>{});
    loadingPhasesFinished = false;
    mapDataLoadingState = LoadingState.loading;
    mapDataErrMsg = "";
    onChange();
    if (fromCache) {
      await WpApi.fetchCbMap({'fromCache': 'true'}).then((values) {
        _mapList = values;
        mapDataLoadingState = LoadingState.loaded;
        loadingPhasesFinished = true;
        onChange();
      });
    } else {
      await Future.wait(
        [
          WpApi.fetchCbMap({'availabilities': 'true'}).then((values) {
            _mapList = values;
            // print("Locations+availabilities loaded");
            mapDataLoadingState = LoadingState.loaded;
            loadingPhasesFinished = true;
            onChange();
          }),
          WpApi.fetchCbMap().then((values) {
            if (_mapList.mapLocations.isEmpty) {
              _mapList = values;
              // print("Locations loaded");
              mapDataLoadingState = LoadingState.loaded;
              onChange();
            }
          }),
        ],
      );
    }
  }

  Future<void> loadLocationsCBAPI() async {
    _mapList = CbMapList(mapLocations: <String, MapLocation>{});
    mapDataLoadingState = LoadingState.loading;
    loadingPhasesFinished = false;
    mapDataErrMsg = "";
    onChange();

    await Future.wait([
      WpApi.fetchCbMapCBAPI(true).then((values) {
        if (_mapList.mapLocations.isEmpty) {
          _mapList = values;
          // print("Locations loaded");
          mapDataLoadingState = LoadingState.loaded;
          onChange();
        }
      }),
      WpApi.fetchCbMapCBAPI().then((values) {
        _mapList = values;
        // print("Locations+availabilities loaded");
        mapDataLoadingState = LoadingState.loaded;
        loadingPhasesFinished = true;
        onChange();
      }),
    ]);
  }

  void onChange() {
    notifyListeners();
  }
}
