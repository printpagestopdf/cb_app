// import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nanoid/nanoid.dart';
import 'package:expandable/expandable.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'dart:async';
import 'package:intl/intl.dart';

T? castNull<T>(dynamic x) => x is T ? x : null;

T castDef<T>(dynamic x, T fallback) => x is T ? x : fallback;

class CbAppService {
  static final CbAppService _singleton = CbAppService._internal();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String cbAppEncKey = 'cbAppEncKey';
  late String clientNanoId;
  late Box encryptedBox;
  late Box settingsBox;
  late LazyBox cachingBox;

  factory CbAppService() {
    return _singleton;
  }

  CbAppService._internal() {
    // initStorages();
  }

  Future<void> initStorages() async {
    var containsEncryptionKey = await secureStorage.containsKey(key: cbAppEncKey);
    if (!containsEncryptionKey) {
      var key = Hive.generateSecureKey();
      await secureStorage.write(key: cbAppEncKey, value: base64UrlEncode(key));
    }

    final key = await secureStorage.read(key: cbAppEncKey);
    final encryptionKeyUint8List = base64Url.decode(key!);

    encryptedBox = await Hive.openBox('vaultBox', encryptionCipher: HiveAesCipher(encryptionKeyUint8List));

    settingsBox = await Hive.openBox('cbappSettings');

    cachingBox = await Hive.openLazyBox('cbappCaching');

    await loadTestSettings();

    String? myClientNanoId;
    if ((myClientNanoId = getSetting('clientNanoId')) == null) {
      clientNanoId = nanoid();
      putSetting('clientNanoId', clientNanoId);
    } else {
      clientNanoId = myClientNanoId!;
    }

    // Map<dynamic, dynamic>? h = await getSetting('hostlist');
    // hostList = (h == null) ? <dynamic, dynamic>{} : h;

    // settingsBox.keys.forEach((value) async {
    //   print(await getSetting(value));
    // });

    // inspect(encryptedBox.toMap());
    // print(getEnc('localhost:8888#PetraMaier'));
  }

  ({String encKey, String hostPart, String userPart})? storagekeyForAppPassword(String userLogin, String hostKey) {
    if (userLogin.isEmpty || !hostList.containsKey(hostKey)) return null;
    String strPort = castDef<String>(hostList[hostKey]['port'], "").isNotEmpty ? ":${hostList[hostKey]['port']}" : "";
    String hostPart = "${hostList[hostKey]['domain']}$strPort";
    return (encKey: "$hostPart#$userLogin", hostPart: hostPart, userPart: userLogin);
  }

  String addHostFromUrl(String hostUrl, [String title = "", Map<dynamic, dynamic>? users]) {
    Map<dynamic, dynamic> hostMap = urlToHostMap(hostUrl);
    if (hostMap.isEmpty) return "";

    final String strPort = (hostMap['port'] as String).isNotEmpty ? ":${hostMap['port']}" : "";
    String hostKey = "${hostMap['domain']}$strPort";
    Map<dynamic, dynamic> hl = hostList;
    hl[hostKey] = <dynamic, dynamic>{
      "key": hostKey,
      "title": title,
      "users": users ??= <dynamic, dynamic>{},
    }..addAll(hostMap);

    // putSetting('hostlist', hostList);
    hostList = hl; //save because of setter
    return hostKey;
  }

  bool updateHost(String hostKey, Map<dynamic, dynamic> hostMap) {
    Map<dynamic, dynamic> hl = hostList;

    hl[hostKey] = hl[hostKey]..addAll(hostMap);
    hostList = hl; //save because of setter
    return true;
  }

  bool deleteHost(String hostKey) {
    Map<dynamic, dynamic> hl = hostList;
    if (hl.remove(hostKey) == null) return false;

    hostList = hl; //save because of setter

    ({String encKey, String hostPart, String userPart})? storageKey = storagekeyForAppPassword("dummy", hostKey);
    if (storageKey != null) {
      deleteEncPrefixAll("${storageKey.hostPart}#");
    }

    return true;
  }

  bool deleteUser(String hostKey, String userKey) {
    Map<dynamic, dynamic> hl = hostList;
    Map<dynamic, dynamic>? host = hostList[hostKey];
    if (host == null || host['users'] == null) return false;

    if ((host['users'] as Map<dynamic, dynamic>).remove(userKey) == null) return false;

    ({String encKey, String hostPart, String userPart})? storageKey = storagekeyForAppPassword(userKey, hostKey);
    if (storageKey != null) {
      deleteEnc(storageKey.encKey);
    }

    hostList = hl; //save because of setter
    return true;
  }

  Map<dynamic, dynamic> urlToHostMap(String hostUrl) {
    Uri? uri = Uri.tryParse(hostUrl);
    if (uri == null) return <dynamic, dynamic>{};

    return {
      "domain": uri.host,
      "port": uri.hasPort ? uri.port.toString() : '',
      "prot": uri.scheme,
    };
  }

  Uri? uriFromHostKey(String? hostKey) {
    if (hostKey == null) return null;
    Map<dynamic, dynamic>? curHost = hostList[hostKey];
    if (curHost == null) return null;

    return Uri(host: curHost['domain'], port: int.tryParse(curHost['port']), scheme: curHost['prot']);
  }

  String urlFromHostKey(String? hostKey) {
    Uri? uri = uriFromHostKey(hostKey);
    if (uri == null) return "";

    return uri.toString();
  }

  bool addOrUpdateUser(String hostKey, Map<dynamic, dynamic> user) {
    try {
      Map<dynamic, dynamic> h = hostList;
      // hostList;

      h[hostKey]['users'] ??= <dynamic, dynamic>{};

      if (h[hostKey]['users'][user['key']] == null) {
        h[hostKey]['users'][user['key']] = user;
      } else {
        h[hostKey]['users'][user['key']] = {}
          ..addAll(h[hostKey]['users'][user['key']])
          ..addAll(user);
      }

      hostList = h;

      return true;
    } catch (_) {
      return false;
    }
  }

  void putEnc(String key, dynamic value) {
    encryptedBox.put(key, value);
  }

  dynamic getEnc(String key) {
    return encryptedBox.get(key);
  }

  void deleteEnc(String key) {
    if (encryptedBox.containsKey(key)) {
      encryptedBox.delete(key);
    }
  }

  bool hasEnc(String key) {
    return encryptedBox.containsKey(key);
  }

  void deleteEncPrefixAll(String prefix) {
    Iterable toDelete = encryptedBox.keys.where((element) => (element as String).startsWith(prefix));
    if (toDelete.isNotEmpty) {
      encryptedBox.deleteAll(toDelete);
    }
  }

  void putSetting(String key, dynamic value) {
    settingsBox.put(key, value);
  }

  dynamic getSetting(String key, [dynamic defaultValue]) {
    return settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> loadTestSettings() async {
    return;
    if (!kDebugMode || settingsBox.isNotEmpty) return;

    final String response = await rootBundle.loadString('assets/test_data.json');
    final data = await json.decode(response);

    await settingsBox.deleteFromDisk();
    settingsBox = await Hive.openBox('cbappSettings');
    await encryptedBox.clear();

    Map<String, dynamic> authKeys = data['authKeys'];
    (data as Map<String, dynamic>).remove('authKeys');

    await settingsBox.putAll(data);
    encryptedBox.putAll(authKeys);
    // inspect(data['servers']);
    // print(rootBundle.loadString('test_data.json'));
  }

  Map<dynamic, dynamic> get hostList {
    try {
      return settingsBox.get('hostlist', defaultValue: <dynamic, dynamic>{});
    } catch (ex) {
      return <dynamic, dynamic>{};
    }
  }

  set hostList(Map<dynamic, dynamic> h) {
    settingsBox.put('hostlist', h);
  }
}

Future<bool> prefetchImageList(BuildContext context, List<String> urlList) async {
  for (String url in urlList) {
    await precacheImage(FastCachedImageProvider(url), context);
    // print("Loaded: $url");
  }

  // print("PREFETCH FINISHED");
  return true;
}

AppLocalizations l10n() {
  try {
    Map<dynamic, dynamic> localeMap =
        Hive.box('cbappSettings').get("locale", defaultValue: {"languageCode": "de", "countryCode": "DE"});
    return lookupAppLocalizations(Locale(localeMap["languageCode"], localeMap["countryCode"]));
  } catch (_) {
    return lookupAppLocalizations(const Locale("de", "DE"));
  }
}

extension StringExtensions on String? {
  bool isNullOrEmpty() => (this == null || this!.isEmpty);
}

extension AppLocalize<T> on BuildContext {
  get l10n {
    return AppLocalizations.of(this);
  }

  bool get isMobile => MediaQuery.of(this).size.width <= 500.0;

  // bool get isTablet => MediaQuery.of(this).size.width < 1024.0 && MediaQuery.of(this).size.width >= 650.0;

  // bool get isSmallTablet => MediaQuery.of(this).size.width < 650.0 && MediaQuery.of(this).size.width > 500.0;

  // bool get isDesktop => MediaQuery.of(this).size.width >= 1024.0;

  // bool get isSmall => MediaQuery.of(this).size.width < 850.0 && MediaQuery.of(this).size.width >= 560.0;

  double get width => MediaQuery.of(this).size.width;

  double get height => MediaQuery.of(this).size.height;

  Size get size => MediaQuery.of(this).size;

  EdgeInsets get dlgPadding => (isMobile)
      ? const EdgeInsets.symmetric(horizontal: 10.0, vertical: 24.0)
      : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0);
}

abstract class LocationInfoInterface {
  String? formattedContactInfoOneLine;
  String? formattedPickupInstructionsOneLine;
  String? formattedAddressOneLine;
  String? locationDescription;
  String? comment;

  String? formattedContactInfoOneLineFormat;
  String? formattedPickupInstructionsOneLineFormat;
  String? formattedAddressOneLineFormat;
  String? locationDescriptionFormat;

  String? commentFormat;

  bool hasLocationInfo();
}

typedef ItemCreator<S> = S Function();

class FormItemControllers<T extends ValueNotifier> {
  final Map<String, T> ffControllers = <String, T>{};
  ItemCreator<T> creator;

  FormItemControllers(this.creator);

  // ignore: unused_element
  T ctrl(String key) {
    if (!ffControllers.containsKey(key)) ffControllers[key] = creator();

    return ffControllers[key]!;
  }

  // ignore: unused_element
  void dispose() {
    for (T item in ffControllers.values) {
      item.dispose();
    }
  }
}

String strGetStartOfWeek(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(getStartOfWeek(date));
}

DateTime getStartOfWeek(DateTime date) {
  // Subtrahiere die Tage vom aktuellen Wochentag, um den Montag der Woche zu erhalten
  int difference = date.weekday - DateTime.monday;
  if (difference < 0) {
    difference += 7;
  }
  return date.subtract(Duration(days: difference));
}

int compDateTimeNull(DateTime? s1, DateTime? s2) {
  if (s1 == null && s2 == null) {
    return 0;
  } else if (s1 == null) {
    return -1;
  } else if (s2 == null) {
    return 1;
  } else {
    return s1.compareTo(s2);
  }
}

void showModalBottomMsg(
  BuildContext context,
  String msg, [
  bool isError = false,
  int duration = 4000,
]) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      Color backgroundColor =
          (isError) ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.background;

      if (duration > 0) {
        Timer(Duration(milliseconds: duration), () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });
      }

      return Wrap(
        children: [
          Container(
            // height: 30,
            color: backgroundColor,
            // child: Center(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                      child: Text(
                    msg,
                    textAlign: TextAlign.center,
                  )),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: context.l10n.close,
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class ExpandableInfo extends StatelessWidget {
  final Widget body;
  const ExpandableInfo({required this.body, super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: const Padding(
          padding: EdgeInsets.only(left: 5),
          child: Text(
            "Info",
            style: TextStyle(fontStyle: FontStyle.italic),
          )),
      collapsed: const SizedBox.shrink(),
      expanded: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: body, // Text(infoText),
        ),
      ),
      theme: const ExpandableThemeData(
        expandIcon: Icons.help_outline,
        collapseIcon: Icons.help_outline,
        iconSize: 14,
        iconPlacement: ExpandablePanelIconPlacement.left,
        iconPadding: EdgeInsets.all(0),
        headerAlignment: ExpandablePanelHeaderAlignment.center,
      ),
    );
  }
}

/*
 * To use just simple provide the RGB value and call the mdColor straight up
 * e.g. CustomMaterialColor(88, 207, 194).mdColor
 */
class CustomMaterialColor {
  final int r;
  final int g;
  final int b;

  CustomMaterialColor(this.r, this.g, this.b);

  MaterialColor get mdColor {
    Map<int, Color> color = {
      50: Color.fromRGBO(r, g, b, .1),
      100: Color.fromRGBO(r, g, b, .2),
      200: Color.fromRGBO(r, g, b, .3),
      300: Color.fromRGBO(r, g, b, .4),
      400: Color.fromRGBO(r, g, b, .5),
      500: Color.fromRGBO(r, g, b, .6),
      600: Color.fromRGBO(r, g, b, .7),
      700: Color.fromRGBO(r, g, b, .8),
      800: Color.fromRGBO(r, g, b, .9),
      900: Color.fromRGBO(r, g, b, 1),
    };
    return MaterialColor(Color.fromRGBO(r, g, b, 1).value, color);
  }
}

Future<bool> yesNoDialog(BuildContext context, String title, String description,
    {String? okTxt, String? cancelTxt}) async {
  okTxt ??= context.l10n.ok;
  cancelTxt ??= context.l10n.cancel;
  bool? ret = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(description),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelTxt!),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(okTxt!),
        ),
      ],
    ),
  );

  return ret ?? false;
}
