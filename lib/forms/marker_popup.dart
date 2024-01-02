import 'package:cb_app/parts/utils.dart';
import 'package:cb_app/wp/cb_map_model.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:cb_app/forms/marker_popup_item.dart';
import 'package:flutter/gestures.dart';
import 'package:cb_app/wp/cb_map_list.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'lr_marker.dart';
import 'package:cb_app/main.dart';
import 'package:cb_app/forms/location_info_dialog.dart';

class MarkerPopup extends StatefulWidget {
  final LRMarker marker;
  final PopupController _popupController;

  const MarkerPopup(this.marker, this._popupController, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MarkerPopupState();
}

class _MarkerPopupState extends State<MarkerPopup> with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final GlobalKey _widgetKey = GlobalKey();

  late MapLocation location;
  AnimationController? animationController;

  void _ensureBoxVisibility(context) {
    if (CBApp.flutterMapKey.currentContext?.findRenderObject() is! RenderBox ||
        _widgetKey.currentContext?.findRenderObject() is! RenderBox ||
        context.findAncestorWidgetOfExactType<FlutterMap>()?.mapController is! MapController) return;

    final RenderBox flutterMapRenderBox = CBApp.flutterMapKey.currentContext?.findRenderObject() as RenderBox;
    final RenderBox popupRenderBox = _widgetKey.currentContext?.findRenderObject() as RenderBox;
    final MapController controller =
        context.findAncestorWidgetOfExactType<FlutterMap>()?.mapController as MapController;

    final Size flutterMapSize = flutterMapRenderBox.size;
    final Size popupSize = popupRenderBox.size;

    final Offset leftTopOffset = popupRenderBox.localToGlobal(Offset.zero, ancestor: flutterMapRenderBox);
    Offset bottomRightOffset =
        popupRenderBox.localToGlobal(Offset(popupSize.width, popupSize.height), ancestor: flutterMapRenderBox);
    bottomRightOffset =
        Offset(flutterMapSize.width - bottomRightOffset.dx, flutterMapSize.height - bottomRightOffset.dy);

    double moveX = 0, moveY = 0;

    if (leftTopOffset.dx < 0) {
      moveX = leftTopOffset.dx.abs();
    } else if (bottomRightOffset.dx < 0) {
      moveX = bottomRightOffset.dx;
    }
    if (leftTopOffset.dy < 0) {
      moveY = leftTopOffset.dy.abs();
    }

    if (moveX != 0 || moveY != 0) {
      animationController ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

      Animation<Offset> animation = Tween<Offset>(begin: const Offset(0, 0), end: Offset(moveX, moveY))
          .chain(CurveTween(
            curve: Curves.elasticOut,
          ))
          .animate(animationController as AnimationController);

      final LatLng center = controller.center;
      final double zoom = controller.zoom;
      (animationController as AnimationController).addListener(() {
        controller.move(center, zoom, offset: animation.value);
      });
      (animationController as AnimationController).forward();
    }
  }

  @override
  void dispose() {
    if (animationController != null) (animationController as AnimationController).dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureBoxVisibility(context));
  }

  @override
  Widget build(BuildContext context) {
    // location = (Provider.of<ModelMapData>(context, listen: false).mapList.mapLocations[widget.marker.locationId]
    //     as MapLocation);
    return ChangeNotifierProvider(
        create: (context) => ModelMapData(),
        builder: (context, child) {
          return Consumer<ModelMapData>(builder: (context, modelMap, child) {
            location = modelMap.mapList.mapLocations[widget.marker.locationId] as MapLocation;
            return Listener(
              onPointerSignal: (PointerSignalEvent event) {
                GestureBinding.instance.pointerSignalResolver.register(event, (PointerSignalEvent event) {
                  //don't propagate scroll event to parents
                });
              },
              child: GestureDetector(
                onTap: () {
                  // don't propaget Tap/Click event to parents;
                },
                child: Card(
                  key: _widgetKey,
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  shape: const RoundedRectangleBorder(
                    side: BorderSide(
                      color: Colors.transparent,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Wrap(direction: Axis.vertical, children: [
                    _locationDescription(context),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 104, // MediaQuery.of(context).size.height / 6,
                        maxWidth: 300,
                        minHeight: 60,
                      ),
                      child: (location.idxItems.isNotEmpty)
                          ? Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: false,
                              child: ListView.separated(
                                controller: _scrollController,
                                shrinkWrap: true,
                                itemCount: location.idxItems.length, // location.items.length,
                                itemBuilder: (context, index) => MarkerPopupItem(
                                    location.idxItems.values.elementAt(index), widget.marker.locationId),
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
                          : (modelMap.loadingPhasesFinished)
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                                  child: Text(
                                    context.l10n.noRentalInThisPeriod,
                                    style: const TextStyle(
                                        color: Color.fromARGB(255, 216, 89, 89),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                )
                              : const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                  ),
                                ),
                    ),
                    const SizedBox(
                      height: 10,
                    )
                  ]),
                ),
              ),
              //),
            );
          });
        });
  }

  Widget _locationDescription(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: InkWell(
        onTap: (location.hasLocationInfo()) ? () => LocationInfoDialog(context, location, true) : null,
        child: Container(
          width: 300,
          // height: 45,
          constraints: const BoxConstraints(
              // minWidth: 100,
              // maxWidth: 200,
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
                      child: Text(
                        location.locationName,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.0,
                          // height: 1.2,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        widget._popupController.hideAllPopups();
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
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(children: [
                  Tooltip(
                    message: 'Position: ${widget.marker.point.latitude}, ${widget.marker.point.longitude}',
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
