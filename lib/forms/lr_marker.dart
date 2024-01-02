import 'package:flutter_map/flutter_map.dart';

class LRMarker extends Marker {
  final String locationId;

  LRMarker({
    required this.locationId,
    required super.point,
    required super.builder,
    super.key,
    super.width = 30.0,
    super.height = 30.0,
    super.rotate,
    super.rotateOrigin,
    super.rotateAlignment,
  });
}

// extension ExtMarker on Marker {
//   static final _markerInfo = Expando<Map<String, dynamic>>();

//   Map<String, dynamic> get markerInfo {
//     if ((_markerInfo[this] is! Object)) _markerInfo[this] = <String, dynamic>{};
//     return _markerInfo[this] as Map<String, dynamic>;
//   }
// }
