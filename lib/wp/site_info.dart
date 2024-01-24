// ignore_for_file: unnecessary_this, depend_on_referenced_packages
import 'package:collection/collection.dart';

class SiteInfo {
  String? name;
  String? description;
  String? url;
  String? home;
  int? gmtOffset;
  String? timezoneString;
  List<String>? namespaces;
  List<String>? routes;
  Authentication? authentication;
  int? siteLogo;
  int? siteIcon;
  String? siteIconUrl;
  Links? lLinks;
  Embedded? eEmbedded;

  SiteInfo(
      {this.name,
      this.description,
      this.url,
      this.home,
      this.gmtOffset,
      this.timezoneString,
      this.namespaces,
      this.routes,
      this.authentication,
      this.siteLogo,
      this.siteIcon,
      this.siteIconUrl,
      this.lLinks,
      this.eEmbedded});

  Medium? get siteIconMedia {
    Medium? retVal;
    if (eEmbedded == null || eEmbedded?.wpFeaturedmedia == null) return null;

    final WpFeaturedmedia? featuredmedia =
        eEmbedded?.wpFeaturedmedia?.firstWhereOrNull((element) => element.id == siteIcon);

    if (featuredmedia?.mediaDetails?.sizes?.mediaSizes == null) return null;
    featuredmedia?.mediaDetails?.sizes?.mediaSizes!.forEach((key, value) {
      if (retVal == null || value!.width! < retVal!.width!) retVal = value;
    });

    return retVal;
  }

  SiteInfo.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    url = json['url'];
    home = json['home'];
    gmtOffset = (json['gmt_offset'] is String) ? int.tryParse(json['gmt_offset']) : json['gmt_offset'];
    timezoneString = json['timezone_string'];
    namespaces = json['namespaces'].cast<String>();
    authentication = json['authentication'] != null && json['authentication'] is Map<String, dynamic>
        ? Authentication.fromJson(json['authentication'])
        : null;
    siteLogo = json['site_logo'];
    siteIcon = json['site_icon'];
    siteIconUrl = json['site_icon_url'];
    lLinks = json['_links'] != null ? Links.fromJson(json['_links']) : null;
    eEmbedded = json['_embedded'] != null ? Embedded.fromJson(json['_embedded']) : null;
    routes = json['routes']?.keys.toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = this.name;
    data['description'] = this.description;
    data['url'] = this.url;
    data['home'] = this.home;
    data['gmt_offset'] = this.gmtOffset;
    data['timezone_string'] = this.timezoneString;
    data['namespaces'] = this.namespaces;
    if (this.authentication != null) {
      data['authentication'] = this.authentication!.toJson();
    }
    data['site_logo'] = this.siteLogo;
    data['site_icon'] = this.siteIcon;
    data['site_icon_url'] = this.siteIconUrl;
    if (this.lLinks != null) {
      data['_links'] = this.lLinks!.toJson();
    }
    return data;
  }
}

class Authentication {
  // ApplicationPasswords? applicationPasswords;
  Map<String, dynamic>? authentications;

  Authentication({this.authentications});

  Authentication.fromJson(Map<String, dynamic> json) {
    authentications = json.map((key, value) => MapEntry(key, value));
    // applicationPasswords =
    //     json['application-passwords'] != null ? ApplicationPasswords.fromJson(json['application-passwords']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.authentications != null) {
      data['application-passwords'] = {};
      // this.authentications!.toJson();
    }
    return data;
  }
}

class ApplicationPasswords {
  Endpoints? endpoints;

  ApplicationPasswords({this.endpoints});

  ApplicationPasswords.fromJson(Map<String, dynamic> json) {
    endpoints = json['endpoints'] != null ? Endpoints.fromJson(json['endpoints']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.endpoints != null) {
      data['endpoints'] = this.endpoints!.toJson();
    }
    return data;
  }
}

class Endpoints {
  String? authorization;

  Endpoints({this.authorization});

  Endpoints.fromJson(Map<String, dynamic> json) {
    authorization = json['authorization'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['authorization'] = this.authorization;
    return data;
  }
}

class Links {
  List<Help>? help;
  List<WpFeaturedmedia>? wpFeaturedmedia;
  List<Curies>? curies;

  Links({this.help, this.wpFeaturedmedia, this.curies});

  Links.fromJson(Map<String, dynamic> json) {
    if (json['help'] != null) {
      help = <Help>[];
      json['help'].forEach((v) {
        help!.add(Help.fromJson(v));
      });
    }
    if (json['wp:featuredmedia'] != null) {
      wpFeaturedmedia = <WpFeaturedmedia>[];
      json['wp:featuredmedia'].forEach((v) {
        wpFeaturedmedia!.add(WpFeaturedmedia.fromJson(v));
      });
    }
    if (json['curies'] != null) {
      curies = <Curies>[];
      json['curies'].forEach((v) {
        curies!.add(Curies.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.help != null) {
      data['help'] = this.help!.map((v) => v.toJson()).toList();
    }
    if (this.wpFeaturedmedia != null) {
      data['wp:featuredmedia'] = this.wpFeaturedmedia!.map((v) => v.toJson()).toList();
    }
    if (this.curies != null) {
      data['curies'] = this.curies!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Help {
  String? href;

  Help({this.href});

  Help.fromJson(Map<String, dynamic> json) {
    href = json['href'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['href'] = this.href;
    return data;
  }
}

// class WpFeaturedmedia {
//   bool? embeddable;
//   String? type;
//   String? href;

//   WpFeaturedmedia({this.embeddable, this.type, this.href});

//   WpFeaturedmedia.fromJson(Map<String, dynamic> json) {
//     embeddable = json['embeddable'];
//     type = json['type'];
//     href = json['href'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['embeddable'] = this.embeddable;
//     data['type'] = this.type;
//     data['href'] = this.href;
//     return data;
//   }
// }

class Curies {
  String? name;
  String? href;
  bool? templated;

  Curies({this.name, this.href, this.templated});

  Curies.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    href = json['href'];
    templated = json['templated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = this.name;
    data['href'] = this.href;
    data['templated'] = this.templated;
    return data;
  }
}

class Embedded {
  List<WpFeaturedmedia>? wpFeaturedmedia;

  Embedded({this.wpFeaturedmedia});

  Embedded.fromJson(Map<String, dynamic> json) {
    if (json['wp:featuredmedia'] != null) {
      wpFeaturedmedia = <WpFeaturedmedia>[];
      json['wp:featuredmedia'].forEach((v) {
        wpFeaturedmedia!.add(WpFeaturedmedia.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.wpFeaturedmedia != null) {
      data['wp:featuredmedia'] = this.wpFeaturedmedia!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class WpFeaturedmedia {
  int? id;
  String? date;
  String? slug;
  String? type;
  String? link;
  Title? title;
  int? author;
  Title? caption;
  String? altText;
  String? mediaType;
  String? mimeType;
  MediaDetails? mediaDetails;
  String? sourceUrl;

  WpFeaturedmedia(
      {this.id,
      this.date,
      this.slug,
      this.type,
      this.link,
      this.title,
      this.author,
      this.caption,
      this.altText,
      this.mediaType,
      this.mimeType,
      this.mediaDetails,
      this.sourceUrl});

  WpFeaturedmedia.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    date = json['date'];
    slug = json['slug'];
    type = json['type'];
    link = json['link'];
    title = json['title'] != null ? Title.fromJson(json['title']) : null;
    author = json['author'];
    caption = json['caption'] != null ? Title.fromJson(json['caption']) : null;
    altText = json['alt_text'];
    mediaType = json['media_type'];
    mimeType = json['mime_type'];
    mediaDetails = json['media_details'] != null ? MediaDetails.fromJson(json['media_details']) : null;
    sourceUrl = json['source_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = this.id;
    data['date'] = this.date;
    data['slug'] = this.slug;
    data['type'] = this.type;
    data['link'] = this.link;
    if (this.title != null) {
      data['title'] = this.title!.toJson();
    }
    data['author'] = this.author;
    if (this.caption != null) {
      data['caption'] = this.caption!.toJson();
    }
    data['alt_text'] = this.altText;
    data['media_type'] = this.mediaType;
    data['mime_type'] = this.mimeType;
    if (this.mediaDetails != null) {
      data['media_details'] = this.mediaDetails!.toJson();
    }
    data['source_url'] = this.sourceUrl;
    return data;
  }
}

class Title {
  String? rendered;

  Title({this.rendered});

  Title.fromJson(Map<String, dynamic> json) {
    rendered = json['rendered'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rendered'] = this.rendered;
    return data;
  }
}

class MediaDetails {
  int? width;
  int? height;
  String? file;
  Sizes? sizes;

  MediaDetails({this.width, this.height, this.file, this.sizes});

  MediaDetails.fromJson(Map<String, dynamic> json) {
    width = json['width'];
    height = json['height'];
    file = json['file'];
    sizes = json['sizes'] != null ? Sizes.fromJson(json['sizes']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['width'] = this.width;
    data['height'] = this.height;
    data['file'] = this.file;
    if (this.sizes != null) {
      data['sizes'] = this.sizes!.toJson();
    }
    return data;
  }
}

// class Sizes {
//   Medium? medium;
//   Medium? large;
//   Medium? full;

//   Sizes({this.medium, this.large, this.full});

//   Sizes.fromJson(Map<String, dynamic> json) {
//     medium = json['medium'] != null ? Medium.fromJson(json['medium']) : null;
//     large = json['large'] != null ? Medium.fromJson(json['large']) : null;
//     full = json['full'] != null ? Medium.fromJson(json['full']) : null;
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     if (this.medium != null) {
//       data['medium'] = this.medium!.toJson();
//     }
//     if (this.large != null) {
//       data['large'] = this.large!.toJson();
//     }
//     if (this.full != null) {
//       data['full'] = this.full!.toJson();
//     }
//     return data;
//   }
// }

class Sizes {
  Map<String, Medium?>? mediaSizes;

  Sizes({
    this.mediaSizes,
  });

  Sizes.fromJson(Map<String, dynamic> json) {
    mediaSizes = json.map((key, value) => MapEntry(key, Medium.fromJson(value)));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    mediaSizes?.forEach((key, value) {
      data[key] = value!.toJson();
    });
    return data;
  }
}

class Medium {
  String? file;
  int? width;
  int? height;
  String? mimeType;
  String? sourceUrl;

  Medium({this.file, this.width, this.height, this.mimeType, this.sourceUrl});

  Medium.fromJson(Map<String, dynamic> json) {
    file = json['file'];
    width = _tryInt(json['width']);
    height = _tryInt(json['height']);
    mimeType = json['mime_type'];
    sourceUrl = json['source_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['file'] = this.file;
    data['width'] = this.width;
    data['height'] = this.height;
    data['mime_type'] = this.mimeType;
    data['source_url'] = this.sourceUrl;
    return data;
  }

  int? _tryInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
