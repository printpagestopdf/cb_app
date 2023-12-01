import 'package:flutter_map/flutter_map.dart';

class LRMarker extends Marker {
  final String locationId;

  LRMarker({
    required this.locationId,
    required point,
    required builder,
    key,
    width = 30.0,
    height = 30.0,
    rotate,
    rotateOrigin,
    rotateAlignment,
  }) : super(
          point: point,
          builder: builder,
          key: key,
          width: width,
          height: height,
          rotate: rotate,
          rotateOrigin: rotateOrigin,
          rotateAlignment: rotateAlignment,
        );
}

// extension ExtMarker on Marker {
//   static final _markerInfo = Expando<Map<String, dynamic>>();

//   Map<String, dynamic> get markerInfo {
//     if ((_markerInfo[this] is! Object)) _markerInfo[this] = <String, dynamic>{};
//     return _markerInfo[this] as Map<String, dynamic>;
//   }
// }
