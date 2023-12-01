// To parse this JSON data, do
//
//     final cbMapList = cbMapListFromJson(jsonString);

import 'dart:convert';
// import 'dart:js_interop';
import 'package:intl/intl.dart';
import 'package:cb_app/parts/utils.dart';

CbMapList cbMapListFromJson(String str) => CbMapList.fromJson(json.decode(str));
CbMapList cbMapListFromJsonCBAPI(String str) => CbMapList.fromJsonCBAPI(json.decode(str));

String cbMapListToJson(CbMapList data) => json.encode(data.toJson());

class CbMapList {
  CbMapList({
    this.mapLocations = const <String, MapLocation>{},
    this.mapSettings,
  });

  Map<String, MapLocation> mapLocations;
  MapSettings? mapSettings;

  factory CbMapList.fromJson(Map<String, dynamic> json) => CbMapList(
        mapLocations: json["map"] is Map
            ? Map.from(json["map"]).map((k, v) => MapEntry<String, MapLocation>(k, MapLocation.fromJson(k, v)))
            : <String, MapLocation>{},
        mapSettings: MapSettings.fromJson(json["settings"]),
      );

  factory CbMapList.fromJsonCBAPI(Map<String, dynamic> json) {
    CbMapList map = CbMapList(
      mapLocations: <String, MapLocation>{},
    );

    for (var e in json["locations"]['features']) {
      map.mapLocations[e["properties"]["id"]] = MapLocation.fromJsonCBAPI(e);
    }

    if (json['items'] == null) return map;

    Map<String, LocationItem> items = <String, LocationItem>{};
    for (var e in json['items']) {
      items[e["id"]] = LocationItem.fromJsonCBAPI(e);
    }

    for (var e in json['availability']) {
      if (items.containsKey(e['itemId']) && map.mapLocations.containsKey(e['locationId'])) {
        map.mapLocations[e['locationId']]?.idxItems[e['itemId']] = items[e['itemId']]!;
        DateTime dtEnd = DateTime.parse(e["end"]);
        DateTime dtStart = DateTime.parse(e["start"]);
        do {
          items[e['itemId']]!.availability!.add(Availability(date: dtStart, status: Status.AVAILABLE));
          dtStart = dtStart.add(const Duration(days: 1));
        } while (dtEnd.isAfter(dtStart));
      }
    }

    return map;
  }

  Map<String, dynamic> toJson() => {
        "map": Map.from(mapLocations).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class MapLocation implements LocationInfoInterface {
  String id;
  double lat;
  double lon;
  String locationName;
  String locationLink;
  List<dynamic> closedDays;
  bool disallowLockDaysInRange;
  bool countLockDaysInRange;
  int countLockDaysMaxDays;

  @override
  String? formattedContactInfoOneLine;
  @override
  String? formattedPickupInstructionsOneLine;
  @override
  String? formattedAddressOneLine;
  @override
  String? locationDescription;
  @override
  String? comment = "";
  @override
  String? formattedContactInfoOneLineFormat;
  @override
  String? formattedPickupInstructionsOneLineFormat;
  @override
  String? formattedAddressOneLineFormat;
  @override
  String? commentFormat;
  @override
  String? locationDescriptionFormat;

  Address address;
  // List<LocationItem> items;
  Map<String, LocationItem> idxItems;
  var defAdr = Address(street: '', city: '', zip: '');

  MapLocation({
    required this.id,
    required this.lat,
    required this.lon,
    required this.locationName,
    required this.locationLink,
    required this.closedDays,
    required this.address,
    required this.disallowLockDaysInRange,
    required this.countLockDaysInRange,
    required this.countLockDaysMaxDays,
    // required this.items,
    required this.idxItems,
    this.formattedContactInfoOneLine,
    this.formattedPickupInstructionsOneLine,
    this.formattedAddressOneLine,
    this.locationDescription,
    this.formattedContactInfoOneLineFormat,
    this.formattedPickupInstructionsOneLineFormat,
    this.formattedAddressOneLineFormat,
    this.locationDescriptionFormat,
  });

  @override
  bool hasLocationInfo() {
    return ((formattedContactInfoOneLine != null && formattedContactInfoOneLine!.isNotEmpty) ||
        (formattedPickupInstructionsOneLine != null && formattedPickupInstructionsOneLine!.isNotEmpty) ||
        (formattedAddressOneLine != null && formattedAddressOneLine!.isNotEmpty) ||
        (comment != null && comment!.isNotEmpty));
  }

  factory MapLocation.fromJson(k, Map<String, dynamic> json) => MapLocation(
        id: k,
        lat: json["lat"]?.toDouble(),
        lon: json["lon"]?.toDouble(),
        locationName: json["location_name"] ?? 'Station ohne Namen',
        locationLink: json["location_link"] ?? '',
        closedDays: json["closed_days"] == null ? [] : List<dynamic>.from(json["closed_days"]!.map((x) => x)),
        address: json["address"] == null ? Address() : Address.fromJson(json["address"]),
        // items:
        //     json["items"] == null ? [] : List<LocationItem>.from(json["items"]!.map((x) => LocationItem.fromJson(x))),
        idxItems: json["items"] == null
            ? <String, LocationItem>{}
            : {
                for (var item in List<LocationItem>.from(json["items"]!.map((x) => LocationItem.fromJson(x))))
                  item.id.toString(): item,
              },
        formattedContactInfoOneLine: json['formattedContactInfoOneLine'],
        formattedPickupInstructionsOneLine: json['formattedPickupInstructionsOneLine'],
        formattedAddressOneLine: json['formattedAddressOneLine'],
        formattedContactInfoOneLineFormat: json['formattedContactInfoOneLineFormat'],
        formattedPickupInstructionsOneLineFormat: json['formattedPickupInstructionsOneLineFormat'],
        formattedAddressOneLineFormat: json['formattedAddressOneLineFormat'],
        locationDescription: json['description'],
        locationDescriptionFormat: json['descriptionFormat'],
        disallowLockDaysInRange: json['disallowLockDaysInRange'] ?? false,
        countLockDaysInRange: json['countLockDaysInRange'] ?? false,
        countLockDaysMaxDays: json['countLockDaysMaxDays'] ?? 0,
      );

  factory MapLocation.fromJsonCBAPI(Map<String, dynamic> json) => MapLocation(
        id: json["properties"]["id"],
        lon: json["geometry"]["coordinates"][0]?.toDouble(),
        lat: json["geometry"]["coordinates"][1]?.toDouble(),
        locationName: json["properties"]["name"] ?? 'Station ohne Namen',
        locationLink: json["properties"]["url"] ?? '',
        closedDays: json["closed_days"] == null ? [] : List<dynamic>.from(json["closed_days"]!.map((x) => x)),
        address:
            json["properties"]["address"] == null ? Address() : Address.fromJsonCBAPI(json["properties"]["address"]),
        formattedAddressOneLine: json["properties"]["address"] ??= "",
        formattedPickupInstructionsOneLine: json["properties"]['pickupInstructions'] ??= "",
        locationDescription: json["properties"]['description'] ??= "",
        // items:
        //     json["items"] == null ? [] : List<LocationItem>.from(json["items"]!.map((x) => LocationItem.fromJson(x))),
        idxItems: json["items"] == null
            ? <String, LocationItem>{}
            : {
                for (var item in List<LocationItem>.from(json["items"]!.map((x) => LocationItem.fromJson(x))))
                  item.id.toString(): item,
              },

        // Map<String, Item>()
        // : Map<String, Item>.fromIterable(List<Item>.from(json["items"]!.map((x) => Item.fromJson(x))),
        //     key: (y) => y.id.toString(), value: (y) => y),
        disallowLockDaysInRange: json['disallowLockDaysInRange'] ?? false,
        countLockDaysInRange: json['countLockDaysInRange'] ?? false,
        countLockDaysMaxDays: json['countLockDaysMaxDays'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "lat": lat,
        "lon": lon,
        "location_name": locationName,
        "location_link": locationLink,
        "closed_days": List<dynamic>.from(closedDays!.map((x) => x)),
        "address": address.toJson(),
        // "items":  List<dynamic>.from(items!.map((x) => x.toJson())),
        "idxItems": List<dynamic>.from(idxItems.values.map((x) => x.toJson())),
      };
}

class Address {
  String street;
  String city;
  String zip;

  Address({
    this.street = '',
    this.city = '',
    this.zip = '',
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        street: json["street"],
        city: json["city"],
        zip: json["zip"],
      );

  factory Address.fromJsonCBAPI(String adr) {
    final regex = RegExp(r'^(.*)\s*,\s*([0-9]*)\s*(.*)\s*$');
    final match = regex.firstMatch(adr);
    return Address(
      street: match?.group(1) ?? adr,
      city: match?.group(3) ?? '',
      zip: match?.group(2) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "street": street,
        "city": city,
        "zip": zip,
      };
}

class LocationItem {
  int? id;
  String? name;
  String? shortDesc;
  String? description;
  String? descriptionFormat;
  String? status;
  List<int>? terms;
  String? link;
  String? thumbnail;
  List<Timeframe>? timeframes;
  List<Availability>? availability;
  int? maxDays;

  LocationItem({
    this.id,
    this.name,
    this.shortDesc,
    this.description,
    this.descriptionFormat,
    this.status,
    this.terms,
    this.link,
    this.thumbnail,
    this.timeframes,
    this.availability,
    this.maxDays,
  });

  factory LocationItem.fromJson(Map<String, dynamic> json) => LocationItem(
        id: json["id"],
        name: json["name"],
        shortDesc: json["short_desc"],
        status: json["status"],
        maxDays: json['maxDays'],
        terms: json["terms"] == null ? [] : List<int>.from(json["terms"]!.map((x) => x)),
        link: json["link"],
        description: json["description"],
        descriptionFormat: json["descriptionFormat"],
        thumbnail: json["thumbnail"],
        timeframes: json["timeframes"] == null
            ? []
            : List<Timeframe>.from(json["timeframes"]!.map((x) => Timeframe.fromJson(x))),
        availability: json["availability"] == null
            ? []
            : List<Availability>.from(json["availability"]!.map((x) => Availability.fromJson(x)))
          ..sort((a, b) => compDateTimeNull(a.date, b.date!)),
      );

  factory LocationItem.fromJsonCBAPI(Map<String, dynamic> json) => LocationItem(
        id: int.parse(json["id"]),
        name: json["name"],
        // shortDesc: json["description"],
        description: json["description"],
        status: json["status"],
        terms: json["terms"] == null ? [] : List<int>.from(json["terms"]!.map((x) => x)),
        link: json["url"],
        thumbnail: json["image"],
        timeframes: json["timeframes"] == null
            ? []
            : List<Timeframe>.from(json["timeframes"]!.map((x) => Timeframe.fromJson(x))),
        availability: json["availability"] == null
            ? []
            : List<Availability>.from(json["availability"]!.map((x) => Availability.fromJson(x)))
          ..sort((a, b) => compDateTimeNull(a.date, b.date!)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "short_desc": shortDesc,
        "status": status,
        "terms": terms == null ? [] : List<dynamic>.from(terms!.map((x) => x)),
        "link": link,
        "thumbnail": thumbnail,
        "timeframes": timeframes == null ? [] : List<dynamic>.from(timeframes!.map((x) => x.toJson())),
        "availability": availability == null ? [] : List<dynamic>.from(availability!.map((x) => x.toJson())),
      };

  final Map<String, Status> _availabilityByDate = {};
  Map<String, Status> get availabilityByDate {
    if (_availabilityByDate.isEmpty && availability != null) {
      final dtf = DateFormat("yyyy-MM-dd");
      for (Availability a in availability!) {
        _availabilityByDate[dtf.format(a.date!)] = a.status!;
      }
    }
    return _availabilityByDate;
  }

  DateTime? get firstAvailability {
    return availability?.first.date;
  }

  DateTime? get lastAvailability {
    return availability?.last.date;
  }
}

class Availability {
  DateTime? date;
  Status? status;

  Availability({
    this.date,
    this.status,
  });

  factory Availability.fromJson(Map<String, dynamic> json) => Availability(
        date: json["date"] == null ? null : DateTime.parse(json["date"]),
        status: statusValues.map[json["status"]]!,
      );

  factory Availability.fromJsonCBAPI(Map<String, dynamic> json) => Availability(
        date: json["start"] == null ? null : DateTime.parse(json["start"]),
        status: Status.AVAILABLE,
      );

  Map<String, dynamic> toJson() => {
        "date":
            "${date!.year.toString().padLeft(4, '0')}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}",
        "status": statusValues.reverse[status],
      };
}

enum Status { AVAILABLE, LOCKED, BOOKED, HOLIDAY, PARTIALLY_BOOKED, OUT_OF_TIMEFRAME }

final statusValues = EnumValues({
  "available": Status.AVAILABLE,
  "booked": Status.BOOKED,
  "locked": Status.LOCKED,
  "partially-booked": Status.PARTIALLY_BOOKED,
  "no-timeframe": Status.OUT_OF_TIMEFRAME,
  'location-holiday': Status.HOLIDAY
});

class Timeframe {
  DateTime? dateStart;
  int? dateEnd;

  Timeframe({
    this.dateStart,
    this.dateEnd,
  });

  factory Timeframe.fromJson(Map<String, dynamic> json) => Timeframe(
        dateStart: /*DateTime(2023), */ json["date_start"] == null ? null : DateTime.parse(json["date_start"]),
        dateEnd: (json["date_end"] is String)
            ? DateTime.parse(json["date_start"]).millisecondsSinceEpoch * 1000
            : json["date_end"], //0, //json["date_end"],
      );

  Map<String, dynamic> toJson() => {
        "date_start":
            "${dateStart!.year.toString().padLeft(4, '0')}-${dateStart!.month.toString().padLeft(2, '0')}-${dateStart!.day.toString().padLeft(2, '0')}",
        "date_end": dateEnd,
      };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}

/* Map Settings Classes */
class MapSettings {
  String? dataUrl;
  String? nonce;
  CustomMarkerIcon? customMarkerIcon;
  // Null itemDraftMarkerIcon;
  String? preferredStatusMarkerIcon;
  Map<String, FilterCbItemCategorie>? filterCbItemCategories;
  FilterAvailability? filterAvailability;
  int? cbMapId;
  String? locale;
  String? assetPath;
  int? baseMap;
  bool? showScale;
  int? zoomMin;
  int? zoomMax;
  bool? scrollWheelZoom;
  int? zoomStart;
  double? latStart;
  double? lonStart;
  bool? markerMapBoundsInitial;
  bool? markerMapBoundsFilter;
  int? maxClusterRadius;
  bool? markerTooltipPermanent;
  bool? showLocationContact;
  bool? showLocationOpeningHours;
  bool? showItemAvailability;
  bool? showLocationDistanceFilter;
  String? labelLocationDistanceFilter;
  bool? showItemAvailabilityFilter;
  String? labelItemAvailabilityFilter;
  String? labelItemCategoryFilter;

  MapSettings(
      {this.dataUrl,
      this.nonce,
      this.customMarkerIcon,
      // this.itemDraftMarkerIcon,
      this.preferredStatusMarkerIcon,
      this.filterCbItemCategories,
      this.filterAvailability,
      this.cbMapId,
      this.locale,
      this.assetPath,
      this.baseMap,
      this.showScale,
      this.zoomMin,
      this.zoomMax,
      this.scrollWheelZoom,
      this.zoomStart,
      this.latStart,
      this.lonStart,
      this.markerMapBoundsInitial,
      this.markerMapBoundsFilter,
      this.maxClusterRadius,
      this.markerTooltipPermanent,
      this.showLocationContact,
      this.showLocationOpeningHours,
      this.showItemAvailability,
      this.showLocationDistanceFilter,
      this.labelLocationDistanceFilter,
      this.showItemAvailabilityFilter,
      this.labelItemAvailabilityFilter,
      this.labelItemCategoryFilter});

  MapSettings.fromJson(Map<String, dynamic> json) {
    dataUrl = json['data_url'];
    nonce = json['nonce'];
    customMarkerIcon =
        json['custom_marker_icon'] != null ? CustomMarkerIcon.fromJson(json['custom_marker_icon']) : null;
    // itemDraftMarkerIcon = json['item_draft_marker_icon'];
    preferredStatusMarkerIcon = json['preferred_status_marker_icon'];
    filterCbItemCategories = json['filter_cb_item_categories'] != null && json['filter_cb_item_categories'] is Map
        ? Map.from(json['filter_cb_item_categories']).map((key, value) => MapEntry(key,
            FilterCbItemCategorie.fromJson(value))) //FilterCbItemCategories.fromJson(json['filter_cb_item_categories'])
        : null;
    filterAvailability =
        json['filter_availability'] != null ? FilterAvailability.fromJson(json['filter_availability']) : null;
    cbMapId = json['cb_map_id'];
    locale = json['locale'];
    assetPath = json['asset_path'];
    baseMap = json['base_map'];
    showScale = json['show_scale'];
    zoomMin = json['zoom_min'];
    zoomMax = json['zoom_max'];
    scrollWheelZoom = json['scrollWheelZoom'];
    zoomStart = json['zoom_start'];
    latStart = json['lat_start'];
    lonStart = json['lon_start'];
    markerMapBoundsInitial = json['marker_map_bounds_initial'];
    markerMapBoundsFilter = json['marker_map_bounds_filter'];
    maxClusterRadius = json['max_cluster_radius'];
    markerTooltipPermanent = json['marker_tooltip_permanent'];
    showLocationContact = json['show_location_contact'];
    showLocationOpeningHours = json['show_location_opening_hours'];
    showItemAvailability = json['show_item_availability'];
    showLocationDistanceFilter = json['show_location_distance_filter'];
    labelLocationDistanceFilter = json['label_location_distance_filter'];
    showItemAvailabilityFilter = json['show_item_availability_filter'];
    labelItemAvailabilityFilter = json['label_item_availability_filter'];
    labelItemCategoryFilter = json['label_item_category_filter'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['data_url'] = dataUrl;
    data['nonce'] = nonce;
    if (customMarkerIcon != null) {
      data['custom_marker_icon'] = customMarkerIcon!.toJson();
    }
    // data['item_draft_marker_icon'] = itemDraftMarkerIcon;
    data['preferred_status_marker_icon'] = preferredStatusMarkerIcon;
    // if (filterCbItemCategories != null) {
    //   data['filter_cb_item_categories'] = filterCbItemCategories!.toJson();
    // }
    if (filterAvailability != null) {
      data['filter_availability'] = filterAvailability!.toJson();
    }
    data['cb_map_id'] = cbMapId;
    data['locale'] = locale;
    data['asset_path'] = assetPath;
    data['base_map'] = baseMap;
    data['show_scale'] = showScale;
    data['zoom_min'] = zoomMin;
    data['zoom_max'] = zoomMax;
    data['scrollWheelZoom'] = scrollWheelZoom;
    data['zoom_start'] = zoomStart;
    data['lat_start'] = latStart;
    data['lon_start'] = lonStart;
    data['marker_map_bounds_initial'] = markerMapBoundsInitial;
    data['marker_map_bounds_filter'] = markerMapBoundsFilter;
    data['max_cluster_radius'] = maxClusterRadius;
    data['marker_tooltip_permanent'] = markerTooltipPermanent;
    data['show_location_contact'] = showLocationContact;
    data['show_location_opening_hours'] = showLocationOpeningHours;
    data['show_item_availability'] = showItemAvailability;
    data['show_location_distance_filter'] = showLocationDistanceFilter;
    data['label_location_distance_filter'] = labelLocationDistanceFilter;
    data['show_item_availability_filter'] = showItemAvailabilityFilter;
    data['label_item_availability_filter'] = labelItemAvailabilityFilter;
    data['label_item_category_filter'] = labelItemCategoryFilter;
    return data;
  }
}

class CustomMarkerIcon {
  String? iconUrl;
  List<int>? iconSize;
  List<int>? iconAnchor;

  CustomMarkerIcon({this.iconUrl, this.iconSize, this.iconAnchor});

  CustomMarkerIcon.fromJson(Map<String, dynamic> json) {
    iconUrl = json['iconUrl'];
    iconSize = json['iconSize'].cast<int>();
    iconAnchor = json['iconAnchor'].cast<int>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['iconUrl'] = iconUrl;
    data['iconSize'] = iconSize;
    data['iconAnchor'] = iconAnchor;
    return data;
  }
}

// class FilterCbItemCategories {
//   Map<String, FilterCbItemCategorie>? filterCbItemCategories;

//   FilterCbItemCategories({this.filterCbItemCategories});

//   FilterCbItemCategories.fromJson(Map<String, dynamic> json) {
//     filterCbItemCategories = json.map((key, value) => MapEntry(key, FilterCbItemCategorie.fromJson(value)));
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     // if (g1621372616985716841 != null) {
//     //   data['g1621372616985-716841'] = g1621372616985716841!.toJson();
//     // }
//     return data;
//   }
// }

class FilterCbItemCategorie {
  String? name;
  List<FilterCbItemCategorieElement>? elements;

  FilterCbItemCategorie({this.name, this.elements});

  FilterCbItemCategorie.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    if (json['elements'] != null) {
      elements = <FilterCbItemCategorieElement>[];
      json['elements'].forEach((v) {
        elements!.add(FilterCbItemCategorieElement.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (elements != null) {
      data['elements'] = elements!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FilterCbItemCategorieElement {
  int? catId;
  String? markup;

  FilterCbItemCategorieElement({this.catId, this.markup});

  FilterCbItemCategorieElement.fromJson(Map<String, dynamic> json) {
    catId = json['cat_id'];
    markup = json['markup'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cat_id'] = catId;
    data['markup'] = markup;
    return data;
  }
}

class FilterAvailability {
  String? dateMin;
  String? dateMax;
  String? dayCountMax;

  FilterAvailability({this.dateMin, this.dateMax, this.dayCountMax});

  FilterAvailability.fromJson(Map<String, dynamic> json) {
    dateMin = json['date_min'];
    dateMax = json['date_max'];
    dayCountMax = json['day_count_max'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date_min'] = dateMin;
    data['date_max'] = dateMax;
    data['day_count_max'] = dayCountMax;
    return data;
  }
}
