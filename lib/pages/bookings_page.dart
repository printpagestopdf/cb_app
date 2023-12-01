import 'dart:developer';
// import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:cb_app/wp/wp_api.dart';
import 'package:cb_app/wp/cb_bookings_data.dart';
import 'package:cb_app/forms/location_info_dialog.dart';
import 'package:cb_app/parts/utils.dart';
import 'package:cb_app/wp/cb_map_model.dart';
import 'package:cb_app/wp/cb_map_list.dart';
import 'package:provider/provider.dart';
import 'package:cb_app/forms/background_animation.dart';
import 'dart:async';
import 'dart:ui';

// import 'package:html/dom.dart' as dom;
// import 'package:html/dom_parsing.dart' as dom_parser;
// import 'package:html/html_escape.dart';
// import 'package:html/parser.dart' as html_parser;

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPage();
}

class _BookingsPage extends State<BookingsPage> {
  late Future<BookingResult> futureBookings;
  late ModelMapData modelMap;
  final List<TapGestureRecognizer> _tapGestureRecognizers = List<TapGestureRecognizer>.empty(growable: true);
  bool isBookUpdating = false;
  Map<String, dynamic> args = {};

  @override
  void initState() {
    super.initState();
    modelMap = Provider.of<ModelMapData>(context, listen: false);
    if (modelMap.isCache && modelMap.hasBookingCache) {
      args = {"fromCache": true};
    }

    futureBookings = WpApi.getBookings(args);
  }

  @override
  void dispose() {
    for (TapGestureRecognizer t in _tapGestureRecognizers) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String titleCache = (modelMap.isCache && modelMap.hasBookingCache)
        ? AppLocalizations.of(context)!.lastUpdated(DateFormat.yMd(Localizations.localeOf(context).toString())
            .add_jms()
            .format(modelMap.locationCacheDateTime!))
        : "";
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.yourBookings),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.l10n.reload,
            onPressed: () {
              setState(() {
                futureBookings = WpApi.getBookings(args);
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<BookingResult>(
        future: futureBookings,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1000,
                  minWidth: 320,
                ),
                child: ((snapshot.data?.bookingsData?.data?.length ?? 0) > 0)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (modelMap.isCache && modelMap.hasBookingCache) Text(titleCache),
                          Expanded(
                              child: ListView.builder(
                            itemCount: snapshot.data?.bookingsData?.data?.length,
                            itemBuilder: (BuildContext context, int index) {
                              return _getListTile(context, snapshot.data?.bookingsData?.data?[index]);
                            },
                          ))
                        ],
                      )
                    : Stack(
                        children: [
                          Center(
                            child: AnimatedBackground(
                              width: context.width,
                              height: context.height,
                            ),
                          ),
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                            // filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              padding: const EdgeInsets.only(right: 20, top: 20),
                              decoration: BoxDecoration(color: Colors.grey.shade200.withOpacity(0.2)),
                            ),
                          ),
                          Center(
                            child: Container(
                              // color: Color.fromARGB(214, 218, 63, 16),
                              decoration: BoxDecoration(
                                  color: const Color.fromARGB(214, 218, 63, 16),
                                  border: Border.all(
                                    color: const Color.fromARGB(214, 218, 63, 16),
                                  ),
                                  borderRadius: const BorderRadius.all(Radius.circular(30))),
                              padding: const EdgeInsets.all(5.0),
                              child: Text(context.l10n.emptyBookingList),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          } else if (snapshot.hasError) {
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
              child: Text('${snapshot.error}'),
            ));
          }

          // By default, show a loading spinner.
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget? _getListTile(BuildContext context, BookingsItemData? booking) {
    if (booking == null) return null;

    return Card(
      color: Theme.of(context).cardTheme.color,
      elevation: 10,
      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            children: _cardItems(context, booking, true),
          );
        } else {
          return Column(
            children: _cardItems(context, booking, false),
          );
        }
      }),
    );
  }

  List<Widget> _cardItems(BuildContext context, BookingsItemData booking, bool isHorizontal) {
    late final String btnText;
    late final MaterialColor btnColor;
    late final bool btnVisibility;
    late final String newStatus;

    switch (booking.content?.status?.value) {
      case "confirmed":
        newStatus = "canceled";
        btnText = context.l10n.bookingCancelButton((isHorizontal).toString());
        btnColor = CustomMaterialColor(202, 66, 211).mdColor;
        btnVisibility = true;
        break;
      case "unconfirmed":
        newStatus = "confirmed";
        btnText = context.l10n.bookingConfirmButton((isHorizontal).toString());
        btnColor = CustomMaterialColor(11, 83, 143).mdColor;
        btnVisibility = true;
        break;

      default:
        newStatus = "canceled";
        btnText = "Buchung\nuncancelled";
        btnColor = CustomMaterialColor(11, 83, 143).mdColor;
        btnVisibility = false;
        break;
    }

    LocationItem? locationItem;
    if (booking.locationId != null && booking.itemId != null) {
      MapLocation? location =
          Provider.of<ModelMapData>(context, listen: false).mapList.mapLocations[booking.locationId.toString()];
      if (location != null) {
        locationItem = location.idxItems[booking.itemId.toString()];
      }
    }

    return [
      Padding(
        padding: const EdgeInsets.all(15.0),
        child: InkWell(
          onTap: (locationItem != null)
              ? () => LocationInfoDialog.locationItem(context, locationItem!, isHorizontal)
              : null,
          child: SizedBox(
            width: 75.0,
            height: 75,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: FastCachedImage(
                width: 75.0,
                height: 75.0,
                filterQuality: FilterQuality.medium,
                url: WpApi.getBookingItemThumbnailUrl(booking),
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                errorBuilder: (context, exception, stacktrace) {
                  return Tooltip(
                    message: context.l10n.imageDisplayNotPossible,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1)),
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  );
                },
                loadingBuilder: (context, progress) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.indigoAccent,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      isHorizontal
          ? Expanded(
              child: _bookingInfo(context, booking, isHorizontal),
            )
          : _bookingInfo(context, booking, isHorizontal),
      Visibility(
        visible: btnVisibility,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: Container(
          alignment: AlignmentDirectional.centerEnd,
          margin: const EdgeInsets.all(15),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                isBookUpdating = true;
              });
              WpApi.bookingUpdate(
                bookingID: booking.bookingId.toString(),
                itemId: booking.itemId.toString(), // map.currentItem!.id.toString(),
                locationId: booking.locationId.toString(), //  map.currentLocation!.id,
                repetitionStart: DateTime.fromMillisecondsSinceEpoch(int.parse(booking.startDate!) * 1000,
                    isUtc: true), // bookingDates["rangeMinDate"],
                repetitionEnd: DateTime.fromMillisecondsSinceEpoch(int.parse(booking.endDate!) * 1000,
                    isUtc: true), // bookingDates["rangeMaxDate"],
                postStatus: newStatus,
              ).then((value) {
                if (value.isError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("${value.msg} (${value.statusCode.toString()})"),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ));
                  setState(() {
                    isBookUpdating = false;
                  });
                } else {
                  setState(() {
                    isBookUpdating = false;
                    futureBookings = WpApi.getBookings(args);
                  });
                }
              });
            },
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(btnColor),
                padding: MaterialStateProperty.all(const EdgeInsets.all(12))),
            child: Text(
              btnText,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _bookingInfo(BuildContext context, BookingsItemData booking, bool isHorizontal) {
    if (booking.locationId != null) {
      MapLocation? location =
          Provider.of<ModelMapData>(context, listen: false).mapList.mapLocations[booking.locationId.toString()];
      if (location != null && location.locationDescription != null) {
        booking.locationDescription = location.locationDescription;
        booking.locationDescriptionFormat = location.locationDescriptionFormat;
      }
    }

    Column itemText = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${booking.startDateFormatted!} - ${booking.endDateFormatted!}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Flexible(
                flex: 1,
                child: RichText(
                  text: TextSpan(
                      text: "${booking.item} @ ${booking.location}",
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        if (booking.hasLocationInfo())
                          WidgetSpan(
                            child: IconButton(
                              constraints: const BoxConstraints(maxWidth: 25),
                              padding: const EdgeInsets.only(left: 5),
                              iconSize: 20,
                              alignment: Alignment.centerLeft,
                              tooltip: context.l10n.stationInfo,
                              onPressed: () => LocationInfoDialog(context, booking, true),
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.lightBlue,
                              ),
                            ),
                          ),
                      ]),
                ),
              ),
            ],
          ),
          if (["confirmed", "unconfirmed"].contains(booking.content?.status?.value))
            Text("${booking.bookingCode?.label!}: ${booking.bookingCode?.value!}"),
        ]);

    Column userText = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("${booking.content?.user?.label!}: ${booking.content?.user?.value!}"),
          Text("${booking.content?.status?.label!}: ${booking.content?.status?.value!}"),
        ]);

    return isHorizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: itemText,
                ),
              ),
              const SizedBox(
                height: 50,
                child: VerticalDivider(
                    // width: 10,
                    ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: userText,
                ),
              ),
            ],
          )
        : Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: MediaQuery.of(context).size.width / 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                itemText,
                userText,
              ],
            ),
          );
  }
}
