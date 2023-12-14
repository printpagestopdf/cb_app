// import 'package:cb_app/wp/cb_item_list.dart';
// import 'dart:js_interop';

// import 'package:cb_app/wp/cb_location_list.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cb_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:cb_app/wp/cb_map_list.dart';
import 'package:cb_app/forms/marker_popup.dart';
import 'package:cb_app/forms/background_animation.dart';
import 'package:cb_app/forms/register_host.dart';
import 'package:cb_app/forms/location_items_list.dart';
import 'package:cb_app/wp/site_info.dart' as wpsite;
import 'package:cb_app/wp/wp_api.dart';
import 'package:cb_app/pages/bookings_page.dart';
import 'package:cb_app/pages/settings_page.dart';
// import 'package:cb_app/forms/lr_marker.dart' as globals;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
// import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
// import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:cb_app/wp/cb_map_model.dart';
import 'package:cb_app/forms/lr_marker.dart';
import 'package:cb_app/forms/availabilities_calendar.dart';
import 'package:provider/provider.dart';
// import 'wp/wp_api.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer';
// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:cb_app/parts/utils.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// final navigatorKey = GlobalKey<NavigatorState>();
final pageBucket = PageStorageBucket();

void main() async {
  /* if (kDebugMode) */ HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await FastCachedImageConfig.init(clearCacheAfter: const Duration(days: 15));

  runApp(const CBApp());
}

class CBApp extends StatelessWidget {
  static GlobalKey flutterMapKey = GlobalKey();
  static GlobalKey<ScaffoldState> cbAppKey = GlobalKey();

  static String currentPlattform = "unknown";

  const CBApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<ModelMapData>(create: (context) => ModelMapData()),
        ],
        child: Consumer<ModelMapData>(builder: (context, modelMap, child) {
          return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'CB App',
              theme: FlexThemeData.light(
                scheme: FlexScheme.greenM3,
                // useMaterial3: true,
              ),
              darkTheme: FlexThemeData.dark(
                scheme: FlexScheme.greenM3,
                // useMaterial3: true,
              ),
              themeMode: ThemeMode.system,
              locale: modelMap.currentLocale, // const Locale("de", "DE"),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              // supportedLocales: AppLocalizations.supportedLocales,

              // localizationsDelegates: const [
              //   GlobalMaterialLocalizations.delegate,
              //   GlobalWidgetsLocalizations.delegate,
              //   GlobalCupertinoLocalizations.delegate,
              // ],
              supportedLocales: const [
                Locale('en'), // English
                Locale('de'), // German
              ],
              initialRoute: "/",
              routes: {
                "/": (context) => const CBAppMain(title: 'Freie Lastenradl'),
                "/bookings": (context) => const BookingsPage(),
                "/settings": (context) => const SettingsPage(),
              });
        }));
  }
}

class CBAppMain extends StatefulWidget {
  const CBAppMain({super.key, required this.title});
  final String title;

  @override
  State<CBAppMain> createState() => _CBAppMainState();
}

class _CBAppMainState extends State<CBAppMain> {
  final PopupController _popupController = PopupController();
  // final SuperclusterMutableController _mutableController = SuperclusterMutableController();
  final SuperclusterImmutableController _immutableController = SuperclusterImmutableController();
  final MapController mapController = MapController();
  late String _connectInfoTooltip = context.l10n.noService;

  LatLngBounds _getMaxBounds(Iterable<Marker> markers) {
    var lngs = markers.map<double>((m) => m.point.longitude).toList();
    var lats = markers.map<double>((m) => m.point.latitude).toList();

    double topMost = lngs.reduce(max);
    double leftMost = lats.reduce(min);
    double rightMost = lats.reduce(max);
    double bottomMost = lngs.reduce(min);

    return LatLngBounds(
      LatLng(rightMost, topMost),
      LatLng(leftMost, bottomMost),
    );
  }

  void _initialMapBounds(CbMapList mapList) {
    if (mapList.mapLocations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        var lngs = mapList.mapLocations.entries.map((m) => m.value.lon).toList();
        var lats = mapList.mapLocations.entries.map((m) => m.value.lat).toList();

        double topMost = lngs.reduce(max);
        double leftMost = lats.reduce(min);
        double rightMost = lats.reduce(max);
        double bottomMost = lngs.reduce(min);

        LatLngBounds bounds = LatLngBounds(
          LatLng(rightMost, topMost),
          LatLng(leftMost, bottomMost),
        );
        _doFitMapBounds(bounds);
      });
    }
  }

  void _doFitMapBounds(LatLngBounds bounds) {
    mapController
      ..fitBounds(bounds, options: const FitBoundsOptions(padding: EdgeInsets.all(20.0)))
      ..move(mapController.center, mapController.zoom + 0.00001);

    Provider.of<ModelMapData>(context, listen: false).settings.putSetting("lastMapCenter",
        <String, double>{"latitude": mapController.center.latitude, "longitude": mapController.center.longitude});
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  Widget _getClusterLayer(BuildContext context, ModelMapData value) {
    if (value.mapDataLoadingState == LoadingState.loaded) {
      _popupController.hideAllPopups();
      List<LRMarker> markers = _getMapMarkers(value);

      _initialMapBounds(value.mapList); //show all map items

      return SuperclusterLayer.immutable(
          initialMarkers: markers, // Provide your own
          indexBuilder: IndexBuilders.computeWithOriginalMarkers,
          //controller: SuperclusterImmutableController(),
          controller: _immutableController,
          calculateAggregatedClusterData: true,
          clusterWidgetSize: const Size(20, 20),
          anchor: AnchorPos.align(AnchorAlign.center),
          popupOptions: PopupOptions(
            // popupController: _popupController,
            selectedMarkerBuilder: (context, marker) => const Icon(
              Icons.directions_bike,
              size: 24,
              color: Color.fromARGB(255, 243, 33, 33),
            ),

            popupDisplayOptions: PopupDisplayOptions(
              builder: (BuildContext context, Marker marker) => MarkerPopup(marker as LRMarker, _popupController),
              snap: PopupSnap.markerTop,
              // animation: const PopupAnimation.fade(
              //     duration: Duration(seconds: 1), curve: Curves.fastLinearToSlowEaseIn),
            ),
          ),
          builder: (context, position, markerCount, extraClusterData) {
            return Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.blue),
              child: Center(
                child: Text(
                  markerCount.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          });
    } else if (value.mapDataLoadingState == LoadingState.failed) {
      return Center(
          child: Container(
        // color: Color.fromARGB(214, 218, 63, 16),
        decoration: BoxDecoration(
            color: const Color.fromARGB(214, 218, 63, 16),
            border: Border.all(
              color: const Color.fromARGB(214, 218, 63, 16),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(30))),
        padding: const EdgeInsets.all(5.0),
        // ignore: unnecessary_string_interpolations
        child: Text("${value.mapDataErrMsg}"),
      ));
    } else if (value.mapDataLoadingState == LoadingState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // By default, show a loading spinner.
    return const SizedBox.shrink();
  }

  List<LRMarker> _getMapMarkers(ModelMapData modelMap) {
    Map<dynamic, dynamic> filters = modelMap.filters;

    if (filters.isEmpty) {
      List<LRMarker> markers = modelMap.mapList.mapLocations.entries
          .map(
            (e) => LRMarker(
              locationId: e.key,
              // anchorPos: AnchorPos.align(AnchorAlign.center),
              point: LatLng(e.value.lat, e.value.lon),
              width: 24.0,
              height: 24.0,
              builder: (context) => Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: const Color.fromRGBO(32, 70, 130, 1),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: Icon(Icons.pedal_bike_outlined,
                    size: 16,
                    // color: Colors.blue,
                    color: Colors.white.withOpacity(0.75)),
              ),
            ),
          )
          .toList();
      return markers;
    }

    List<LRMarker> markers = <LRMarker>[];
    for (MapEntry<String, MapLocation> e
        in Provider.of<ModelMapData>(context, listen: false).mapList.mapLocations.entries) {
      if (e.value.idxItems.isNotEmpty &&
          e.value.idxItems.values.first.terms != null &&
          filters.keys.every((element) => e.value.idxItems.values.first.terms!.contains(element))) {
        markers.add(
          LRMarker(
            locationId: e.key,
            // anchorPos: AnchorPos.align(AnchorAlign.center),
            point: LatLng(e.value.lat, e.value.lon),
            width: 24.0,
            height: 24.0,
            builder: (context) => const Icon(
              Icons.directions_bike,
              size: 24,
              color: Colors.red,
            ),
          ),
        );
      }
    }
    return markers;
  }

  void filterMap(ModelMapData modelMap) {
    List<LRMarker> markers = _getMapMarkers(modelMap);
    _immutableController.replaceAll(markers);
    return;
  }

  @override
  // ignore: must_call_super
  void dispose() {
    ModelMapData().realDispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Provider.of<ModelMapData>(context, listen: false).addListener(() {
      if (Provider.of<ModelMapData>(context, listen: false).needsLogin) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showLoginPopup(context);
        });
      }
      if (Provider.of<ModelMapData>(context, listen: false).doCacheLoading &&
          !Provider.of<ModelMapData>(context, listen: false).isCache) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<ModelMapData>(context, listen: false).cacheLocationItemImages(context);
        });
      }
      if (Provider.of<ModelMapData>(context, listen: false).registerNewHost) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showRegisterHost(context);
        });
      }
      if (Provider.of<ModelMapData>(context, listen: false).filtersChanged) {
        filterMap(Provider.of<ModelMapData>(context, listen: false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      CBApp.currentPlattform = "TargetPlatform.web";
      // CBApp.currentPlattform = "TargetPlatform.noweb";
    } else {
      CBApp.currentPlattform = Theme.of(context).platform.toString();
    }
    // print(CBApp.currentPlattform);
    return Scaffold(
      key: CBApp.cbAppKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(35.0),
        child: _responsiveAppBar(),
      ),
      drawer: PageStorage(
        bucket: pageBucket,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 30,
          ),
          child: Drawer(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            backgroundColor: Theme.of(context).cardColor.withOpacity(0.95),
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: DrawerHeader(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                context.l10n.menu,
                                overflow: TextOverflow.fade,
                                softWrap: true,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.0,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                CBApp.cbAppKey.currentState!.closeDrawer();
                              },
                              child: const MouseRegion(
                                cursor: MaterialStateMouseCursor.clickable,
                                child: Icon(
                                  Icons.clear,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ]),
                    ),
                  ),
                  Expanded(
                    child: _drawerMenu(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      endDrawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            topLeft: Radius.circular(20),
          ),
        ),
        backgroundColor: Theme.of(context).cardColor.withOpacity(0.95),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: DrawerHeader(
                  margin: const EdgeInsets.all(10),
                  // padding: const EdgeInsets.all(5),
                  padding: const EdgeInsets.all(0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            CBApp.cbAppKey.currentState!.closeEndDrawer();
                          },
                          child: const MouseRegion(
                            cursor: MaterialStateMouseCursor.clickable,
                            child: Icon(
                              Icons.clear,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            context.l10n.bookItem,
                            overflow: TextOverflow.fade,
                            softWrap: true,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      ]),
                ),
              ),
              const AvailabilitiesCalendar(),
            ],
          ),
        ),
      ),
      body: Consumer<ModelMapData>(builder: (context, value, child) {
        if (value.displayStartup) {
          return Stack(
            children: [
              Center(
                child: AnimatedBackground(
                  width: context.width,
                  height: context.height,
                ),
              ),
              BackdropFilter(
                // filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                filter: ImageFilter.blur(sigmaX: 2.8, sigmaY: 2.8),
                child: Container(
                  padding: const EdgeInsets.only(right: 20, top: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade200.withOpacity(0.2)),
                  child: Align(
                    alignment: Alignment.topRight,
                    child:
                        Text(context.l10n.infoSelectServiceprovider, style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ),
              ),
            ],
          );
        }

        if (value.isMainViewMap == false || value.mapTilesAvailable == LoadingState.failed) {
          return const Center(child: LocationItemsList());
          // return const Expanded(child: LocationItemsList());
        }

        if (value.mapTilesAvailable == LoadingState.loading || value.mapTilesAvailable == LoadingState.unknown) {
          return const Center(child: CircularProgressIndicator());
          // return const Expanded(child: Center(child: CircularProgressIndicator()));
        }

        Map<dynamic, dynamic> lastCenter = Provider.of<ModelMapData>(context, listen: false)
            .settings
            .getSetting("lastMapCenter", {'latitude': 0.0, 'longitude': 0.0});

        LatLng lastMapCenter = LatLng(lastCenter['latitude'], lastCenter['longitude']);

        return /* Expanded(
          child: */
            PopupScope(
          popupController: _popupController,
          // onPopupEvent: (event, selectedMarkers) => debugPrint(
          //   '$event: selected: $selectedMarkers',
          // ),
          child: Stack(
            children: [
              /* child: */ FlutterMap(
                key: CBApp.flutterMapKey,
                mapController: mapController,
                options: MapOptions(
                  center: lastMapCenter,
                  // onPositionChanged: (position, hasGesture) {
                  //   print(position.bounds);
                  //   print(position.center);
                  //   print(position.zoom);
                  // },
                  // center: const LatLng(48.1363743, 11.5222377),
                  // zoom: 11,
                  // interactiveFlags: ~InteractiveFlag.doubleTapZoom,
                  onTap: (_, __) {
                    _popupController.hideAllPopups();
                  }, // Hide popup when the map is tapped.
                  // onMapEvent: (p0) => print(p0),
                  // onMapReady: () {
                  //   mapController.mapEventStream.listen((evt) {
                  //     print(evt);
                  //   });
                  //   // And any other `MapController` dependent non-movement methods
                  // },
                ),
                nonRotatedChildren: [
                  SimpleAttributionWidget(
                    source: const Text('OpenStreetMap contributors'),
                    onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                  ),
                ],
                children: [
                  TileLayer(
                    // key: ValueKey(_tileLayerKey),
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.commonsapi.app',
                    errorTileCallback: (tile, error, stackTrace) {
                      if (value.mapTilesAvailable != LoadingState.failed) {
                        value.mapTilesAvailable = LoadingState.failed;
                        value.onChange();
                      }
                    },
                  ),
                  if (value.currentMapLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: value.currentMapLocation!,
                          width: 40,
                          height: 40,
                          builder: (context) => const Icon(
                            Icons.navigation,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  _getClusterLayer(context, value),
                ],
              ),
              if (value.showZoom)
                Positioned(
                  top: 10,
                  left: 10,
                  child: SizedBox(
                    width: 45,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      // crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            foregroundColor: Colors.black, //   Colors.blue,
                            padding: EdgeInsets.zero, // const EdgeInsets.symmetric(horizontal: 4),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(5.0),
                                topLeft: Radius.circular(5.0),
                              ),
                            ),
                          ),
                          child: const Icon(Icons.add),
                          onPressed: () => mapController.move(mapController.center, mapController.zoom + 1.0),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            foregroundColor: Colors.black, //   Colors.blue,
                            padding: EdgeInsets.zero, // const EdgeInsets.symmetric(horizontal: 4),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(5.0),
                                bottomLeft: Radius.circular(5.0),
                              ),
                            ),
                          ),
                          child: const Icon(Icons.remove),
                          onPressed: () => mapController.move(mapController.center, mapController.zoom - 1.0),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      }),

      floatingActionButton: Consumer<ModelMapData>(
        builder: (context, value, child) {
          return FloatingActionButton(
            onPressed: () => Provider.of<ModelMapData>(context, listen: false).toggleMainView(),
            tooltip: context.l10n.changeViewButtonTooltip(value.isMainViewMap.toString()),
            child: value.isMainViewMap ? const Icon(Icons.view_list_outlined) : const Icon(Icons.map_outlined),
          );
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  LayoutBuilder _responsiveAppBar() {
    return LayoutBuilder(builder: (context, constraints) {
      return Consumer<ModelMapData>(
        builder: (context, map, child) {
          String userName = (map.currentUserMap['name'] == null || map.currentUserMap['name'] == '')
              ? context.l10n.notLoggedIn
              : map.currentUserMap['name'];

          String currentHost = !(map.currentHostMap['title'] ?? '').isEmpty
              ? map.currentHostMap['title']
              : !(map.currentHostMap['domain'] ?? '').isEmpty
                  ? map.currentHostMap['domain']
                  : context.l10n.noService;
          String txtCache = map.isCache ? " (Cache)" : "";
          _connectInfoTooltip = "$currentHost ($userName)$txtCache";
          return AppBar(
            automaticallyImplyLeading: true, // this will hide Drawer hamburger icon
            title: Row(children: [
              Tooltip(
                message: _connectInfoTooltip,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 15,
                  ),
                  child: (map.openHostRunning)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.amber,
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      : SizedBox(
                          width: 28,
                          height: 28,
                          child: (map.isCache)
                              ? Badge(
                                  backgroundColor: Theme.of(context).colorScheme.inverseSurface,
                                  label: Text(DateFormat.yMd(Localizations.localeOf(context).toString())
                                      .add_jms()
                                      .format(map.locationCacheDateTime!)),
                                  child: const Padding(
                                    padding: EdgeInsets.only(top: 3),
                                    child: Icon(
                                      Icons.storage_outlined,
                                      color: Colors.amber,
                                    ),
                                  ),
                                )
                              : Stack(children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: (map.isLoggedIn)
                                        ? const Icon(Icons.person_outline_outlined)
                                        : const Icon(Icons.person_off_outlined),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Icon(Icons.public_outlined,
                                        size: 20,
                                        color: ((map.siteInfoLoadingState == LoadingState.loaded)
                                            ? null //Theme.of(context).primaryColor
                                            : Colors.red)),
                                  ),
                                ]),
                        ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: (map.siteInfo?.name != null &&
                              (map.siteInfoLoadingState == LoadingState.loaded || map.isCache))
                          ? Text(
                              map.siteInfo!.name!,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            )
                          : Text(
                              "${context.l10n.appName} (${context.l10n.noService})",
                              textAlign: TextAlign.center,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: (map.siteInfo != null &&
                              map.siteInfoLoadingState == LoadingState.loaded &&
                              !map.isCache &&
                              map.siteInfo?.siteIconMedia?.sourceUrl != null)
                          ? FastCachedImage(
                              url: WpApi.getSiteIconForPlatform(map.siteInfo!.siteIconMedia!.sourceUrl!),
                              fit: BoxFit.contain,
                              width: 28,
                              height: 28,
                              fadeInDuration: const Duration(milliseconds: 200),
                              errorBuilder: (context, exception, stacktrace) {
                                return const SizedBox.shrink();
                              },
                              loadingBuilder: (context, progress) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.indigoAccent,
                                  ),
                                );
                              },
                            )
                          : Tooltip(
                              message: (map.siteInfoLoadingState == LoadingState.failed)
                                  ? map.siteInfoErrMsg
                                  : context.l10n.noService,
                              child: const Icon(
                                Icons.cloud_off_outlined,
                                size: 28,
                                color: Colors.red,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ]),
            actions: (constraints.maxWidth < 600)
                ? [
                    Container(), //hide endDrawer Hamburger Button
                  ]
                : [
                    MenuAnchor(
                        menuChildren: _hostMenuItemsAppBar(map),
                        builder: (context, controller, child) {
                          return SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              tooltip: _connectInfoTooltip,
                              padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 0),
                              // iconSize: 28,
                              icon: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: (map.isLoggedIn)
                                        ? const Icon(Icons.person_outline_outlined)
                                        : const Icon(Icons.person_off_outlined),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Icon(
                                      Icons.public_outlined,
                                      size: 20,
                                      color: map.isCache
                                          ? Colors.amber
                                          : ((map.siteInfoLoadingState == LoadingState.loaded)
                                              ? null //Theme.of(context).primaryColor
                                              : Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: () {
                                if (controller.isOpen) {
                                  controller.close();
                                } else {
                                  controller.open();
                                }
                              },
                            ),
                          );
                        }),
                    Padding(
                      padding: const EdgeInsets.only(left: 7, right: 0, top: 4, bottom: 4),
                      child: Container(
                        width: 2,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    if (map.isLoggedIn || map.hasBookingCache)
                      IconButton(
                        icon: const Icon(Icons.calendar_month_outlined),
                        tooltip: context.l10n.showBookingsList,
                        onPressed: () => _appBarAction("bookingsList"),
                      ),
                    MenuAnchor(
                      menuChildren: _filterMenuItems(map),
                      builder: ((context, controller, child) {
                        return IconButton(
                          tooltip: "Filter",
                          icon:
                              Icon(Icons.filter_alt_outlined, color: (map.filters.isEmpty) ? Colors.white : Colors.red),
                          onPressed: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                        );
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: context.l10n.reloadLocations,
                      onPressed: () => _appBarAction("reloadMap"),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      child: Container(
                        width: 2,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    if (map.isMainViewMap)
                      IconButton(
                        icon: const Icon(Icons.adjust_outlined),
                        tooltip: context.l10n.resetMapView,
                        onPressed: () => _appBarAction("fitMap"),
                      ),
                    if (map.isMainViewMap &&
                        map.locationServiceEnabled &&
                        (map.locationPermission == LocationPermission.whileInUse ||
                            map.locationPermission == LocationPermission.always))
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        tooltip: context.l10n.gotoCurrentLocation,
                        onPressed: () => _appBarAction("gotoLocation"),
                      ),
                    if (map.isMainViewMap)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                        child: Container(
                          width: 2,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: context.l10n.settings,
                      onPressed: () => _appBarAction("settingsPage"),
                    ),
                  ],
          );
        },
      );
      //   },
      // );
    });
  }

  void _closeMenuDrawer() {
    CBApp.cbAppKey.currentState!.closeDrawer();
  }

  Widget _drawerMenu(BuildContext context) {
    return Consumer<ModelMapData>(builder: (context, map, child) {
      return SingleChildScrollView(
        child: Column(
          children: [
            ExpansionTile(
              key: const PageStorageKey<String>('hostsExpansionTile'),
              shape: Border.all(style: BorderStyle.none),
              title: Tooltip(
                message: _connectInfoTooltip,
                child: Text(context.l10n.service),
              ),
              initiallyExpanded: true,
              leading: Stack(children: [
                (map.isLoggedIn)
                    ? const Icon(
                        Icons.person_outline_outlined,
                      )
                    : const Icon(Icons.person_off_outlined),
                IconButton(
                  tooltip: _connectInfoTooltip,
                  icon: Icon(
                    Icons.public_outlined,
                    color: map.isCache
                        ? Colors.amber
                        : ((map.siteInfoLoadingState == LoadingState.loaded)
                            ? null //Theme.of(context).primaryColor
                            : Theme.of(context).colorScheme.error),
                  ),
                  onPressed: () {},
                ),
              ]),
              childrenPadding: const EdgeInsets.only(left: 15), //children padding
              children: _hostMenuItemsDrawer(map),
            ),
            const Divider(
              indent: 20,
            ),
            if (map.isLoggedIn || map.hasBookingCache)
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(context.l10n.showBookingsList),
                onTap: () {
                  _appBarAction("bookingsList");
                },
              ),
            ExpansionTile(
              key: const PageStorageKey<String>('filtersExpansionTile'),
              title: Tooltip(
                message: context.l10n.tooltipFilter,
                child: Text(context.l10n.filter),
              ),
              initiallyExpanded: false,
              leading: Icon(Icons.filter_alt_outlined, color: (map.filters.isEmpty) ? null : Colors.red),
              childrenPadding: const EdgeInsets.only(left: 30), //children padding
              children: _filterMenuItems(map),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(context.l10n.reloadLocations),
              onTap: () {
                _closeMenuDrawer();
                _appBarAction("reloadMap");
              },
            ),
            const Divider(
              indent: 20,
            ),
            if (map.isMainViewMap)
              ListTile(
                leading: const Icon(Icons.adjust_outlined),
                title: Text(context.l10n.resetMapView),
                onTap: () {
                  _closeMenuDrawer();
                  _appBarAction("fitMap");
                },
              ),
            if (map.isMainViewMap &&
                map.locationServiceEnabled &&
                (map.locationPermission == LocationPermission.whileInUse ||
                    map.locationPermission == LocationPermission.always))
              ListTile(
                leading: const Icon(Icons.location_searching_outlined),
                title: Text(context.l10n.gotoCurrentLocation),
                onTap: () {
                  _closeMenuDrawer();
                  _appBarAction("gotoLocation");
                },
              ),
            if (map.isMainViewMap)
              const Divider(
                indent: 20,
              ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(context.l10n.settings),
              onTap: () {
                _closeMenuDrawer();
                _appBarAction("settingsPage");
              },
            ),
          ],
        ),
      );
    });
    // });
  }

  void _showRegisterHost(BuildContext context) {
    showDialog(
      context: context, // navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: context.dlgPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: RegisterHost(),
        );
      },
    ).then((value) {
      if (value != null) {
        Provider.of<ModelMapData>(context, listen: false).addHost(value);
      }
    });
  }

  void _registerHost() {
    showDialog<Map<String, String>>(
      context: context, // navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: context.dlgPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: RegisterHost(
            initialTab: ActiveTab.hostTab,
          ),
        );
      },
    ).then((result) {
      if (result != null && result['newHostKey'] != null) {
        if (result['newUserKey'] != null) {
          if (Provider.of<ModelMapData>(context, listen: false)
              .hasAppPassword(result['newHostKey']!, result['newUserKey']!)) {
            yesNoDialog(context, context.l10n.logIn, context.l10n.loginWithNewAccount).then((value) {
              if (value) {
                _popupController.hideAllPopups();
                _closeMenuDrawer();
                Provider.of<ModelMapData>(context, listen: false).openHost(result['newHostKey']!, result['newUserKey']);
              } else {
                Provider.of<ModelMapData>(context, listen: false).onChange();
              }
            });
          } else {
            Provider.of<ModelMapData>(context, listen: false).onChange();
          }
        } else {
          yesNoDialog(context, context.l10n.serviceprovider, context.l10n.useNewServiceQuestion).then((value) {
            if (value) {
              _popupController.hideAllPopups();
              _closeMenuDrawer();
              Provider.of<ModelMapData>(context, listen: false).openHost(result['newHostKey']!, "");
            } else {
              Provider.of<ModelMapData>(context, listen: false).onChange();
            }
          });
        }
      }
    });
  }

  void _registerAccount(String hostKey) {
    showDialog<Map<String, String>>(
      context: context, // navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: context.dlgPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: RegisterHost(
            initialTab: ActiveTab.loginTab,
            params: {
              "loginTitle": context.l10n.titleCreateAccount,
              "currentHostKey": hostKey,
            },
          ),
        );
      },
    ).then((result) {
      if (result != null && result['newUserKey'] != null) {
        if (Provider.of<ModelMapData>(context, listen: false).hasAppPassword(hostKey, result['newUserKey']!)) {
          yesNoDialog(context, context.l10n.logIn, context.l10n.loginWithNewAccount).then((value) {
            // yesNoDialog(context, "Anmelden", "Wollen sie sich mit dem neuen Account jetzt anmelden?").then((value) {
            if (value) {
              _popupController.hideAllPopups();
              _closeMenuDrawer();
              Provider.of<ModelMapData>(context, listen: false).openHost(hostKey, result['newUserKey']);
            } else {
              Provider.of<ModelMapData>(context, listen: false).onChange();
            }
          });
        } else {
          Provider.of<ModelMapData>(context, listen: false).onChange();
        }
      }
    });
  }

  Future<bool> _requestAuthData(String hostKey, String userKey) async {
    Map<String, String>? result = await showDialog<Map<String, String>>(
      context: context, // navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: context.dlgPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: RegisterHost(
            initialTab: ActiveTab.loginTab,
            params: {
              "userAuthTitle": context.l10n.logIn,
              "authSaveLabel": context.l10n.logIn,
              'formTask': "login",
              "currentHostKey": hostKey,
              "currentUserKey": userKey
            },
          ),
        );
      },
    );
    return (result != null && result['appPasswordSaved'] == "true");
  }

  void _showLoginPopup(BuildContext context) {
    showDialog(
      context: context, // navigatorKey.currentContext!,
      builder: (BuildContext context) {
        ModelMapData ctrl = Provider.of<ModelMapData>(context, listen: false);
        TextEditingController ctrlUserName = TextEditingController(); //..text = ctrl.currentUser['login'];
        TextEditingController ctrlPassword = TextEditingController();

        // ignore: no_leading_underscores_for_local_identifiers
        void _submitForm() {
          ctrl
              .requestAppPassword(ctrlUserName.text, ctrlPassword.text)
              .then((value) => Navigator.pop(context, true))
              .onError((error, stackTrace) =>
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))));
        }

        return Dialog(
          insetPadding: context.dlgPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Anmelden',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  onFieldSubmitted: (_) {
                    _submitForm(); // Diese Funktion wird aufgerufen, wenn Enter gedrückt wird.
                  },
                  controller: ctrlUserName,
                  // initialValue: ctrl.currentUser['login'],
                  decoration: const InputDecoration(
                    labelText: 'Benutzername',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 10.0),
                TextFormField(
                  onFieldSubmitted: (_) {
                    _submitForm(); // Diese Funktion wird aufgerufen, wenn Enter gedrückt wird.
                  },
                  controller: ctrlPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Passwort',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () => _submitForm(),
                  child: Text(context.l10n.logIn),
                ),
              ],
            ),
          ),
        );
      },
    ).then((value) {
      if (value == null) {
        Provider.of<ModelMapData>(context, listen: false).loadLocationsCBAPI();
      }
    });
  }

  List<Widget> _filterMenuItems(ModelMapData map) {
    List<Widget> filters = <Widget>[];

    if (map.mapList.mapSettings?.filterCbItemCategories?.values != null) {
      for (FilterCbItemCategorie f in map.mapList.mapSettings!.filterCbItemCategories!.values) {
        if (f.elements != null) {
          for (FilterCbItemCategorieElement el in f.elements!) {
            if (el.markup != null) {
              filters.add(
                CheckboxMenuButton(
                  closeOnActivate: false,
                  onChanged: (bool? value) {
                    map.toggleFilter(el.catId);
                  },
                  value: map.filters.containsKey(el.catId),
                  // onPressed: () {
                  //   map.toggleFilter(el.catId);
                  // },
                  // leadingIcon: map.filters.containsKey(el.catId)
                  //     ? const Icon(
                  //         Icons.check_outlined,
                  //         color: Colors.lightGreen,
                  //       )
                  //     : const Icon(null),
                  child: Text(el.markup!),
                ),
              );
            }
          }
        }
      }
    }

    return filters;
  }

  List<Widget> _hostMenuItemsAppBar(ModelMapData map) {
    Map<dynamic, dynamic> registeredHosts = map.settings.hostList;

    if (map.settings.hostList.isEmpty) {
      return [
        const Divider(
          height: 1,
        ),
        MenuItemButton(
          leadingIcon: const Icon(size: 14, Icons.library_add_outlined),
          // leadingIcon: const Icon(null),
          onPressed: () => _registerHost(), // Provider.of<ModelMapData>(context, listen: false).fireRegisterNewHost(),
          child: Text(
            context.l10n.addService,
            style: const TextStyle(
                fontStyle: FontStyle.italic, decoration: TextDecoration.underline, color: Colors.blueGrey),
          ),
        ),
      ];
    }

    // MapEntry<dynamic, dynamic> getUser(Map<dynamic, dynamic> users, int idx) {
    //   return users.entries.elementAt(idx);
    // }

    return registeredHosts.entries
        .map<Widget>(
          (e) => SubmenuButton(
            menuChildren: e.value['users'].entries
                .map<Widget>(
                  (MapEntry<dynamic, dynamic> entry) => MenuItemButton(
                    leadingIcon: (e.key == map.currentHost && entry.key == map.currentUser)
                        ? Icon(
                            Icons.check_outlined,
                            color: map.isCache ? Colors.amber : Colors.lightGreen,
                          )
                        : const Icon(null),
                    child: Text(
                      "${entry.value['name']}",
                    ),
                    onPressed: () {
                      if (!Provider.of<ModelMapData>(context, listen: false).hasAppPassword(e.key, entry.key)) {
                        _requestAuthData(e.key, entry.key).then((value) {
                          if (value) {
                            _popupController.hideAllPopups();
                            _closeMenuDrawer();
                            Provider.of<ModelMapData>(context, listen: false).openHost(e.key, entry.key);
                          } else {
                            showModalBottomMsg(context, context.l10n.errLoginFailed, true);
                          }
                        });
                      } else {
                        _popupController.hideAllPopups();
                        _closeMenuDrawer();
                        Provider.of<ModelMapData>(context, listen: false).openHost(e.key, entry.key);
                      }
                    },
                  ),
                )
                .toList()
              ..addAll([
                const Divider(
                  height: 1,
                ),
                MenuItemButton(
                  leadingIcon: const Icon(size: 14, Icons.person_add_alt_outlined),
                  // leadingIcon: const Icon(null),
                  onPressed: () => _registerAccount(e.key),
                  child: Text(
                    context.l10n.addAccount,
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, decoration: TextDecoration.underline, color: Colors.blueGrey),
                  ),
                ),
              ]),
            leadingIcon: (e.key == map.currentHost)
                ? Icon(
                    Icons.cloud_done_outlined,
                    color: map.isCache
                        ? Colors.amber
                        : (map.siteInfoLoadingState == LoadingState.loaded)
                            ? Colors.lightGreen
                            : Colors.red,
                  )
                : GestureDetector(
                    onTap: () {
                      _popupController.hideAllPopups();
                      Provider.of<ModelMapData>(context, listen: false).openHost(e.key).onError((error, stackTrace) =>
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))));
                    },
                    child: const Icon(Icons.cloud_off_outlined)), // Icon(Icons.cloud_off_outlined),
            child: Text((e.value['title']?.isEmpty ?? true) ? e.value['domain'] : e.value['title']),
          ),
          // }
        )
        .toList()
      ..addAll([
        const Divider(
          height: 1,
        ),
        MenuItemButton(
          leadingIcon: const Icon(size: 14, Icons.library_add_outlined),
          onPressed: () => _registerHost(),
          child: Text(
            context.l10n.addService,
            style: const TextStyle(
                fontStyle: FontStyle.italic, decoration: TextDecoration.underline, color: Colors.blueGrey),
          ),
        ),
      ]);
  }

  List<Widget> _hostMenuItemsDrawer(ModelMapData map) {
    Map<dynamic, dynamic> registeredHosts = map.settings.hostList;

    if (map.settings.hostList.isEmpty) {
      return [
        // const Divider(
        //   height: 1,
        // ),
        ListTile(
          leading: const Icon(size: 14, Icons.library_add_outlined),
          // leadingIcon: const Icon(null),
          onTap: () => _registerHost(), //Provider.of<ModelMapData>(context, listen: false).fireRegisterNewHost(),
          title: Text(
            context.l10n.addService,
            style: const TextStyle(
                fontStyle: FontStyle.italic, decoration: TextDecoration.underline, color: Colors.blueGrey),
          ),
        ),
      ];
    }
    return registeredHosts.entries
        .map<Widget>(
          (e) => ExpansionTile(
            shape: const Border(bottom: BorderSide(style: BorderStyle.none)),
            childrenPadding: const EdgeInsets.only(left: 15), //children padding
            initiallyExpanded: (e.key == map.currentHost && map.currentUser.isNotEmpty),
            children: e.value['users'].entries
                .map<Widget>(
                  (MapEntry<dynamic, dynamic> entry) => ListTile(
                      leading: (e.key == map.currentHost && entry.key == map.currentUser)
                          ? Icon(
                              Icons.check_outlined,
                              color: map.isCache ? Colors.amber : Colors.lightGreen,
                            )
                          : const Icon(null),
                      title: Text(
                        "${entry.value['name']}",
                      ),
                      onTap: () {
                        if (!Provider.of<ModelMapData>(context, listen: false).hasAppPassword(e.key, entry.key)) {
                          _requestAuthData(e.key, entry.key).then((value) {
                            if (value) {
                              _popupController.hideAllPopups();
                              _closeMenuDrawer();
                              Provider.of<ModelMapData>(context, listen: false).openHost(e.key, entry.key);
                            } else {
                              showModalBottomMsg(context, context.l10n.errLoginFailed, true);
                            }
                          });
                        } else {
                          _popupController.hideAllPopups();
                          _closeMenuDrawer();
                          Provider.of<ModelMapData>(context, listen: false).openHost(e.key, entry.key);
                        }
                      }),
                )
                .toList()
              ..addAll([
                // const Divider(
                //   height: 1,
                // ),
                ListTile(
                  leading: const Icon(size: 14, Icons.person_add_alt_outlined),
                  // leadingIcon: const Icon(null),
                  onTap: () => _registerAccount(e.key),
                  title: Text(
                    context.l10n.addAccount,
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, decoration: TextDecoration.underline, color: Colors.blueGrey),
                  ),
                ),
              ]),
            leading: GestureDetector(
              onTap: () {
                _popupController.hideAllPopups();
                _closeMenuDrawer();
                Provider.of<ModelMapData>(context, listen: false).openHost(e.key).onError((error, stackTrace) =>
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))));
              },
              child: (e.key == map.currentHost)
                  ? Icon(
                      Icons.cloud_done_outlined,
                      color: map.isCache
                          ? Colors.amber
                          : ((map.siteInfoLoadingState == LoadingState.loaded) ? Colors.lightGreen : Colors.red),
                    )
                  : const Icon(Icons.cloud_off_outlined),
            ),
            title: Text((e.value['title']?.isEmpty ?? true) ? e.value['domain'] : e.value['title']),
          ),
          // }
        )
        .toList()
      ..addAll([
        // const Divider(
        //   height: 1,
        // ),
        ListTile(
          leading: const Icon(size: 14, Icons.library_add_outlined),
          onTap: () => _registerHost(),
          title: Text(
            context.l10n.addService,
            style: const TextStyle(
                fontStyle: FontStyle.italic, decoration: TextDecoration.underline, color: Colors.blueGrey),
          ),
        ),
      ]);
  }

  void _appBarAction(String action) {
    switch (action) {
      case "fitMap":
        _immutableController.all().then((markers) {
          _doFitMapBounds(_getMaxBounds(markers));
        });
        break;

      case "reloadMap":
        Provider.of<ModelMapData>(context, listen: false)
            .loadLocations(fromCache: Provider.of<ModelMapData>(context, listen: false).isCache)
            .onError((error, stackTrace) => showModalBottomMsg(context, "Error reloading Map $error", true));
        break;

      case "gotoLocation":
        _determinePosition().then((position) {
          Provider.of<ModelMapData>(context, listen: false).currentMapLocation =
              LatLng(position.latitude, position.longitude);
          mapController.move(Provider.of<ModelMapData>(context, listen: false).currentMapLocation!, mapController.zoom);
        });
        break;

      case "bookingsList":
        Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => const BookingsPage(),
              settings: const RouteSettings(name: "/bookings"),
            ));
        break;

      case "settingsPage":
        Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => const SettingsPage(),
              settings: const RouteSettings(name: "/settings"),
            ));
        break;

      default:
        break;
    }
  }
}
