// import 'dart:html';

import 'package:cb_app/wp/cb_map_list.dart';
import 'package:flutter/material.dart';
import 'package:cb_app/wp/cb_map_model.dart';
import 'package:cb_app/forms/background_animation.dart';
import 'package:provider/provider.dart';
import 'package:cb_app/forms/location_info_dialog.dart';
import 'package:cb_app/forms/marker_popup_item.dart';
import 'package:cb_app/parts/utils.dart';
import 'dart:ui';
import 'dart:math';

// class _ItemLocation {
//   final MapLocation location;
//   final LocationItem item;

//   const _ItemLocation(this.location, this.item);
// }

class LocationItemsList extends StatefulWidget {
  const LocationItemsList({super.key});

  @override
  State<LocationItemsList> createState() => _LocationItemsList();
}

class _LocationItemsList extends State<LocationItemsList> {
  List<MapLocation> mapLocationsSort = <MapLocation>[];

  final double _tileHeight = 190;
  final double _tileWidth = 320;
  final double _gridPadding = 5;

  ({double containerWidth, int numTiles}) _responsiveSizes(BoxConstraints constraints) {
    int numTiles = max(((constraints.maxWidth - 2 * _gridPadding) ~/ _tileWidth), 1);
    double containerWidth = (constraints.maxWidth - 2 * _gridPadding) < _tileWidth
        ? constraints.maxWidth
        : numTiles * _tileWidth + 2 * _gridPadding;

    return (containerWidth: containerWidth, numTiles: numTiles);
  }

  @override
  void initState() {
    // mapLocationsSort = List<MapLocation>.from(widget.map.mapList.mapLocations.values);
    // mapLocationsSort.sort((a, b) => a.locationName.compareTo(b.locationName));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelMapData>(builder: (context, map, child) {
      if (map.mapDataLoadingState == LoadingState.failed) {
        return Stack(
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
                // ignore: unnecessary_string_interpolations
                child: Text("${map.mapDataErrMsg}"),
              ),
            ),
          ],
        );
      }
      if (map.filters.isEmpty) {
        mapLocationsSort = List<MapLocation>.from(map.mapList.mapLocations.values);
      } else {
        mapLocationsSort = <MapLocation>[];
        for (MapEntry<String, MapLocation> e in map.mapList.mapLocations.entries) {
          if (e.value.idxItems.isNotEmpty &&
              e.value.idxItems.values.first.terms != null &&
              map.filters.keys.every((element) => e.value.idxItems.values.first.terms!.contains(element))) {
            mapLocationsSort.add(e.value);
          }
        }
      }
      mapLocationsSort.sort((a, b) => a.locationName.compareTo(b.locationName));

      return LayoutBuilder(
        builder: (context, constraints) {
          // ({double containerWidth, double gridWidth}) responsiveSizes = _responsiveSizes(constraints);
          var responsiveSizes = _responsiveSizes(constraints);
          return Container(
            padding: const EdgeInsets.only(top: 5),
            alignment: AlignmentDirectional.center,
            width: responsiveSizes.containerWidth,
            child: GridView.builder(
              padding: EdgeInsets.all(_gridPadding),
              itemCount: mapLocationsSort.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: responsiveSizes.numTiles, mainAxisExtent: _tileHeight),
              itemBuilder: (context, index) {
                return _getLocationTile(context, mapLocationsSort[index], map);
              },
            ),
          );
        },
      );
    });
  }

  Widget? _getLocationTile(BuildContext context, MapLocation location, ModelMapData map) {
    final localScrollController = ScrollController();
    return Card(
      // clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: const RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.transparent,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
          // direction: Axis.vertical,
          children: [
            _locationDescription(context, location),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 104, // MediaQuery.of(context).size.height / 6,
                // maxWidth: 300,
                // minHeight: 60,
              ),
              child: (location.idxItems.isNotEmpty)
                  ? Scrollbar(
                      controller: localScrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: localScrollController,
                        shrinkWrap: true,
                        itemCount: location.idxItems.length, // location.items.length,
                        itemBuilder: (context, index) =>
                            MarkerPopupItem(location.idxItems.values.elementAt(index), location.id),
                        // MarkerPopupItem(location.items[index], widget.marker.locationId),
                        separatorBuilder: (BuildContext context, int index) =>
                            // ignore: unnecessary_string_interpolations
                            Text("${'.' * 25}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  letterSpacing: 2.5,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                )), // Divider(),
                      ),
                    )
                  : (map.loadingPhasesFinished)
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                          child: Text(
                            "${context.l10n.noRentalInThisPeriod}!",
                            style: const TextStyle(
                                color: Color.fromARGB(255, 216, 89, 89), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                          ),
                        ),
            ),
            // const SizedBox(
            //   height: 10,
            // )
          ]),
    );
  }

  Widget _locationDescription(BuildContext context, MapLocation location) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: InkWell(
        onTap: (location.hasLocationInfo()) ? () => LocationInfoDialog(context, location, true) : null,
        child: Container(
          width: double.infinity,
          // height: 45,
          constraints: const BoxConstraints(
              // minWidth: 100,
              // maxWidth: 300,
              // maxHeight: 45,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (location.hasLocationInfo())
                      const Padding(
                        padding: EdgeInsets.only(right: 3),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.lightBlue,
                          size: 18,
                        ),
                      ),
                    Expanded(
                      // width: 50,
                      child: Text(
                        location.locationName,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        maxLines: 2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.0,
                          // height: 1.2,
                        ),
                      ),
                    ),
                  ]),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(children: [
                  Tooltip(
                    message: 'Position: ${location.lat}, ${location.lon}',
                    child: const Icon(
                      Icons.location_on_outlined,
                      size: 18,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
