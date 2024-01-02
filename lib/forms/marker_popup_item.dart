import 'package:cb_app/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cb_app/wp/wp_api.dart';
import 'package:cb_app/parts/utils.dart';
import 'package:cb_app/forms/location_info_dialog.dart';
import 'package:cb_app/wp/cb_map_model.dart';
import 'package:cb_app/forms/overview_calendar.dart';
import 'package:cb_app/wp/cb_map_list.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';

class MarkerPopupItem extends StatelessWidget {
  final LocationItem item;
  final String locationId;

  const MarkerPopupItem(this.item, this.locationId, {super.key});

  @override
  Widget build(BuildContext context) {
    return /*Card(
      child: */
        Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                left: 15,
                right: 0,
                top: 5,
                bottom: 5,
              ),
              child: InkWell(
                onTap: (item.shortDesc == null && item.description == null)
                    ? null
                    : () {
                        LocationInfoDialog.locationItem(context, item, true);
                      },
                child: SizedBox(
                  width: 75,
                  height: 75,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image(
                      image: FastCachedImageProvider(WpApi.getItemThumbnailUrl(item)),
                      errorBuilder: (context, exception, stacktrace) {
                        return Tooltip(
                          message: context.l10n.imageDisplayNotPossible,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1)),
                            child: const Icon(Icons.image_not_supported_outlined),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.indigoAccent,
                          ),
                        );
                      },
                      height: 75.0,
                      width: 75.0,
                      filterQuality: FilterQuality.medium,
                      fit: BoxFit.cover,
                      // fadeInDuration: const Duration(milliseconds: 200),
                    ),
                  ),
                ),
              ),
            ),
            //),
            _cardDescription(context),
          ],
          //),
        ),
      ],
    );
  }

  Widget _cardDescription(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, top: 0),
      child: /*Container(
        // constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
        child:*/
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: (item.shortDesc == null && item.description == null)
                ? null
                : () {
                    LocationInfoDialog.locationItem(context, item, true);
                  },
            child: SizedBox(
                width: 200,
                child: RichText(
                  softWrap: true,
                  text: TextSpan(
                    children: [
                      if (item.shortDesc != null || item.description != null)
                        const WidgetSpan(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: 3,
                            ),
                            child: Icon(
                              Icons.info_outline,
                              size: 17,
                            ),
                          ),
                        ),
                      TextSpan(
                        text: item.name,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                )),
          ),
          const Padding(padding: EdgeInsets.only(top: 5.0)),
          InkWell(
            onTap: () {
              ModelMapData().setCurrent(locationId: locationId, itemId: item.id.toString());
              CBApp.cbAppKey.currentState!.openEndDrawer();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OverviewCalendar(locationId, item.id.toString()),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  (Provider.of<ModelMapData>(context, listen: false).isLoggedIn)
                      ? context.l10n.openBookingCalendar
                      : context.l10n.calendar,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      //),
    );
  }
}
