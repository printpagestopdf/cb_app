import 'package:cb_app/main.dart';
import 'package:cb_app/wp/cb_map_model.dart';
import 'package:cb_app/data/booking_stats.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:typed_data';
import 'cb_bookings_data.dart';
import 'package:cb_app/data/host_info_provider.dart';
import 'package:cb_app/parts/utils.dart';
import 'cb_map_list.dart';
import 'package:hive/hive.dart';
import 'site_info.dart' as wpsite;
import 'dart:convert';
import 'dart:async';

// Uri _baseUri = Uri(scheme: 'https', host: 'www.freie-lastenradl.de');
// Uri _baseUri = Uri(scheme: 'https', host: 'freie-lasten.org'); //keine API
// Uri _baseUri = Uri(scheme: 'https', host: 'flotte-berlin.de');
// Uri _baseUri = Uri(scheme: 'https', host: 'essener-lastenrad.de');

Uri _baseUri = Uri(scheme: 'http', host: 'localhost', port: 8888);

// Uri _baseUri = Uri(scheme: 'https', host: 'laptrr.rr.net.eu.org');

// String _wp_app_password_pm = 'PetraMaier:izL4 OgBn xsMx Fndr nc3N NqDf';
// String _wp_app_password_gen = 'Gen:ZuFl idwj 6trR SF5M tisd WVlz';

class BookingResult {
  final String msg;
  final bool isError;
  final int statusCode;
  final BookingsData? bookingsData;

  BookingResult({required this.msg, this.isError = false, this.statusCode = 200, this.bookingsData});
}

class WpApi {
  static Dio dio = Dio(BaseOptions(
    connectTimeout: null, //const Duration(seconds: 20),
    receiveTimeout: null, //const Duration(seconds: 20),
    responseType: ResponseType.plain,
    validateStatus: (status) => true, //get status errorcodes instead of Exception
  ));
  // static var httpClient = http.Client();

  static const String apiPrefix = "/wp-json";
  static const String apiPostfix = "/cbappapi/v1";

  // ignore: unnecessary_brace_in_string_interps
  static const String basePath = "${apiPrefix}${apiPostfix}";

  static Uri? _currentHost;
  static bool corsLimit = false;

  static DateTime? locationCacheDateTime;
  static DateTime? bookingCacheDateTime;

  static String lastAuthError = "";

  static ({String? user, String? secret})? auth;

  static String get appPassword {
    if (auth?.user != null && auth?.secret != null) {
      return "${auth!.user}:${auth!.secret}";
    } else {
      return "";
    }
  }

  static Uri get currentHost {
    return (_currentHost == null) ? _baseUri : _currentHost!;
  }

  static set currentHost(Uri? url) => _currentHost = url;

  static bool useCache = false;

  static String getItemThumbnailUrl(LocationItem item) {
    if (CBApp.currentPlattform == "TargetPlatform.web" && WpApi.corsLimit) {
      final url = currentHost.replace(path: '$basePath/apputils/media', queryParameters: {
        'post_id': item.id.toString(),
      });
      return url.toString();
    } else {
      return item.thumbnail ?? "";
    }
  }

  static String getBookingItemThumbnailUrl(BookingsItemData booking) {
    if (CBApp.currentPlattform == "TargetPlatform.web" && WpApi.corsLimit) {
      final url = currentHost.replace(path: '$basePath/apputils/media', queryParameters: {
        'post_id': booking.itemId.toString(),
      });
      return url.toString();
    } else {
      return booking.itemThumbnail ?? "";
    }
  }

  static Future<wpsite.SiteInfo> siteInfo([Uri? urlOverride, bool? fromCache]) async {
    if (fromCache == true) {
      Map<dynamic, dynamic>? siteInfo = await Hive.lazyBox('cbappCaching').get("siteinfo_${currentHost.origin}");
      if (siteInfo == null || (siteInfo["json"] == null)) {
        //no cache data available
        throw Exception("No cached site Info available");
      } else {
        Map<String, dynamic> responseBody = jsonDecode(siteInfo["json"]);
        return wpsite.SiteInfo.fromJson(responseBody);
      }
    }

    final url =
        (urlOverride != null) ? urlOverride : currentHost.replace(path: '/wp-json/', queryParameters: {'_embed': '1'});
    final response = await dio.getUri(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          "Accept": "application/json",
        },
      ),
    );
    Map<String, dynamic> responseBody = jsonDecode(response.data);
    if (response.statusCode == null) throw Exception("HTTP Status is NULL");
    if (response.statusCode! < 200 || response.statusCode! >= 400) {
      throw Exception(response.data);
    } else {
      final wpsite.SiteInfo siteInfoData = wpsite.SiteInfo.fromJson(responseBody);

      if (urlOverride == null && useCache) {
        Hive.lazyBox('cbappCaching')
            .put("siteinfo_${currentHost.origin}", <String, dynamic>{"date": DateTime.now(), "json": response.data});
      }

      return siteInfoData;
    }
  }

  static String getSiteIconForPlatform(String baseUrl) {
    if (CBApp.currentPlattform == "TargetPlatform.web" && WpApi.corsLimit) {
      final url = currentHost.replace(path: '$basePath/apputils/site_icon');
      return url.toString();
    } else {
      return baseUrl;
    }
  }

  static Future<CbMapList> fetchCbMap([Map<String, String>? args]) async {
    locationCacheDateTime = null;
    if (args != null && args['fromCache'] != null) {
      Map<dynamic, dynamic>? mapLocations =
          await Hive.lazyBox('cbappCaching').get("maplocations_${currentHost.origin}");
      if (mapLocations == null || (mapLocations["json"] == null && mapLocations["jsonCBAPI"] == null)) {
        //no cache data available
        throw Exception("No Service connection and empty cache");
      } else {
        if (mapLocations["date"] != null) locationCacheDateTime = mapLocations["date"];
        return (mapLocations["json"] != null)
            ? cbMapListFromJson(mapLocations["json"])
            : cbMapListFromJsonCBAPI(mapLocations["jsonCBAPI"]);
      }
    }

    final url = (args == null)
        ? currentHost.replace(path: '$basePath/location_items')
        : currentHost.replace(path: '$basePath/location_items', queryParameters: args);

    // final response = await http.get(url, headers: {"Accept": "application/json"});
    final Response response = await dio.getUri(
      url,
      options: Options(
        headers: {"Accept": "application/json"},
      ),
    );
    if (response.statusCode == null) throw Exception("HTTP Status is NULL");
    if (response.statusCode! < 200 || response.statusCode! >= 400) {
      Map<String, dynamic> responseBody = jsonDecode(response.data);
      WpApi.lastAuthError = responseBody['message'];

      throw Exception("Unable to fetch Data (${response.statusCode}). ${responseBody['message']}");
    }

    final cbMapList = cbMapListFromJson(response.data);
    if (useCache) {
      Hive.lazyBox('cbappCaching')
          .put("maplocations_${currentHost.origin}", <String, dynamic>{"date": DateTime.now(), "json": response.data});
    }
    return cbMapList;
  }

  static Future<CbMapList> fetchCbMapCBAPI([bool locationsOnly = false]) async {
    final url = (locationsOnly)
        ? currentHost.replace(path: '/wp-json/commonsbooking/v1/locations')
        : currentHost.replace(path: '/wp-json/commonsbooking/v1/items');

    // final response = await http.get(url, headers: {"Accept": "application/json"});
    final Response response = await dio.getUri(url, options: Options(headers: {"Accept": "application/json"}));

    if (response.statusCode == null) throw Exception("HTTP Status is NULL");
    if (response.statusCode! < 200 || response.statusCode! >= 400) {
      throw Exception("Unable to fetch Data (${response.statusCode})");
    }

    final cbMapList = cbMapListFromJsonCBAPI(response.data);
    if (useCache) {
      Hive.lazyBox('cbappCaching').put(
          "maplocations_${currentHost.origin}", <String, dynamic>{"date": DateTime.now(), "jsonCBAPI": response.data});
    }
    return cbMapList;
  }

  static Future<String> registerUser(String userName, String password, String clientId, {Uri? hostUri}) async {
    final url = (hostUri == null)
        ? WpApi.currentHost.replace(path: '$basePath/apputils/register')
        : hostUri.replace(path: '$basePath/apputils/register');

    Response response;
    try {
      response = await dio.postUri(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            "Accept": "application/json",
          },
        ),
        data: jsonEncode({
          'user_name': userName,
          'password': password,
          'client_id': clientId,
        }),
      );
    } catch (_) {
      throw Exception("Beim Verbindungsversuch ist ein Netzwerkfehler aufgetreten!");
    }
    // print(String.fromCharCodes(response.bodyBytes));
    Map<String, dynamic> responseBody = jsonDecode(response.data);
    // inspect(responseBody);
    if (response.statusCode == null) throw Exception("HTTP Status is NULL");

    if (response.statusCode! < 200 || response.statusCode! >= 400) {
      throw Exception(responseBody['message']);
    } else {
      return responseBody['data'];
    }
  }

  static Future<bool> checkAuth({String? loginName, String? secret, Uri? hostUri}) async {
    bool ret = false;
    WpApi.lastAuthError = "";
    try {
      String basicPw = (loginName != null && secret != null) ? "$loginName:$secret" : WpApi.appPassword;
      String encoded = base64Encode(basicPw.codeUnits);
      String basicAuth = 'BASIC $encoded';

      final url = (hostUri != null)
          ? hostUri.replace(path: '$basePath/apputils/check_auth')
          : WpApi.currentHost.replace(path: '$basePath/apputils/check_auth');
      final Response response = await dio.postUri(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            "Accept": "application/json",
            'Authorization': basicAuth,
          },
        ),
      );

      if (response.statusCode == null) throw Exception("HTTP Status is NULL");
      if (response.statusCode! < 200 || response.statusCode! >= 400) {
        Map<String, dynamic> responseBody = jsonDecode(response.data);
        WpApi.lastAuthError = responseBody['message'];
        ret = false;
      } else {
        ret = true;
      }
    } catch (ex) {
      WpApi.lastAuthError = ex.toString();
      ret = false;
    }
    return ret;
  }

  static Future<Uint8List> getImageBinary(String orgUrl, [ValueNotifier<Uint8List?>? data]) async {
    try {
      String encoded = base64Encode(WpApi.appPassword.codeUnits);
      String basicAuth = 'BASIC $encoded';

      // final url = Uri.parse('$_host$basePath/bookings');
      final url = WpApi.currentHost.replace(path: '$basePath/apputils/uploads', queryParameters: {
        'org_url': orgUrl,
      });

      final Response response = await dio.getUri(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': basicAuth,
          },
        ),
      );

      if (response.statusCode == null) throw Exception("HTTP Status is NULL");
      if (response.statusCode! >= 200 && response.statusCode! < 400) {
        if (data != null) {
          data.value = response.data;
          return data.value!;
        }
        return response.data;
      } else {
        throw Exception("No image");
      }
    } catch (e) {
      // inspect(e);
      rethrow;
    }
  }

  static Future<void> testHost(HostInfoProvider hostInfo) async {
    final regex = RegExp(r'^.*<([^>]*)>;\s*rel=.*api.w.org.*$');
    String? restApiUrl;

    hostInfo.hasNetwork = LoadingState.loading;
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      bool connectionTestFailed = true;
      if (hostInfo.connectionTestUri != null) {
        try {
          Response response = await dio.headUri(hostInfo.connectionTestUri!);
          if (response.statusCode == null) throw Exception(l10n().unknownHTTPStatus);
          if (response.statusCode! >= 200 && response.statusCode! < 400) {
            connectionTestFailed = false;
          }
        } catch (_) {}
      }

      if (connectionTestFailed) {
        hostInfo.msgs["hasNetworkConnection"] = l10n().msgNetworkUnavailable;
        hostInfo.hasNetwork = LoadingState.failed;
        return;
      }
    }
    hostInfo.msgs["hasNetworkConnection"] = l10n().msgNetworkAvailable;
    hostInfo.hasNetwork = LoadingState.loaded;

    // hostInfo.mapTilesAvailable = LoadingState.loading;
    // try {
    //   LoadingState status = LoadingState.failed;
    //   http.Response response;
    //   for (String srv in <String>['a', 'b', 'c']) {
    //     // ignore: unnecessary_brace_in_string_interps
    //     response = await http
    //         .head(Uri(scheme: 'https', host: "${srv}.tile.openstreetmap.org", path: '/0/0/0.png'))
    //         .timeout(WpApi.httpTimeout, onTimeout: WpApi.timeoutResponse);
    //     if (response.statusCode >= 200 && response.statusCode < 400) {
    //       status = LoadingState.loaded;
    //       break;
    //     }
    //   }
    //   hostInfo.mapTilesAvailable = status;
    // } catch (ex) {
    //   hostInfo.mapTilesAvailable = LoadingState.failed;
    // }

    hostInfo.msgs["mainUrlConnection"] = "${l10n().msgCheckUrl} ${hostInfo.hostUrl.toString()}";
    hostInfo.mainUrlConnection = LoadingState.loading;
    try {
      Response response = await dio.headUri(hostInfo.hostUrl);
      if (response.statusCode == null) throw Exception("HTTP Status is NULL");
      if (response.statusCode! < 200 || response.statusCode! >= 400) {
        hostInfo.msgs["mainUrlConnection"] = (response.statusMessage != null && response.statusMessage!.isNotEmpty)
            ? response.statusMessage!
            : "${l10n().msgRequestFinishedWithError} ${response.statusCode.toString()}";
        hostInfo.mainUrlConnection = LoadingState.failed;
      } else {
        hostInfo.msgs["mainUrlConnection"] = l10n().msgLinkAvailable;
        // print(response.headers['link']);
        hostInfo.mainUrlConnection = LoadingState.loaded;
        if (response.headers.map.containsKey('link')) {
          final match = regex.firstMatch(response.headers.map['link']!.first);
          if (match != null && match.groupCount == 1) {
            restApiUrl = match.group(1);
          }
        }
      }
    } catch (ex) {
      hostInfo.msgs["mainUrlConnection"] = ex.toString();
      hostInfo.mainUrlConnection = LoadingState.failed;
    }

    restApiUrl ??= "${hostInfo.hostUrl.toString()}/wp-json/";

    hostInfo.hasCBApi = LoadingState.loading;
    hostInfo.hasCBAppApi = LoadingState.loading;
    hostInfo.supportsAuthentication = LoadingState.loading;
    hostInfo.msgs["restApiConnection"] = "${l10n().msgCheckUrl} $restApiUrl";
    hostInfo.restApiConnection = LoadingState.loading;
    try {
      wpsite.SiteInfo restApiInfo = await siteInfo(Uri.parse(restApiUrl));
      // inspect(restApiInfo);
      if (restApiInfo.routes == null) {
        hostInfo.hasCBApi = LoadingState.failed;
        hostInfo.hasCBAppApi = LoadingState.failed;
      } else {
        if (restApiInfo.routes!.contains('/commonsbooking/v1/items')) {
          hostInfo.hasCBApi = LoadingState.loaded;
          hostInfo.msgs["cbApiConnection"] = l10n().msgCbAPIAvailable;
        } else {
          hostInfo.hasCBApi = LoadingState.failed;
        }

        if (restApiInfo.routes!.contains('$apiPostfix/location_items')) {
          hostInfo.hasCBAppApi = LoadingState.loaded;
          hostInfo.msgs["cbAppApiConnection"] = l10n().msgAppAPIavailable;
        } else {
          hostInfo.hasCBAppApi = LoadingState.failed;
        }
      }
      if (restApiInfo.authentication == null ||
          !restApiInfo.authentication!.authentications!.containsKey('application-passwords')) {
        hostInfo.supportsAuthentication = LoadingState.failed;
      } else {
        hostInfo.supportsAuthentication = LoadingState.loaded;
        hostInfo.msgs["supportsAuthentication"] = l10n().msgAppLoginAvailable;
      }
      hostInfo.msgs["restApiConnection"] = l10n().msgRestAPIAvailable;
      hostInfo.restApiConnection = LoadingState.loaded;

      // }
    } catch (ex) {
      hostInfo.hasCBApi = LoadingState.failed;
      hostInfo.hasCBAppApi = LoadingState.failed;
      hostInfo.supportsAuthentication = LoadingState.failed;
      hostInfo.msgs["restApiConnection"] = ex.toString();
      hostInfo.restApiConnection = LoadingState.failed;
    }

    hostInfo.finalCheck = true;
    hostInfo.onNotify();
  }

  static bool hasBookingCache() {
    try {
      return Hive.lazyBox('cbappCaching').containsKey("bookings_${WpApi.auth!.user}_${WpApi.currentHost.origin}");
    } catch (_) {
      return false;
    }
  }

  static Future<BookingResult> bookingNew(
      {required String itemId,
      required String locationId,
      required DateTime repetitionStart,
      required DateTime repetitionEnd,
      String comment = "",
      String postStatus = "confirmed"}) async {
    DateTime repititionStartUtc = DateTime.utc(repetitionStart.year, repetitionStart.month, repetitionStart.day);
    DateTime repetitionEndUtc = DateTime.utc(repetitionEnd.year, repetitionEnd.month, repetitionEnd.day, 23, 59, 59);

    return _bookingPOST({
      'item-id': itemId,
      'location-id': locationId,
      'repetition-start': (repititionStartUtc.millisecondsSinceEpoch ~/ 1000).toString(),
      'repetition-end': (repetitionEndUtc.millisecondsSinceEpoch ~/ 1000).toString(),
      'comment': comment,
      'post_status': postStatus,
    });
  }

  static Future<BookingResult> _bookingPOST(Map<String, String> args) async {
    try {
      String encoded = base64Encode(WpApi.appPassword.codeUnits);
      String basicAuth = 'BASIC $encoded';

      // final url = Uri.parse('$_host$basePath/bookings');
      final url = WpApi.currentHost.replace(path: '$basePath/bookings/');
      final response = await WpApi.dio.postUri(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            "Accept": "application/json",
            'Authorization': basicAuth,
          },
        ),
        data: jsonEncode(args),
      );

      Map<String, dynamic> responseBody = jsonDecode(response.data);
      // inspect(responseBody);
      if (response.statusCode == null) throw Exception("HTTP Status is NULL");
      if (response.statusCode!! >= 400) {
        return BookingResult(msg: responseBody['message'], isError: true, statusCode: response.statusCode!);
      } else {
        return BookingResult(msg: responseBody['message'], statusCode: response.statusCode!);
      }
    } on Exception catch (e) {
      // inspect(e);
      return BookingResult(msg: e.toString(), isError: true, statusCode: 500);
    }
  }

  static Future<BookingResult> bookingUpdate(
      {required String bookingID,
      required String itemId,
      required String locationId,
      required DateTime repetitionStart,
      required DateTime repetitionEnd,
      String postStatus = "confirmed"}) async {
    DateTime repititionStartUtc = DateTime.utc(repetitionStart.year, repetitionStart.month, repetitionStart.day);
    DateTime repetitionEndUtc = DateTime.utc(repetitionEnd.year, repetitionEnd.month, repetitionEnd.day, 23, 59, 59);

    return _bookingPATCH(bookingID, {
      'item-id': itemId,
      'location-id': locationId,
      'repetition-start': (repititionStartUtc.millisecondsSinceEpoch ~/ 1000).toString(),
      'repetition-end': (repetitionEndUtc.millisecondsSinceEpoch ~/ 1000).toString(),
      'post_status': postStatus,
    });
  }

  static Future<BookingResult> _bookingPATCH(String bookingID, Map<String, String> args) async {
    try {
      String encoded = base64Encode(WpApi.appPassword.codeUnits);
      String basicAuth = 'BASIC $encoded';

      // final url = Uri.parse('$_host$basePath/bookings');
      final url = WpApi.currentHost.replace(path: '$basePath/bookings/$bookingID');
      final Response response = await WpApi.dio.patchUri(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            "Accept": "application/json",
            'Authorization': basicAuth,
          },
        ),
        data: jsonEncode(args),
      );

      // print(String.fromCharCodes(response.bodyBytes));
      Map<String, dynamic> responseBody = jsonDecode(response.data);
      if (response.statusCode == null) throw Exception("HTTP Status is NULL");
      if (response.statusCode! < 200 || response.statusCode! >= 400) {
        return BookingResult(msg: responseBody['message'], isError: true, statusCode: response.statusCode!);
      } else {
        return BookingResult(msg: responseBody['message'], statusCode: response.statusCode!);
      }
    } on Exception catch (e) {
      // inspect(e);
      return BookingResult(msg: e.toString(), isError: true, statusCode: 500);
    }
  }

  static Future<BookingStats> getBookingStats() async {
    try {
      String encoded = base64Encode(WpApi.appPassword.codeUnits);
      String basicAuth = 'BASIC $encoded';

      final url = WpApi.currentHost.replace(path: '$basePath/bookings/booking_stats/');
      final Response response = await WpApi.dio.getUri(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            "Accept": "application/json",
            'Authorization': basicAuth,
          },
        ),
      );
      Map<String, dynamic> responseBody = jsonDecode(response.data);
      return BookingStats.fromJson(responseBody);
    } catch (e) {
      return BookingStats();
    }
  }

  static Future<BookingResult> getBookings(Map<String, dynamic> args) async {
    try {
      if (args['fromCache'] != null) {
        Map<dynamic, dynamic>? mapBookings =
            await Hive.lazyBox('cbappCaching').get("bookings_${WpApi.auth!.user}_${WpApi.currentHost.origin}");
        if (mapBookings == null || mapBookings["json"] == null) {
          //no cache data available
          throw Exception("No Server connection and empty cache");
        } else {
          Map<String, dynamic> cachedJson = jsonDecode(mapBookings["json"]);
          final BookingsData bookingsData = BookingsData.fromJson(cachedJson['data']);
          if (mapBookings["date"] != null) bookingCacheDateTime = mapBookings["date"];

          return BookingResult(bookingsData: bookingsData, msg: cachedJson['message'], statusCode: 200);
        }
      }

      String encoded = base64Encode(WpApi.appPassword.codeUnits);
      String basicAuth = 'BASIC $encoded';

      final url = WpApi.currentHost.replace(path: '$basePath/bookings/', queryParameters: args);
      final Response response = await WpApi.dio.getUri(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            "Accept": "application/json",
            'Authorization': basicAuth,
          },
        ),
      );

      Map<String, dynamic> responseBody = jsonDecode(response.data);
      if (response.statusCode == null) throw Exception("HTTP Status is NULL");
      if (response.statusCode! < 200 || response.statusCode! >= 400) {
        return Future.error(responseBody['message']);
      } else {
        if (useCache) {
          Hive.lazyBox('cbappCaching').put("bookings_${WpApi.auth!.user}_${WpApi.currentHost.origin}",
              <String, dynamic>{"date": DateTime.now(), "json": response.data});
        }

        final BookingsData bookingsData = BookingsData.fromJson(responseBody['data']);

        // Hive.lazyBox('cbappCaching').put("bookings_${WpApi.auth!.user}_${WpApi.currentHost.origin}",
        //     <String, dynamic>{"date": DateTime.now(), "json": response.data});

        return BookingResult(
            bookingsData: bookingsData, msg: responseBody['message'], statusCode: response.statusCode!);
      }
    } catch (e) {
      return BookingResult(msg: e.toString(), bookingsData: null, statusCode: 405);
    }
  }

  static void clearCache(dynamic hostKey) {
    if (hostKey != null) {
      Iterable<dynamic> keys = Hive.lazyBox('cbappCaching').keys.where((element) =>
          (element.contains(RegExp("^bookings_.*_$hostKey\$")) ||
              element.contains(RegExp("^siteinfo_$hostKey\$")) ||
              element.contains(RegExp("^maplocations_$hostKey\$"))));
      Hive.lazyBox('cbappCaching').deleteAll(keys);
    }
  }
} /*class WpApi */


