import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:non_uniform_border/non_uniform_border.dart';
import 'package:expandable/expandable.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cb_app/wp/cb_map_list.dart';
import 'package:provider/provider.dart';
import 'package:cb_app/parts/utils.dart';
import 'package:cb_app/wp/cb_map_model.dart';
import 'package:cb_app/wp/wp_api.dart';
import 'dart:math';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:scrollable_clean_calendar/controllers/clean_calendar_controller.dart';
import 'package:scrollable_clean_calendar/scrollable_clean_calendar.dart';
import 'package:scrollable_clean_calendar/utils/enums.dart';
import 'package:scrollable_clean_calendar/utils/extensions.dart';
import 'package:scrollable_clean_calendar/models/day_values_model.dart';
import 'dart:ui';
import 'dart:async';

class _BookingDates extends ValueNotifier<Map<String, dynamic>> {
  _BookingDates(super.value);

  void reset() {
    value.updateAll((key, value) => value = null);
  }

  operator []=(String i, dynamic val) {
    if (!value.containsKey(i) || value[i] != val) {
      value[i] = val;
      notifyListeners();
    }
  }

  operator [](String key) {
    if (value.containsKey(key)) {
      return value[key];
    } else {
      return null;
    }
  }
}

typedef _DayDispParams = ({
  BoxDecoration decoration,
  bool strikeOverlay,
  bool disallowLockDaysinRange,
});

class AvailabilitiesCalendar extends StatefulWidget {
  const AvailabilitiesCalendar({super.key});

  @override
  State<AvailabilitiesCalendar> createState() => _AvailabilitiesCalendar();
}

class _AvailabilitiesCalendar extends State<AvailabilitiesCalendar> {
  final TextEditingController _commentTextController = TextEditingController();
  final ExpandableController _bookingMsgExpandableController = ExpandableController(initialExpanded: false);
  final _BookingDates _bookingDates = _BookingDates(<String, dynamic>{
    "rangeMinDate": null,
    "rangeMaxDate": null,
  });
  final GlobalKey _textInfoKey = GlobalKey();
  final _dtf = DateFormat("yyyy-MM-dd");
  final _mtf = DateFormat("yyyy-MM");
  final Map<String, dynamic> _calinfo = {
    "validFrom": null,
    "validTo": null,
  };
  // int _maxBookingdays = 3;
  late int _maxBookingdays;
  double _bottomMsgHeight = 0;
  String _bottomMsgTxt = "";
  Color _bottomMsgColor = Colors.white;
  Timer? _bottomMsgTimer;

  static Border dayBorder = Border.all(width: 0.5, color: const Color.fromARGB(255, 0, 0, 0));
  static const Color redColor = Color.fromRGBO(213, 66, 92, 1.0);
  static const Color greenColor = Color.fromRGBO(116, 206, 60, 1.0);
  static const Color grayColor = Color.fromRGBO(221, 221, 221, 1.0);

  static BoxDecoration bookedDecoration = BoxDecoration(
    color: redColor,
    border: dayBorder,
    shape: BoxShape.circle,
    // gradient: const LinearGradient(
    //   transform: GradientRotation(pi / 2),
    //   begin: Alignment.topRight,
    //   end: Alignment.bottomLeft,
    //   stops: [0.0, 0.48, 0.48, 0.52, 0.52, 1.0],
    //   colors: [redColor, redColor, Colors.black, Colors.black, redColor, redColor],
    // ),
  );

  static BoxDecoration outsideDecoration = const BoxDecoration(
      // gradient: LinearGradient(
      //   transform: GradientRotation(pi / 2),
      //   begin: Alignment.topRight,
      //   end: Alignment.bottomLeft,
      //   stops: [0.0, 0.48, 0.48, 0.52, 0.52, 1.0],
      //   // colors: [Colors.white, Colors.white, Colors.black, Colors.black, Colors.white, Colors.white],
      //   colors: [
      //     Colors.transparent,
      //     Colors.transparent,
      //     Colors.black,
      //     Colors.black,
      //     Colors.transparent,
      //     Colors.transparent
      //   ],
      // ),
      );

  static BoxDecoration hollidayDecoration = BoxDecoration(
    border: dayBorder,
    shape: BoxShape.circle,
    gradient: const LinearGradient(
      transform: GradientRotation(-pi / 3),
      begin: Alignment.topLeft,
      end: Alignment(-0.4, -0.8),
      stops: [0.0, 0.30, 0.30, 1],
      colors: [
        redColor,
        redColor,
        Colors.transparent,
        Colors.transparent,
      ],
      tileMode: TileMode.repeated,
    ),
  );

  static BoxDecoration partiallyDecoration = BoxDecoration(
    border: dayBorder,
    shape: BoxShape.circle,
    gradient: const LinearGradient(
      transform: GradientRotation(pi / 2),
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [greenColor, greenColor, redColor, redColor],
      stops: [0, 0.5, 0.5, 1],
    ),
  );

  static BoxDecoration availableDecoration = BoxDecoration(
    border: dayBorder,
    shape: BoxShape.circle,
    color: greenColor,
  );

  static BoxDecoration lockedDecoration = BoxDecoration(
    border: dayBorder,
    shape: BoxShape.circle,
    color: grayColor,
  );

  _AvailabilitiesCalendar();

  void _showBottomMsg(String msg, [bool isError = false]) {
    if (_bottomMsgTimer != null && _bottomMsgTimer!.isActive) {
      _bottomMsgTimer!.cancel();
    }

    _bottomMsgTxt = msg;
    _bottomMsgColor = (isError) ? Colors.red : Colors.white;

    setState(() {
      _bottomMsgHeight = 80;
    });
  }

  void _hideBottomMsg() {
    if (context.mounted && _bottomMsgHeight > 0) {
      setState(() {
        _bottomMsgHeight = 0;
      });
    }
  }

  @override
  void dispose() {
    if (_bottomMsgTimer != null && _bottomMsgTimer!.isActive) {
      _bottomMsgTimer!.cancel();
    }

    // Clean up the controller when the widget is disposed.
    _commentTextController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ModelMapData>(context, listen: false).loadBookingStats();
    });
    _maxBookingdays = Provider.of<ModelMapData>(context, listen: false).currentItem?.maxDays ?? 3;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelMapData>(builder: (context, map, child) {
      return Expanded(
        child: LoaderOverlay(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(key: _textInfoKey, children: [
                    _locationDescription(context, map.currentLocation!),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8,
                            right: 10,
                            top: 5,
                            bottom: 0,
                          ),
                          child: SizedBox(
                            width: 75,
                            height: 75,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: FastCachedImage(
                                height: 75.0,
                                width: 75.0,
                                filterQuality: FilterQuality.medium,
                                url: WpApi.getItemThumbnailUrl(map.currentItem!),
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
                        _cardDescription(context, map),
                      ],
                    ),
                    const Divider(
                      height: 0,
                    ),
                  ]),
                  (map.currentItem!.availability != null &&
                          map.currentItem!.availability!.isNotEmpty &&
                          map.bookingStats != null)
                      ? Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child: Container(
                              // color: Colors.white,
                              child: _bookingCalendar(map),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Wrap(children: [
                            Text(
                              "${context.l10n.availabilities} ...",
                              textAlign: TextAlign.center,
                              style: const TextStyle(),
                            ),
                            if (map.bookingStats == null)
                              Text(
                                "${context.l10n.bookinglimits} ...",
                                textAlign: TextAlign.center,
                                style: const TextStyle(),
                              ),
                            const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                              ),
                            ),
                          ]),
                        ),
                ],
              ),
              AnimatedContainer(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadiusDirectional.only(topStart: Radius.circular(5), topEnd: Radius.circular(5)),
                  color: _bottomMsgColor,
                ),
                height: _bottomMsgHeight,
                duration: Durations.medium4,
                onEnd: () {
                  if (_bottomMsgHeight > 0) {
                    _bottomMsgTimer = Timer(const Duration(seconds: 5), () {
                      _hideBottomMsg();
                    });
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            _bottomMsgTxt,
                            softWrap: true,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _hideBottomMsg();
                      },
                      child: const MouseRegion(
                        cursor: MaterialStateMouseCursor.clickable,
                        child: Padding(
                          padding: EdgeInsets.only(top: 5, right: 5),
                          child: Icon(
                            Icons.clear,
                            size: 15,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
    // });
  }

  Widget _cardDescription(BuildContext context, ModelMapData map) {
    _bookingDates.reset();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          SizedBox(
            width: 200,
            child: Text(
              map.currentItem!.name!,
              // overflow: TextOverflow.fade,
              maxLines: 3,
              softWrap: true,
            ),
          ),
          ValueListenableBuilder(
              valueListenable: _bookingDates,
              builder: (BuildContext context, Map<String, dynamic> bookingDates, Widget? child) {
                if ((bookingDates["rangeMaxDate"] == null || bookingDates["rangeMinDate"] == null) &&
                    _bookingMsgExpandableController.expanded) {
                  _bookingMsgExpandableController.toggle();
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          constraints: const BoxConstraints(minWidth: 35),
                          child: Text(
                            "${context.l10n.from}: ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        bookingDates["rangeMinDate"] == null
                            ? Text(
                                context.l10n.pleaseSelect,
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              )
                            : Text(
                                DateFormat.yMd(Localizations.localeOf(context).toString())
                                    .format(bookingDates["rangeMinDate"]),
                                textAlign: TextAlign.right,
                              ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          constraints: const BoxConstraints(minWidth: 35),
                          child: Text(
                            "${context.l10n.until}: ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        bookingDates["rangeMaxDate"] == null
                            ? Text(
                                context.l10n.pleaseSelect,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Text(
                                DateFormat.yMd(Localizations.localeOf(context).toString())
                                    .format(bookingDates["rangeMaxDate"]),
                                textAlign: TextAlign.right,
                              ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: ExpandablePanel(
                        controller: _bookingMsgExpandableController,
                        collapsed: const SizedBox.shrink(),
                        expanded: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 80,
                              maxWidth: 180,
                            ),
                            child: TextField(
                              controller: _commentTextController,
                              style: const TextStyle(fontSize: 12),
                              keyboardType: TextInputType.multiline,
                              maxLines: 5,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                hintText: context.l10n.addComment,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 0),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: (bookingDates["rangeMaxDate"] == null || bookingDates["rangeMinDate"] == null)
                                ? null
                                : () {
                                    context.loaderOverlay.show();
                                    WpApi.bookingNew(
                                      itemId: map.currentItem!.id.toString(),
                                      locationId: map.currentLocation!.id,
                                      repetitionStart: bookingDates["rangeMinDate"],
                                      repetitionEnd: bookingDates["rangeMaxDate"],
                                      comment: _commentTextController.text,
                                    ).then((value) {
                                      if (value.isError) {
                                        _showBottomMsg("${value.msg} (${value.statusCode.toString()})", true);
                                      } else {
                                        _showBottomMsg(value.msg, false);

                                        DateTime current = bookingDates["rangeMinDate"];
                                        while (current.isSameDayOrBefore(bookingDates["rangeMaxDate"])) {
                                          String fmt = _dtf.format(current);
                                          map.currentItem!.availabilityByDate[fmt] = Status.BOOKED;
                                          current = current.add(const Duration(days: 1));
                                        }
                                        map.onChange();
                                      }
                                    }).whenComplete(() => context.loaderOverlay.hide());
                                  },
                            style: ElevatedButton.styleFrom(
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(5.0),
                                  bottomLeft: Radius.circular(5.0),
                                ),
                              ),
                            ),
                            child: Text(context.l10n.booking),
                          ),
                          Tooltip(
                            message: context.l10n.addComment,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 30),
                              decoration: BoxDecoration(
                                  border: BorderDirectional(start: BorderSide(color: Colors.black.brighten(60)))),
                              child: ElevatedButton(
                                onPressed:
                                    (bookingDates["rangeMaxDate"] == null || bookingDates["rangeMinDate"] == null)
                                        ? null
                                        : () => _bookingMsgExpandableController.toggle(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary.brighten(30), //   Colors.blue,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(5.0),
                                      bottomRight: Radius.circular(5.0),
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_comment_outlined,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
          // const Padding(padding: EdgeInsets.only(bottom: 5.0)),
        ],
      ),
      //),
    );
  }

  Widget _locationDescription(BuildContext context, MapLocation location) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
      ),
      child: SizedBox(
        width: 300,
        // height: 45,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      location.locationName,
                      overflow: TextOverflow.fade,
                      softWrap: true,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ]),
            Wrap(children: [
              Tooltip(
                message: 'Position: ${location.lat}, ${location.lon}',
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.black,
                ),
              ),
              Text(
                "${location.address.street}, ${location.address.zip} ${location.address.city}",
                overflow: TextOverflow.fade,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 12.0,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  DateTime? _lastValidDay(DateTime firstDate, ModelMapData map) {
    if (map.bookingStats?.monthRestrictions?.bookings?.limit != null) {
      if ((map.bookingStats?.monthRestrictions?.bookings?.booked?[_mtf.format(firstDate)] ?? 0) + 1 >
          map.bookingStats!.monthRestrictions!.bookings!.limit!) {
        return null;
      }
    }

    if (map.bookingStats?.weekRestrictions?.bookings?.limit != null) {
      DateTime monday = getStartOfWeek(firstDate);
      if ((map.bookingStats?.weekRestrictions?.bookings?.booked?[_dtf.format(monday)] ?? 0) + 1 >
          map.bookingStats!.weekRestrictions!.bookings!.limit!) {
        return null;
      }
    }

    DateTime validTo = firstDate.add(Duration.zero);
    DateTime? retVal;

    int dayCount = 0;
    int dayCountOfWeek = 0;
    int dayCountOfMonth = 0;
    int countLockDays = 0;
    int countLockDaysMaxDays = map.currentLocation!.countLockDaysMaxDays;

    Loop:
    while (map.currentItem!.availabilityByDate.containsKey(_dtf.format(validTo))) {
      bool countsAsDay = false;
      bool isBookable = false;
      switch (map.currentItem!.availabilityByDate[_dtf.format(validTo)]!) {
        // case Status.HOLIDAY:
        //   // maxBookingdays--;
        //   break;
        case Status.AVAILABLE:
          countsAsDay = true;
          isBookable = true;
          break;
        case Status.HOLIDAY:
        case Status.LOCKED:
          if (map.currentLocation!.disallowLockDaysInRange) {
            break Loop;
          } else if (map.currentLocation!.countLockDaysInRange) {
            if (countLockDaysMaxDays == 0 || countLockDays < countLockDaysMaxDays) {
              countLockDays++;
              countsAsDay = true;
            }
          }
          break;
        default:
          break Loop;
        // continue;
      }
      if (validTo.weekday == 0) dayCountOfWeek = 0;
      if (validTo.day == 1) dayCountOfMonth = 0;
      if (countsAsDay) {
        dayCount++;
        if (dayCount > _maxBookingdays) break Loop;

        if (map.bookingStats?.weekRestrictions?.days?.limit != null) {
          dayCountOfWeek++;
          DateTime monday = getStartOfWeek(firstDate);
          if ((map.bookingStats?.weekRestrictions?.days?.booked?[_dtf.format(monday)] ?? 0) + dayCountOfWeek >
              map.bookingStats!.weekRestrictions!.days!.limit!) {
            break Loop;
          }
        }

        if (map.bookingStats?.monthRestrictions?.days?.limit != null) {
          dayCountOfMonth++;
          if ((map.bookingStats?.monthRestrictions?.days?.booked?[_mtf.format(firstDate)] ?? 0) + dayCountOfMonth >
              map.bookingStats!.monthRestrictions!.days!.limit!) {
            break Loop;
          }
        }
      }

      if (isBookable) {
        retVal = validTo.add(Duration.zero);
      }

      validTo = validTo.add(const Duration(days: 1));
    }
    // return validTo;
    return retVal;
  }

  void _clearSelection(CleanCalendarController? calendarController) {
    _bookingDates["rangeMinDate"] = _bookingDates["rangeMaxDate"] = null;
    _calinfo["validFrom"] = calendarController?.minDate;
    _calinfo["validTo"] = calendarController?.maxDate;
    calendarController?.clearSelectedDates();
  }

  Widget _bookingCalendar(ModelMapData map) {
    CleanCalendarController? calendarController;

    _calinfo["validFrom"] = map.currentItem!.firstAvailability!;
    _calinfo["validTo"] = map.currentItem!.lastAvailability!;

    calendarController = CleanCalendarController(
      minDate: map.currentItem!.firstAvailability!,
      maxDate: map.currentItem!.lastAvailability!,
      readOnly: !map.isLoggedIn,
      initialFocusDate: DateTime.now(),
      onRangeSelected: (firstDate, secondDate) {
        // _clearSelection(calendarController);
        // return;
        if (map.currentItem!.availabilityByDate[_dtf.format(firstDate)]! != Status.AVAILABLE ||
            (secondDate != null && map.currentItem!.availabilityByDate[_dtf.format(secondDate)]! != Status.AVAILABLE)) {
          calendarController?.rangeMinDate = _bookingDates["rangeMinDate"];
          calendarController?.rangeMaxDate = _bookingDates["rangeMaxDate"];
          return;
        }

        if (firstDate.isBefore(_calinfo["validFrom"]) || firstDate.isAfter(_calinfo["validTo"])) {
          _bookingDates["rangeMinDate"] = _calinfo["validFrom"] = calendarController?.rangeMinDate = firstDate;
          _bookingDates["rangeMaxDate"] = calendarController?.rangeMaxDate = null;
          _calinfo["validTo"] = _lastValidDay(firstDate, map);
          if (_calinfo["validTo"] == null) _clearSelection(calendarController);
          if (_calinfo["validTo"] == _bookingDates["rangeMinDate"]) _bookingDates["rangeMaxDate"] = _calinfo["validTo"];
          return;
        }

        if (secondDate != null &&
            (secondDate.isBefore(_calinfo["validFrom"]) || secondDate.isAfter(_calinfo["validTo"]))) {
          _bookingDates["rangeMinDate"] = _calinfo["validFrom"] = calendarController?.rangeMinDate = secondDate;
          _bookingDates["rangeMaxDate"] = calendarController?.rangeMaxDate = null;
          _calinfo["validTo"] = _lastValidDay(secondDate, map);
          if (_calinfo["validTo"] == null) _clearSelection(calendarController);
          if (_calinfo["validTo"] == _bookingDates["rangeMinDate"]) _bookingDates["rangeMaxDate"] = _calinfo["validTo"];
          return;
        }

        _bookingDates["rangeMinDate"] = firstDate;
        if (calendarController!.minDate.isSameDay(_calinfo["validFrom"])) {
          _calinfo["validFrom"] = firstDate;
        }
        // _calinfo["validTo"] = firstDate.add(const Duration(days: 3));
        if (calendarController.maxDate.isSameDay(_calinfo["validTo"])) {
          _calinfo["validTo"] = _lastValidDay(firstDate, map);
          if (_calinfo["validTo"] == null) {
            _clearSelection(calendarController);
            return;
          }
          if (_calinfo["validTo"] == _bookingDates["rangeMinDate"]) {
            _bookingDates["rangeMaxDate"] = _calinfo["validTo"];
            return;
          }
        }

        _bookingDates["rangeMaxDate"] = secondDate;
      },
      weekdayStart: DateTime.monday,
    );

    return GestureDetector(
      onDoubleTap: () => _clearSelection(calendarController),
      child: ScrollableCleanCalendar(
        padding: const EdgeInsets.only(left: 30, right: 30, top: 2),
        calendarController: calendarController,
        layout: Layout.BEAUTY,
        locale: map.currentLocale.languageCode, // "de",
        calendarCrossAxisSpacing: 0,
        // calendarMainAxisSpacing: 0,
        // calendarCrossAxisSpacing: 0,
        calendarMainAxisSpacing: 2,
        dayRadius: 0,
        weekdayTextStyle: const TextStyle(),

        // weekdayBuilder: (BuildContext context, String weekday) => Text(weekday),
        monthBuilder: (BuildContext context, String month) => Row(children: [
          Expanded(
            child: Text(
              month,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () => _clearSelection(calendarController),
            icon: const Icon(Icons.deselect),
            iconSize: 14,
            tooltip: context.l10n.clearDateSelection,
          ),
        ]),
        monthTextAlign: TextAlign.center,
        spaceBetweenMonthAndCalendar: 2,
        spaceBetweenCalendars: 2,
        dayTextStyle: const TextStyle(),
        // padding: EdgeInsets.zero,
        dayBuilder: (BuildContext context, DayValues values) {
          _DayDispParams? dispParms = dayDispParams(values, map);
          if (dispParms == null) {
            // if (!map.currentItem!.availabilityByDate.containsKey(_dtf.format(values.day))) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: [
                  Container(
                    decoration: outsideDecoration,
                    alignment: Alignment.center,
                    child: Text(
                      style: TextStyle(
                          color: Theme.of(context).textTheme.labelMedium?.color?.withOpacity(0.7), fontSize: 12),
                      values.day.day.toString(),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Transform.rotate(
                        angle: -pi / 4,
                        child: Container(
                          height: 1.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // final Status itemStatus = map.currentItem!.availabilityByDate[_dtf.format(values.day)]!;
          final List<double> params = (!values.isSelected &&
                  (values.selectedMaxDate != null || values.selectedMinDate != null) &&
                  ((values.day.isBefore(_calinfo["validFrom"])) || values.day.isAfter(_calinfo["validTo"])))
              ? [9, 0.6]
              : [5, 1];
          return Container(
            foregroundDecoration: (map.bookingStats?.isFullWeekMonthRestriction(values.day) ?? false)
                ? BoxDecoration(color: Colors.black.withOpacity(0.3))
                : null,
            decoration: _validAreaBorder(context, values),
            child: Container(
              decoration: _foregroundDecoration(context, values),
              child: Padding(
                padding: EdgeInsets.all(params[0]),
                child: Stack(
                  children: [
                    Container(
                      decoration: dispParms.decoration,
                      alignment: Alignment.center,
                      child: Text(
                        values.day.day.toString(),
                        textScaler: TextScaler.linear(params[1]),
                        // textScaleFactor: params[1],
                      ),
                    ),
                    if (dispParms.strikeOverlay)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Transform.rotate(
                            angle: -pi / 4,
                            child: Container(
                              height: 1.5,
                              color: dispParms.disallowLockDaysinRange ? Colors.black : Colors.green,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  _DayDispParams? dayDispParams(DayValues values, ModelMapData map) {
    BoxDecoration decoration;
    bool strikeOverlay = false;
    bool disallowLockDaysinRange = false;

    switch (map.currentItem?.availabilityByDate[_dtf.format(values.day)]) {
      case Status.AVAILABLE:
        decoration = availableDecoration;
      case Status.BOOKED:
        strikeOverlay = true;
        disallowLockDaysinRange = true;
        decoration = bookedDecoration;
      case Status.LOCKED:
        if (map.currentLocation!.disallowLockDaysInRange) {
          strikeOverlay = true;
          disallowLockDaysinRange = true;
        } else if (map.currentLocation!.countLockDaysInRange) {
          strikeOverlay = true;
          disallowLockDaysinRange = false;
        }
        decoration = lockedDecoration;
      case Status.HOLIDAY:
        if (map.currentLocation!.disallowLockDaysInRange) {
          strikeOverlay = true;
          disallowLockDaysinRange = true;
        } else if (map.currentLocation!.countLockDaysInRange) {
          strikeOverlay = true;
          disallowLockDaysinRange = false;
        }
        decoration = hollidayDecoration;
      case Status.PARTIALLY_BOOKED:
        decoration = partiallyDecoration;
      default:
        if (values.day.isSameDayOrAfter(map.currentItem!.firstAvailability!) &&
            values.day.isSameDayOrBefore(map.currentItem!.lastAvailability!)) {
          strikeOverlay = true;
          disallowLockDaysinRange = true;
          decoration = bookedDecoration;
        } else {
          return null;
        }
        break;
    }

    return (
      decoration: decoration,
      strikeOverlay: strikeOverlay,
      disallowLockDaysinRange: disallowLockDaysinRange,
    );
  }

  Decoration? _validAreaBorder(BuildContext context, DayValues values) {
    const double bWidth = 2.0;
    const Color bColor = Colors.green;
    const Radius bRadius = Radius.circular(13);
    const double bStrokeAlign = BorderSide.strokeAlignCenter;

    if ((values.selectedMaxDate == null && values.selectedMinDate == null) ||
        (values.day.isBefore(_calinfo["validFrom"])) ||
        values.day.isAfter(_calinfo["validTo"])) return null;

    if (values.day.isSameDay(_calinfo["validFrom"]) && values.day.isSameDay(_calinfo["validTo"])) {
      return const ShapeDecoration(
        shape: NonUniformBorder(
          strokeAlign: bStrokeAlign,
          color: bColor,
          rightWidth: bWidth,
          leftWidth: bWidth,
          topWidth: bWidth,
          bottomWidth: bWidth,
          borderRadius: BorderRadius.all(bRadius),
        ),
      );
    }

    if (values.day.isSameDay(_calinfo["validFrom"])) {
      return const ShapeDecoration(
        shape: NonUniformBorder(
          strokeAlign: bStrokeAlign,
          color: bColor,
          rightWidth: 0,
          leftWidth: bWidth,
          topWidth: bWidth,
          bottomWidth: bWidth,
          borderRadius: BorderRadius.only(
            topLeft: bRadius,
            bottomLeft: bRadius,
          ),
        ),
      );
    } else if (values.day.isSameDay(_calinfo["validTo"])) {
      return const ShapeDecoration(
          shape: NonUniformBorder(
              strokeAlign: bStrokeAlign,
              color: bColor,
              rightWidth: bWidth,
              leftWidth: 0,
              topWidth: bWidth,
              bottomWidth: bWidth,
              borderRadius: BorderRadius.only(
                topRight: bRadius,
                bottomRight: bRadius,
              )));
    }

    return const ShapeDecoration(
      shape: NonUniformBorder(
        strokeAlign: bStrokeAlign,
        color: bColor,
        rightWidth: 0,
        leftWidth: 0,
        topWidth: bWidth,
        bottomWidth: bWidth,
        borderRadius: BorderRadius.zero,
      ),
    );
  }

  // BoxDecoration? _foregroundDecoration(BuildContext context, DayValues values) {
  BoxDecoration? _foregroundDecoration(BuildContext context, DayValues values) {
    Color baseColor = Theme.of(context).colorScheme.tertiary;
    Color bgColor = baseColor.withOpacity(0.5);
    BorderRadiusGeometry? borderRadius;
    if (values.isSelected) {
      if (values.selectedMaxDate == null &&
          values.selectedMinDate != null &&
          values.day.isSameDay(_calinfo["validTo"])) {
        borderRadius = const BorderRadius.horizontal(right: Radius.circular(12));
      } else if ((values.selectedMinDate != null &&
          values.day.isSameDay(values.selectedMinDate!) &&
          (values.selectedMaxDate == null || !values.day.isSameDay(values.selectedMaxDate!)))) {
        borderRadius = const BorderRadius.horizontal(left: Radius.circular(12));
      } else if ((values.selectedMaxDate != null && values.day.isSameDay(values.selectedMaxDate!)) &&
          (values.selectedMinDate == null || !values.day.isSameDay(values.selectedMinDate!))) {
        borderRadius = const BorderRadius.horizontal(right: Radius.circular(12));
      } else if ((values.selectedMinDate != null && values.day.isSameDay(values.selectedMinDate!)) ||
          (values.selectedMaxDate != null && values.day.isSameDay(values.selectedMaxDate!))) {
        borderRadius = const BorderRadius.all(Radius.circular(12));
      }
      return BoxDecoration(
          color: bgColor,
          //backgroundBlendMode: BlendMode.xor /* BlendMode.softLight*/,
          borderRadius: borderRadius);
    } else {
      return null;
    }
  }
}
