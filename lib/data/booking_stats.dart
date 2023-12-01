import 'package:intl/intl.dart';

class BookingStats {
  final _dtf = DateFormat("yyyy-MM-dd");
  final _mtf = DateFormat("yyyy-MM");

  RestrictionGroup? monthRestrictions;
  RestrictionGroup? weekRestrictions;

  bool get isEmpty {
    return (monthRestrictions == null && weekRestrictions == null);
  }

  final Set<String> _weekFullRestrict = <String>{}; //yyy-MM-dd
  final Set<String> _monthFullRestrict = <String>{}; //yyy-MM

  bool isFullWeekMonthRestriction(DateTime day) {
    if (_monthFullRestrict.isNotEmpty) {
      String strMonth = _mtf.format(day);
      if (_monthFullRestrict.contains(strMonth)) return true;
    }

    if (_weekFullRestrict.isNotEmpty) {
      String strDay = DateFormat("yyyy-MM-dd").format(day);
      if (_weekFullRestrict.contains(strDay)) return true;
    }

    return false;
  }

  BookingStats({this.monthRestrictions, this.weekRestrictions});

  BookingStats.fromJson(Map<String, dynamic> json) {
    monthRestrictions =
        json['month_restrictions'] != null ? RestrictionGroup.fromJson(json['month_restrictions']) : null;
    weekRestrictions = json['week_restrictions'] != null ? RestrictionGroup.fromJson(json['week_restrictions']) : null;

    _buildRestrictionSets();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (monthRestrictions != null) {
      data['month_restrictions'] = monthRestrictions!.toJson();
    }
    if (weekRestrictions != null) {
      data['week_restrictions'] = weekRestrictions!.toJson();
    }
    return data;
  }

  void _buildRestrictionSets() {
    if (monthRestrictions?.bookings?.booked != null) {
      monthRestrictions!.bookings!.booked!.entries
          .where((x) => x.value >= monthRestrictions!.bookings!.limit!)
          .forEach((element) {
        _monthFullRestrict.add(element.key);
      });
    }

    if (monthRestrictions?.days?.booked != null) {
      monthRestrictions!.days!.booked!.entries
          .where((x) => x.value >= monthRestrictions!.days!.limit!)
          .forEach((element) {
        _monthFullRestrict.add(element.key);
      });
    }
    if (weekRestrictions?.bookings?.booked != null) {
      weekRestrictions!.bookings!.booked!.entries
          .where((x) => x.value >= weekRestrictions!.bookings!.limit!)
          .forEach((element) {
        DateTime? mondayDateTime = DateTime.tryParse(element.key);
        if (mondayDateTime != null) {
          for (int i = 0; i < 7; i++) {
            _weekFullRestrict.add(_dtf.format(mondayDateTime.add(Duration(days: i))));
          }
        }
      });
    }

    if (weekRestrictions?.days?.booked != null) {
      weekRestrictions!.days!.booked!.entries
          .where((x) => x.value >= weekRestrictions!.days!.limit!)
          .forEach((element) {
        DateTime? mondayDateTime = DateTime.tryParse(element.key);
        if (mondayDateTime != null) {
          for (int i = 0; i < 7; i++) {
            _weekFullRestrict.add(_dtf.format(mondayDateTime.add(Duration(days: i))));
          }
        }
      });
    }
  }
}

class RestrictionGroup {
  Restrictions? bookings;
  Restrictions? days;

  RestrictionGroup({this.bookings, this.days});

  RestrictionGroup.fromJson(Map<String, dynamic> json) {
    bookings = json['bookings'] != null ? Restrictions.fromJson(json['bookings']) : null;
    days = json['days'] != null ? Restrictions.fromJson(json['days']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (bookings != null) {
      data['bookings'] = bookings!.toJson();
    }
    if (days != null) {
      data['days'] = days!.toJson();
    }
    return data;
  }
}

class Restrictions {
  int? limit;
  Map<String, int>? booked;

  Restrictions({this.limit, this.booked});

  Restrictions.fromJson(Map<String, dynamic> json) {
    limit = json['limit'];
    booked = json['booked'] != null ? (json['booked'] as Map<String, dynamic>).cast<String, int>() : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['limit'] = limit;
    data['booked'] = booked;
    return data;
  }
}
