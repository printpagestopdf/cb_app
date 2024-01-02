import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cb_app/parts/utils.dart';
import 'package:cb_app/wp/cb_map_list.dart';
import 'package:cb_app/wp/wp_api.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:cb_app/wp/cb_map_model.dart';
import 'package:html2md/html2md.dart' as html2md;

class LocationInfoDialog {
  final BuildContext context;
  final List<ValueNotifier<Uint8List?>> _notifiers = <ValueNotifier<Uint8List?>>[];

  Widget _getInfoBlock(String headLine, String content, String? format, TextStyle? titleStyle) {
    Widget contentWidget;

    if (!<String?>[null, "html", "text", "md"].contains(format)) return const SizedBox.shrink();

    if (format == null || format == "html") {
      content = html2md.convert(_prepareHtml(content));
    }

    if (content.replaceAll(RegExp(r'[\s\r\n ]'), '').isEmpty) return const SizedBox.shrink();

    if (format == "text") {
      contentWidget = Text(content);
    } else {
      if (Provider.of<ModelMapData>(context, listen: false).hasCorsLimitation &&
          Provider.of<ModelMapData>(context, listen: false).isLoggedIn) {
        //has CORS Limitation, but is logged in => get image by REST API
        contentWidget = MarkdownBody(
          data: content,
          onTapLink: (text, href, title) => _launchURL(href),
          imageBuilder: (uri, title, alt) {
            _notifiers.add(ValueNotifier<Uint8List?>(null));
            WpApi.getImageBinary(uri.toString(), _notifiers.last);

            return ValueListenableBuilder<Uint8List?>(
                valueListenable: _notifiers.last,
                builder: (BuildContext context, Uint8List? data, child) {
                  return data == null
                      ? const CircularProgressIndicator()
                      : Image.memory(
                          Uint8List.fromList(data),
                        );
                });
          },
        );
      } else {
        contentWidget = MarkdownBody(
          data: content,
          onTapLink: (text, href, title) => _launchURL(href),
          imageBuilder: (uri, title, alt) {
            if (Provider.of<ModelMapData>(context, listen: false).isCache) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: context.l10n.imageDisplayNotPossible,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  InkWell(
                    onTap: () {
                      _launchURL(uri.toString());
                    },
                    child: Tooltip(
                      message: context.l10n.openInNewWindow,
                      child: RichText(
                        text: TextSpan(
                          text: context.l10n.link,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                          children: const [
                            WidgetSpan(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.0),
                                child: Icon(
                                  Icons.open_in_new,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return Image.network(
              uri.toString(),
              errorBuilder: (context, error, stackTrace) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: context.l10n.imageDisplayNotPossible,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    InkWell(
                      onTap: () {
                        _launchURL(uri.toString());
                      },
                      child: Tooltip(
                        message: context.l10n.openInNewWindow,
                        child: RichText(
                          text: TextSpan(
                            text: context.l10n.link,
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                            children: const [
                              WidgetSpan(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Icon(
                                    Icons.open_in_new,
                                    size: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headLine,
                style: titleStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 4,
              ),
              contentWidget,
            ]),
      ),
    );
  }

  LocationInfoDialog.locationItem(this.context, LocationItem locationItem, bool isHorizontal) {
    showDialog(
      context: context, // navigatorKey.currentContext!,
      builder: (BuildContext context) {
        final TextStyle? titleStyle = Theme.of(context).textTheme.titleLarge?.merge(const TextStyle(
              fontWeight: FontWeight.bold,
              height: 1.0,
            ));

        return Dialog(
          insetPadding: context.dlgPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Flex(direction: Axis.vertical, children: [
            Flexible(
              fit: FlexFit.tight,
              child: SingleChildScrollView(
                child: Container(
                  constraints: MediaQuery.of(context).size.width > 600
                      ? BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        )
                      : null,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _getInfoBlock(context.l10n.shortInfo, locationItem.shortDesc ??= "", null, titleStyle),
                      _getInfoBlock(context.l10n.articleInfo, locationItem.description ??= "",
                          locationItem.descriptionFormat, titleStyle),
                      // const Divider(),
                      // const Divider(),
                      // Text(locationItem.shortDesc ??= ""),
                      // const Divider(),
                      // Text(locationItem.description ??= ""),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  LocationInfoDialog(this.context, LocationInfoInterface locationinfo, bool isHorizontal) {
    showDialog(
      context: context, // navigatorKey.currentContext!,
      builder: (BuildContext context) {
        final TextStyle? titleStyle = Theme.of(context).textTheme.titleLarge?.merge(const TextStyle(
              fontWeight: FontWeight.bold,
              height: 1.0,
            ));

        return Dialog(
          insetPadding: context.dlgPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Flex(direction: Axis.vertical, children: [
            Flexible(
              fit: FlexFit.tight,
              child: SingleChildScrollView(
                child: Container(
                  constraints: MediaQuery.of(context).size.width > 600
                      ? BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        )
                      : null,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _getInfoBlock(context.l10n.station, locationinfo.locationDescription ??= "",
                          locationinfo.locationDescriptionFormat, titleStyle),
                      _getInfoBlock(context.l10n.address, locationinfo.formattedAddressOneLine ??= "",
                          locationinfo.formattedAddressOneLineFormat, titleStyle),
                      _getInfoBlock(
                          context.l10n.pickupInstructions,
                          locationinfo.formattedPickupInstructionsOneLine ??= "",
                          locationinfo.formattedPickupInstructionsOneLineFormat,
                          titleStyle),
                      _getInfoBlock(context.l10n.contact, locationinfo.formattedContactInfoOneLine ??= "",
                          locationinfo.formattedContactInfoOneLineFormat, titleStyle),
                      _getInfoBlock(context.l10n.bookingComment, locationinfo.comment ??= "", "text", titleStyle),
                      // const Divider(),
                      // const Divider(),
                      // Text(locationinfo.formattedAddressOneLine!),
                      // const Divider(),
                      // Text(locationinfo.formattedPickupInstructionsOneLine!),
                      // const Divider(),
                      // Text(locationinfo.formattedContactInfoOneLine!),
                      // const Divider(),
                      // Text(locationinfo.locationDescription!),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  // bool _hasText(List<TextSpan> spanList) {
  //   String textOnly = "";
  //   for (TextSpan ts in spanList) {
  //     textOnly += ts.toPlainText(includePlaceholders: false, includeSemanticsLabels: false);
  //   }

  //   return textOnly.replaceAll(RegExp(r'[\n\r\t\s]*'), '').isNotEmpty;
  // }

  String _prepareHtml(String text) {
    final Pattern unicodePattern = RegExp(r'\\u([0-9A-Fa-f]{4})');
    text = text.replaceAllMapped(unicodePattern, (Match unicodeMatch) {
      final int hexCode = int.parse(unicodeMatch.group(1)!, radix: 16);
      final unicode = String.fromCharCode(hexCode);
      return unicode;
    });
    return text
        .replaceAll(RegExp(r'\\/'), '/')
        .replaceAll(RegExp(r'\\"'), '"')
        .replaceAll(RegExp(r'(\\n|\\r)'), "")
        .replaceAll(RegExp(r'\[caption.*\[/caption]'), "")
        .replaceAll(RegExp(r'<br\s*[/]?>(\n|\r\n)?'), '<br />');

    // html = html.replaceAll(RegExp(r'-->(\\n)*'), '-->');
    // html = html.replaceAll(RegExp(r'[\n\r]'), "");
  }

  // List<TextSpan> _html2text(String html) {
  //   String text = _prepareHtml(html);
  //   var fragment = html_parser.parseFragment(_prepareHtml(text));

  //   if (fragment.children.isEmpty) {
  //     //seems to be pure text
  //     text = text.replaceAll(RegExp(r'\\r\\n'), "\n");
  //     text = text.replaceAll(RegExp(r'\\n'), "\n");
  //     return <TextSpan>[
  //       TextSpan(text: text, style: Theme.of(context).textTheme.bodyMedium),
  //     ];
  //   }

  //   List<TextSpan> spanList = List<TextSpan>.empty(growable: true);
  //   _walk(fragment.nodes, spanList);
  //   return spanList;
  // }

  // void _walk(dom.NodeList nodes, List<TextSpan> spanList, [String text = ""]) {
  //   for (dom.Node node in nodes) {
  //     switch (node.nodeType) {
  //       case dom.Node.TEXT_NODE:
  //         if ((node.text ??= "").isNotEmpty) {
  //           text += node.text!;
  //         }
  //         break;

  //       case dom.Node.ELEMENT_NODE:
  //         switch ((node as dom.Element).localName) {
  //           case "br":
  //             text += "\n";
  //             break;
  //           case "p":
  //             if (text.isNotEmpty) {
  //               spanList.add(TextSpan(text: text, style: Theme.of(context).textTheme.bodyMedium));
  //               text = "";
  //             }
  //             spanList.add(TextSpan(text: "\n", style: Theme.of(context).textTheme.bodyMedium));
  //             _walk(node.nodes, spanList, text);
  //             spanList.add(TextSpan(text: "\n", style: Theme.of(context).textTheme.bodyMedium));
  //             break;
  //           case "b":
  //           case "strong":
  //             if (text.isNotEmpty) {
  //               spanList.add(TextSpan(text: text, style: Theme.of(context).textTheme.bodyMedium));
  //               text = "";
  //             }
  //             spanList.add(
  //               TextSpan(
  //                 text: node.text,
  //                 style: Theme.of(context).textTheme.bodyMedium!.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //               ),
  //             );
  //             break;
  //           case "i":
  //             if (text.isNotEmpty) {
  //               spanList.add(TextSpan(text: text, style: Theme.of(context).textTheme.bodyMedium));
  //               text = "";
  //             }
  //             spanList.add(TextSpan(
  //               text: node.text,
  //               style: Theme.of(context).textTheme.bodyMedium!.copyWith(
  //                     fontStyle: FontStyle.italic,
  //                   ),
  //             ));
  //             break;
  //           case "u":
  //             if (text.isNotEmpty) {
  //               spanList.add(TextSpan(text: text, style: Theme.of(context).textTheme.bodyMedium));
  //               text = "";
  //             }
  //             spanList.add(TextSpan(
  //               text: node.text,
  //               style: Theme.of(context).textTheme.bodyMedium!.copyWith(
  //                     decoration: TextDecoration.underline,
  //                   ),
  //             ));
  //             break;
  //           case "a":
  //             if (text.isNotEmpty) {
  //               spanList.add(TextSpan(text: text, style: Theme.of(context).textTheme.bodyMedium));
  //               text = "";
  //             }
  //             spanList.add(TextSpan(
  //               text: node.text,
  //               style: Theme.of(context).textTheme.bodyMedium!.copyWith(
  //                     color: Colors.blue,
  //                     decoration: TextDecoration.underline,
  //                   ),
  //               recognizer: (() {
  //                 TapGestureRecognizer t = TapGestureRecognizer();
  //                 _tapGestureRecognizers.add(t);
  //                 return t..onTap = () => _launchURL(node.attributes['href']);
  //               })(),
  //             ));
  //             break;
  //           default:
  //             if (node.hasChildNodes()) {
  //               if (text.isNotEmpty) {
  //                 spanList.add(TextSpan(text: text, style: Theme.of(context).textTheme.bodyMedium));
  //                 text = "";
  //               }
  //               _walk(node.nodes, spanList, text);
  //             }
  //             break;
  //         }
  //         break;
  //       default:
  //         break;
  //     }
  //   }

  //   if (text.isNotEmpty) {
  //     spanList.add(TextSpan(text: text, style: Theme.of(context).textTheme.bodyMedium));
  //   }
  // }

  void _launchURL(String? strUrl) async {
    if (strUrl == null) return;
    Uri? url = Uri.tryParse(strUrl);
    if (url == null) return;

    await launchUrl(url);
  }
}
