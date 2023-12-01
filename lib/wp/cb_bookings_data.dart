import 'package:cb_app/parts/utils.dart';

class BookingsData {
  int? page;
  int? perPage;
  Filters? filters;
  List<BookingsItemData>? data;
  int? total;
  int? totalPages;

  BookingsData({this.page, this.perPage, this.filters, this.data, this.total, this.totalPages});

  BookingsData.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    perPage = (json['per_page'] is String) ? int.tryParse(json['per_page']) : json['per_page'];
    filters = json['filters'] != null ? Filters.fromJson(json['filters']) : null;
    if (json['data'] != null) {
      data = <BookingsItemData>[];
      json['data'].forEach((v) {
        data!.add(BookingsItemData.fromJson(v));
      });
    }
    total = json['total'];
    totalPages = json['total_pages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['page'] = page;
    data['per_page'] = perPage;
    if (filters != null) {
      data['filters'] = filters!.toJson();
    }
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['total'] = total;
    data['total_pages'] = totalPages;
    return data;
  }
}

class Filters {
  List<String>? user;
  List<String>? item;
  List<String>? location;
  List<String>? status;

  Filters({this.user, this.item, this.location, this.status});

  Filters.fromJson(Map<String, dynamic> json) {
    user = json['user'].cast<String>();
    item = json['item'].cast<String>();
    location = json['location'].cast<String>();
    status = json['status'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user'] = user;
    data['item'] = item;
    data['location'] = location;
    data['status'] = status;
    return data;
  }
}

class BookingsItemData implements LocationInfoInterface {
  int? bookingId;
  String? startDate;
  String? endDate;
  String? startDateFormatted;
  String? endDateFormatted;
  String? item;
  int? itemId;
  String? itemThumbnail;
  String? location;
  int? locationId;
  String? bookingDate;
  String? user;
  String? status;
  @override
  String? comment;
  @override
  String? commentFormat;
  Content? content;
  User? bookingCode;
  String? actions;
  @override
  String? formattedContactInfoOneLine;
  @override
  String? formattedPickupInstructionsOneLine;
  @override
  String? formattedAddressOneLine;
  @override
  String? locationDescription;
  @override
  String? formattedContactInfoOneLineFormat;
  @override
  String? formattedPickupInstructionsOneLineFormat;
  @override
  String? formattedAddressOneLineFormat;
  @override
  String? locationDescriptionFormat;

  BookingsItemData({
    this.bookingId,
    this.startDate,
    this.endDate,
    this.startDateFormatted,
    this.endDateFormatted,
    this.item,
    this.itemId,
    this.itemThumbnail,
    this.location,
    this.locationId,
    this.bookingDate,
    this.user,
    this.status,
    this.comment,
    this.commentFormat,
    this.content,
    this.bookingCode,
    this.actions,
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

  BookingsItemData.fromJson(Map<String, dynamic> json) {
    bookingId = json['booking_id'];
    startDate = (json['startDate'] is String) ? json['startDate'] : json['startDate'].toString();
    endDate = (json['endDate'] is String) ? json['endDate'] : json['endDate'].toString();
    startDateFormatted = json['startDateFormatted'];
    endDateFormatted = json['endDateFormatted'];
    item = json['item'];
    itemId = json['item_id'];
    itemThumbnail = (json['item_thumbnail'] is String) ? json['item_thumbnail'] : '';
    location = json['location'];
    locationId = json['location_id'];
    bookingDate = json['bookingDate'];
    user = json['user'];
    status = json['status'];
    comment = json['comment'] ?? "";
    commentFormat = json['commentFormat'];
    content = json['content'] != null ? Content.fromJson(json['content']) : null;
    bookingCode = json['bookingCode'] != null ? User.fromJson(json['bookingCode']) : null;
    actions = json['actions'];
    formattedContactInfoOneLine = json['formattedContactInfoOneLine'];
    formattedPickupInstructionsOneLine = json['formattedPickupInstructionsOneLine'];
    formattedAddressOneLine = json['formattedAddressOneLine'];
    locationDescription = json['locationDescription'];
    formattedContactInfoOneLineFormat = json['formattedContactInfoOneLineFormat'];
    formattedPickupInstructionsOneLineFormat = json['formattedPickupInstructionsOneLineFormat'];
    formattedAddressOneLineFormat = json['formattedAddressOneLineFormat'];
    locationDescriptionFormat = json['locationDescriptionFormat'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['booking_id'] = bookingId;
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['startDateFormatted'] = startDateFormatted;
    data['endDateFormatted'] = endDateFormatted;
    data['item'] = item;
    data['item_id'] = itemId;
    data['location'] = location;
    data['location_id'] = locationId;
    data['bookingDate'] = bookingDate;
    data['user'] = user;
    data['status'] = status;
    if (content != null) {
      data['content'] = content!.toJson();
    }
    if (bookingCode != null) {
      data['bookingCode'] = bookingCode!.toJson();
    }
    data['actions'] = actions;
    return data;
  }
}

class Content {
  User? user;
  User? status;

  Content({this.user, this.status});

  Content.fromJson(Map<String, dynamic> json) {
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    status = json['status'] != null ? User.fromJson(json['status']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (status != null) {
      data['status'] = status!.toJson();
    }
    return data;
  }
}

class User {
  String? label;
  String? value;

  User({this.label, this.value});

  User.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['label'] = label;
    data['value'] = value;
    return data;
  }
}
