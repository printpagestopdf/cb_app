// import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:cb_app/wp/cb_map_list.dart';
import 'package:provider/provider.dart';
import 'package:cb_app/wp/cb_map_model.dart';
import 'package:cb_app/parts/utils.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class OverviewCalendar extends StatelessWidget {
  static Border dayBorder = Border.all(width: 0.5, color: const Color.fromARGB(255, 0, 0, 0));
  static const BorderRadius dayBorderRadius = BorderRadius.all(Radius.circular(6.0));
  static const Color redColor = Color.fromRGBO(213, 66, 92, 1.0);
  static const Color greenColor = Color.fromRGBO(116, 206, 60, 1.0);
  static const Color grayColor = Color.fromRGBO(221, 221, 221, 1.0);

  static BoxDecoration bookedDecoration = BoxDecoration(
    border: dayBorder,
    borderRadius: dayBorderRadius,
    gradient: const LinearGradient(
      transform: GradientRotation(pi / 2),
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      stops: [0.0, 0.48, 0.48, 0.52, 0.52, 1.0],
      colors: [redColor, redColor, Colors.black, Colors.black, redColor, redColor],
    ),
  );

  static BoxDecoration hollidayDecoration = BoxDecoration(
    border: dayBorder,
    borderRadius: dayBorderRadius,
    gradient: const LinearGradient(
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
    borderRadius: dayBorderRadius,
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
    borderRadius: dayBorderRadius,
    color: greenColor,
  );

  static BoxDecoration lockedDecoration = BoxDecoration(
    border: dayBorder,
    borderRadius: dayBorderRadius,
    color: grayColor,
  );

  BoxDecoration availabilityDecoration(Status? stat) {
    switch (stat) {
      case Status.AVAILABLE:
        return availableDecoration;
      case Status.BOOKED:
        return bookedDecoration;
      case Status.LOCKED:
        return lockedDecoration;
      case Status.HOLIDAY:
        return hollidayDecoration;
      case Status.PARTIALLY_BOOKED:
        return partiallyDecoration;
      default:
        return bookedDecoration;
    }
  }

  final String locationId;
  final String itemId;

  final datStyle = const TextStyle(
    fontSize: 11.0,
  );

  const OverviewCalendar(this.locationId, this.itemId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return ChangeNotifierProvider(
    //     create: (context) => ModelMapData(),
    //     builder: (context, child) {
    return Consumer<ModelMapData>(builder: (context, mapModel, child) {
      // List<Availability>? avail = mapModel.mapList.mapLocations[locationId]?.idxItems[itemId]?.availability;
      Map<String, Status>? availByDate =
          mapModel.mapList.mapLocations[locationId]?.idxItems[itemId]?.availabilityByDate;
      // if (availabilities.isNull || availabilities.isEmpty) {
      if (availByDate == null || availByDate.isEmpty) {
        return Wrap(children: [
          Text(
            "${context.l10n.availabilities}.....  ",
            textAlign: TextAlign.center,
            style: const TextStyle(),
          ),
          const SizedBox.square(
            dimension: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
            ),
          ),
        ]);
      } else {
        double m = 5.0;
        final dtf = DateFormat("yyyy-MM-dd");
        DateTime now = DateTime.now();
        DateTime dtNow = DateTime.utc(now.year, now.month, now.day);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(7, (int index) {
            m = (index == 6) ? 0 : 5;
            DateTime dt = dtNow.add(Duration(days: index));
            String dtKey = dtf.format(dt);
            Status state = availByDate.containsKey(dtKey) ? availByDate[dtKey]! : Status.BOOKED;
            return Tooltip(
              message: DateFormat.yMd(Localizations.localeOf(context).toString()).format(dt),
              child: Container(
                // width: 28,
                margin: EdgeInsetsDirectional.only(end: m),
                padding: const EdgeInsets.all(3.0),
                decoration: availabilityDecoration(state),
                child: Text(
                  Localizations.localeOf(context).languageCode == "de"
                      ? "${dt.day.toString().padLeft(2, '0')}.\n${dt.month.toString().padLeft(2, '0')}."
                      : "${dt.month.toString().padLeft(2, '0')} \n${dt.day.toString().padLeft(2, '0')} ",
                  // sprintf("%02i.\n%02i.", [dt.day, dt.month]),
                  style: datStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }, growable: false),
        );

        // return Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: List<Widget>.generate(7, (int index) {
        //       m = (index == 6) ? 0 : 5;
        //       return Container(
        //         // width: 28,
        //         margin: EdgeInsetsDirectional.only(end: m),
        //         padding: const EdgeInsets.all(3.0),
        //         decoration: availabilityDecoration(avail[index].status),
        //         child: Text(
        //           sprintf("%02i.\n%02i.", [avail[index].date?.day, avail[index].date?.month]),
        //           style: datStyle,
        //           textAlign: TextAlign.center,
        //         ),
        //       );
        //     }, growable: false),
        //     );
      }
    });
  }
  //);
}
// }
