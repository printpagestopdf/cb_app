import 'package:intl/intl.dart';
import 'package:cb_app/wp/cb_map_model.dart';
import 'package:flutter/material.dart';
import 'package:cb_app/forms/register_host.dart';
import 'package:cb_app/parts/utils.dart';
import 'dart:math';
// import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage> with TickerProviderStateMixin {
  late TabController tabController;
  String? currentHostKey;
  String? currentUserKey;
  final GlobalKey<FormFieldState<bool>> _switchCacheEnabledKey = GlobalKey<FormFieldState<bool>>();
  final GlobalKey<FormFieldState<bool>> _switchShowZoomKey = GlobalKey<FormFieldState<bool>>();
  final GlobalKey<FormFieldState<double>> _sliderMarkerSizeKey = GlobalKey<FormFieldState<double>>();
  final selectedColor = Colors.red;
  static const double formFieldSpacing = 5.0;
  int currentTab = 0;
  final GlobalKey<FormState> _hostFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _userFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _settingsFormKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState> _hostDropdownKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _userDropdownKey = GlobalKey<FormFieldState>();
  bool _settingsFormModified = false;
  bool _hostFormModified = false;
  bool _userFormModified = false;
  bool _initEnableOfflineHost = true;
  bool _initShowZoom = false;
  late ModelMapData modelMap;
  double _sliderMarkerSize = 16.0;

  final FormItemControllers<TextEditingController> _txtControllers =
      FormItemControllers<TextEditingController>(() => TextEditingController());

  final double _timeoutSliderMax = 300;

  double __timeoutSlider = 0;
  double get _timeoutSlider => __timeoutSlider;
  set _timeoutSlider(dynamic value) {
    if (value is String) {
      __timeoutSlider = min((double.tryParse(value) ?? _timeoutSliderMax), _timeoutSliderMax);
    } else if (value is int) {
      __timeoutSlider = min(value.toDouble(), _timeoutSliderMax);
    } else if (value is double) {
      __timeoutSlider = min(value, _timeoutSliderMax);
    } else {
      __timeoutSlider = _timeoutSliderMax;
    }
  }

  void goTo(int index) {
    tabController.animateTo(index);
    setState(() {
      currentTab = index;
    });
  }

  void _findCurrentHostKey() {
    if (currentHostKey != null) return;

    if (modelMap.currentHost.isNotEmpty) {
      currentHostKey = modelMap.currentHost;
    } else if (modelMap.settings.hostList.isNotEmpty) {
      currentHostKey = modelMap.settings.hostList.keys.first;
    } else {
      currentHostKey = null;
    }
  }

  void _findCurrentUserKey() {
    if (currentHostKey == null) {
      currentUserKey = null;
      return;
    }

    if (currentUserKey != null) return;
    if (modelMap.settings.hostList[currentHostKey]['users'] != null &&
        (modelMap.settings.hostList[currentHostKey]['users'] as Map<dynamic, dynamic>).isNotEmpty) {
      currentUserKey = (modelMap.settings.hostList[currentHostKey]['users'] as Map<dynamic, dynamic>).keys.first;
    } else {
      currentUserKey = null;
    }
  }

  void updateCurrentHostDefaults({String? hostKey, String? userKey}) {
    currentHostKey = hostKey ?? currentHostKey;
    _findCurrentHostKey();

    if (hostKey != null) {
      currentUserKey = null;
    } else {
      currentUserKey = userKey ?? currentUserKey;
    }
    _findCurrentUserKey();

    String hostTitle = "";
    String hostUrl = "";
    String userLogin = "";
    String userName = "";

    if (currentHostKey != null) {
      hostTitle = modelMap.settings.hostList[currentHostKey]['title'];
      hostUrl = modelMap.settings.urlFromHostKey(currentHostKey);

      if (currentUserKey != null) {
        userLogin = modelMap.settings.hostList[currentHostKey]['users'][currentUserKey]['login'];
        userName = modelMap.settings.hostList[currentHostKey]['users'][currentUserKey]['name'];
      }
    }

    _initEnableOfflineHost = (modelMap.settings.hostList[currentHostKey]?['cacheEnabled'] as bool?) ?? true;

    _txtControllers.ctrl("hostTitle").text = hostTitle;
    _txtControllers.ctrl("hostUrl").text = hostUrl;

    _txtControllers.ctrl("userLogin").text = userLogin;
    _txtControllers.ctrl("userName").text = userName;

    _hostFormModified = false;
    _userFormModified = false;
  }

  void updateCurrentSettingDefaults() {
    int? timeoutSetting = modelMap.settings.getSetting("netTimeout");

    if (timeoutSetting == null) {
      _txtControllers.ctrl("netTimeout").text = ""; // "(${context.l10n.unlimited})";
      _timeoutSlider = _timeoutSliderMax;
    } else {
      _txtControllers.ctrl("netTimeout").text = timeoutSetting.toString();
      _timeoutSlider = timeoutSetting;
    }

    _initShowZoom = modelMap.showZoom;

    _sliderMarkerSize = modelMap.markerIconSize;

    _settingsFormModified = false;
  }

  @override
  void dispose() {
    super.dispose();
    _txtControllers.dispose();
  }

  @override
  void initState() {
    super.initState();
    modelMap = Provider.of<ModelMapData>(context, listen: false);

    tabController = TabController(length: 2 /* 3 */, vsync: this);
    currentTab = 0;

    updateCurrentSettingDefaults();
    updateCurrentHostDefaults();
  }

  @override
  Widget build(BuildContext context) {
    if (_txtControllers.ctrl("netTimeout").text.isEmpty) {
      _txtControllers.ctrl("netTimeout").text = "(${context.l10n.unlimited})";
    }

    return Scaffold(
      appBar: AppBar(
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? BackButton(
                onPressed: () async {
                  if (_hostFormModified || _userFormModified || _settingsFormModified) {
                    if (await yesNoDialog(context, context.l10n.msgDataModified, context.l10n.questStillContinue)) {
                      if (context.mounted) Navigator.maybePop(context);
                    } else {
                      if (_settingsFormModified) {
                        goTo(0);
                      } else if (_hostFormModified || _userFormModified) {
                        goTo(1);
                      }
                    }
                  } else {
                    if (context.mounted) Navigator.maybePop(context);
                  }
                },
              )
            : null,
        title: context.isMobile
            ? const SizedBox.shrink()
            : Text(
                context.l10n.settings,
                textAlign: TextAlign.center,
              ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSecondary, // Text Color
            ),
            onPressed: () => goTo(0),
            child: Container(
              padding: const EdgeInsets.only(
                bottom: 3,
              ),
              decoration: currentTab == 0
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2.0,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  Tooltip(
                    message: "${context.l10n.common}",
                    child: const Icon(Icons.settings),
                  ),
                  if (!context.isMobile)
                    Text(
                      " ${context.l10n.common}",
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSecondary, // Text Color
            ),
            onPressed: () => goTo(1),
            child: Container(
              padding: const EdgeInsets.only(
                bottom: 3,
              ),
              decoration: currentTab == 1
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2.0,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  Tooltip(
                    message: "${context.l10n.serviceprovider}",
                    child: const Icon(Icons.public_outlined),
                  ),
                  if (!context.isMobile)
                    Text(
                      " ${context.l10n.serviceprovider}",
                    ),
                ],
              ),
            ),
          ),
          // TextButton(
          //   style: TextButton.styleFrom(
          //     foregroundColor: Theme.of(context).colorScheme.onSecondary, // Text Color
          //   ),
          //   onPressed: () => goTo(2),
          //   child: Container(
          //     padding: const EdgeInsets.only(
          //       bottom: 3,
          //     ),
          //     decoration: currentTab == 2
          //         ? BoxDecoration(
          //             border: Border(
          //               bottom: BorderSide(
          //                 width: 2.0,
          //                 color: Theme.of(context).colorScheme.onSecondary,
          //               ),
          //             ),
          //           )
          //         : null,
          //     child: Row(
          //       children: [
          //         const Tooltip(
          //           message: 'Info',
          //           child: Icon(Icons.info_outline),
          //         ),
          //         if (!context.isMobile)
          //           const Text(
          //             ' Info',
          //           ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: <Widget>[
          SingleChildScrollView(
            child: _settingsForm(),
          ),
          SingleChildScrollView(
            child: _hostsForm(),
          ),
          // SingleChildScrollView(
          //   child: _infoTab(),
          // ),
        ],
      ),
    );
  }

  Widget _settingsForm() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double margin =
            switch (constraints.maxWidth) { (< 350) => 5, (< 600) => 10, _ => (constraints.maxWidth - 600) / 2 };

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: margin, vertical: 10),
          child: Column(
            children: [
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Form(
                    onChanged: () {
                      if (!_settingsFormModified) {
                        setState(() {
                          _settingsFormModified = true;
                        });
                      }
                    },
                    key: _settingsFormKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text(
                            context.l10n.common,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        //),
                        const SizedBox(height: formFieldSpacing),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                              labelText: context.l10n.hdrStartupAction,
                              prefixIcon: const Icon(Icons.power_settings_new_outlined)),
                          value: modelMap.startupAction,
                          items: <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: "last",
                              child: Text(
                                context.l10n.optStartupAction("last"),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem<String>(
                              value: "last_offline",
                              child: Text(
                                context.l10n.optStartupAction("last_offline"),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem<String>(
                              value: "none",
                              child: Text(
                                context.l10n.optStartupAction("none"),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (locale) {},
                          onSaved: (newValue) {
                            modelMap.startupAction = newValue ?? "last";
                          },
                        ),
                        const SizedBox(height: formFieldSpacing),
                        DropdownButtonFormField<Locale>(
                          decoration: InputDecoration(
                              labelText: toBeginningOfSentenceCase(context.l10n.select(context.l10n.language)),
                              prefixIcon: const Icon(Icons.language)),
                          value: modelMap.currentLocale,
                          items: <DropdownMenuItem<Locale>>[
                            DropdownMenuItem<Locale>(
                              value: const Locale("de", "DE"),
                              child: Text(context.l10n.german),
                            ),
                            DropdownMenuItem<Locale>(
                              value: const Locale("en", "US"),
                              child: Text(context.l10n.english),
                            ),
                          ],
                          onChanged: (locale) {},
                          onSaved: (newValue) {
                            modelMap.currentLocale = newValue ?? const Locale("de", "DE");
                          },
                        ),
                        const SizedBox(height: formFieldSpacing),
                        InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.zoom_in_outlined),
                          ),
                          child: FormField(
                            key: _switchShowZoomKey,
                            initialValue: _initShowZoom,
                            builder: (FormFieldState<bool> field) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Switch.adaptive(
                                    value: _initShowZoom, // field.value!,
                                    onChanged: (val) {
                                      _initShowZoom = val;
                                      field.didChange(val);
                                    },
                                  ),
                                  Flexible(
                                    child: Text(
                                      context.l10n.showZoomButtons,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              );
                            },
                            onSaved: (newValue) {
                              modelMap.showZoom = _switchShowZoomKey.currentState!.value ?? false;
                            },
                          ),
                        ),
                        const SizedBox(height: formFieldSpacing),

                        InputDecorator(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.zoom_out_map),
                            labelText: context.l10n.lblMarkerSize,
                            suffixIcon: IconButton(
                              color: Theme.of(context).colorScheme.tertiary,
                              padding: const EdgeInsets.only(top: 15),
                              tooltip: context.l10n.ttResetMarkerSize,
                              onPressed: () {
                                _sliderMarkerSize = 24.00;
                                _sliderMarkerSizeKey.currentState!.didChange(24.0);
                              },
                              icon: const Icon(Icons.undo),
                            ),
                          ),
                          child: FormField<double>(
                            key: _sliderMarkerSizeKey,
                            initialValue: _sliderMarkerSize,
                            builder: (FormFieldState<double> field) {
                              return SliderTheme(
                                data: Theme.of(context).sliderTheme.copyWith(
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                      trackHeight: 4,
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                    ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  // color: Theme.of(context).inputDecorationTheme.fillColor,
                                  children: [
                                    SizedBox(
                                      width: _sliderMarkerSize,
                                      height: _sliderMarkerSize,
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color.fromRGBO(32, 70, 130, 1),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(Icons.pedal_bike_outlined,
                                            size: _sliderMarkerSize - 8, color: Colors.white.withOpacity(0.75)),
                                      ),
                                    ),
                                    Expanded(
                                      child: Slider(
                                        value: _sliderMarkerSize,
                                        min: 10,
                                        max: 50,
                                        divisions: 40,
                                        label: _sliderMarkerSize.round().toString(),
                                        onChanged: (double value) {
                                          _sliderMarkerSize = value;
                                          field.didChange(value);
                                          // setState(() {
                                          //   _sliderMarkerSize = value;
                                          // });
                                        },
                                      ),
                                    ),
                                    Badge.count(
                                      count: _sliderMarkerSize.round(),
                                      textColor: Theme.of(context).textTheme.labelMedium!.color,
                                      backgroundColor: Theme.of(context).cardColor,
                                    ),
                                  ],
                                ),
                              );
                            },
                            onSaved: (newValue) {
                              if (newValue != null) {
                                modelMap.markerIconSize = newValue;
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: formFieldSpacing),
                        TextFormField(
                          controller: _txtControllers.ctrl("netTimeout")
                            ..addListener(() {
                              if (_txtControllers.ctrl("netTimeout").text.isEmpty) {
                                _txtControllers.ctrl("netTimeout").text = "(${context.l10n.unlimited})";
                                setState(() {
                                  _timeoutSlider = _timeoutSliderMax;
                                });
                              }
                            }),
                          textAlign: TextAlign.end,
                          onEditingComplete: () {
                            setState(() {
                              _timeoutSlider = _txtControllers.ctrl("netTimeout").text;
                            });
                          },
                          keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: context.l10n.netTimeoutInSeconds,
                            prefixIcon: const Icon(Icons.access_time_outlined),
                            // isDense: true,
                            suffixText: (int.tryParse(_txtControllers.ctrl("netTimeout").text) != null)
                                ? context.l10n.seconds
                                : '',
                            suffixIcon: IconButton(
                              color: Theme.of(context).colorScheme.tertiary,
                              padding: const EdgeInsets.only(top: 15),
                              tooltip: context.l10n.setTimeoutUnlimited,
                              onPressed: () async {
                                FocusScope.of(context).unfocus();

                                _txtControllers.ctrl("netTimeout").text = "(${context.l10n.unlimited})";
                                setState(() {
                                  _timeoutSlider = _timeoutSliderMax;
                                });
                              },
                              icon: const Icon(Icons.all_inclusive_outlined),
                            ),
                          ),
                          onSaved: (newValue) {
                            // modelMap.settings.putSetting("netTimeout", int.tryParse(newValue ?? ''));
                            modelMap.updateNetworkTimeout(newValue);
                          },
                        ),
                        SliderTheme(
                          data: Theme.of(context).sliderTheme.copyWith(
                                trackShape: const RectangularSliderTrackShape(),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                trackHeight: 2,
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                showValueIndicator: ShowValueIndicator.never,
                              ),
                          child: Container(
                            color: Theme.of(context).inputDecorationTheme.fillColor,
                            child: Slider(
                              value: _timeoutSlider,
                              min: 0,
                              max: _timeoutSliderMax,
                              divisions: _timeoutSliderMax.toInt(),
                              // label: _timeoutSlider.toString(),
                              onChanged: (value) {
                                _txtControllers.ctrl("netTimeout").text = value.toInt().toString();
                                setState(() {
                                  _timeoutSlider = value.toInt().toDouble();
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: formFieldSpacing),
                        TextFormField(
                          initialValue: modelMap.settings.getSetting("connectionTestUrl", "https://1.1.1.1/"),
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: context.l10n.linkForInternettest,
                            prefixIcon: const Icon(Icons.link),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.l10n.addValidLink;
                            }
                            Uri? parsed = Uri.tryParse(value);
                            if (parsed == null ||
                                parsed.host.isEmpty ||
                                (parsed.scheme != "http" && parsed.scheme != "https")) {
                              return context.l10n.addValidLink;
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            modelMap.settings.putSetting("connectionTestUrl", newValue);
                          },
                        ),

                        const SizedBox(height: formFieldSpacing),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            TextButton.icon(
                              onPressed: _settingsFormModified
                                  ? () {
                                      if (_settingsFormKey.currentState!.validate()) {
                                        _settingsFormKey.currentState!.save();
                                        setState(() {
                                          _settingsFormModified = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(context.l10n.savedSuccessfully),
                                        ));
                                      }
                                    }
                                  : null,
                              icon: const Icon(
                                Icons.save_outlined,
                                size: 16,
                              ),
                              label: Text(
                                context.l10n.save,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _hostsForm() {
    Map<dynamic, dynamic> formUserDataMap = <dynamic, dynamic>{};

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      double margin =
          switch (constraints.maxWidth) { (< 350) => 5, (< 600) => 10, _ => (constraints.maxWidth - 600) / 2 };

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: margin, vertical: 10),
        child: Column(
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        toBeginningOfSentenceCase(context.l10n.edit(context.l10n.service))!,
                        //'Service bearbeiten',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      key: _hostDropdownKey,
                      decoration: InputDecoration(
                          labelText: context.l10n.select(context.l10n.service),
                          prefixIcon: const Icon(Icons.cloud_done_outlined)),
                      value: currentHostKey,
                      items: _hostItems(),
                      onChanged: (host) async {
                        if (host == currentHostKey) return;
                        if (_hostFormModified == true || _userFormModified == true) {
                          if (!await yesNoDialog(
                              context, context.l10n.msgDataModified, context.l10n.questStillContinue)) {
                            _hostDropdownKey.currentState!.reset();
                            return;
                          }
                        }
                        if (host != null) {
                          setState(() {
                            updateCurrentHostDefaults(hostKey: host);
                            _hostFormModified = false;
                            _userFormModified = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: formFieldSpacing),
                    Form(
                      onChanged: () {
                        if (!_hostFormModified) {
                          setState(() {
                            _hostFormModified = true;
                          });
                        }
                      },
                      key: _hostFormKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _txtControllers.ctrl("hostUrl"),
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: 'Url',
                              prefixIcon: const Icon(Icons.link),
                              suffixIcon: IconButton(
                                color: Theme.of(context).colorScheme.tertiary,
                                tooltip: context.l10n.netwokTest,
                                onPressed: () {
                                  FocusScope.of(context).unfocus();

                                  showDialog<Map<String, String>>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          insetPadding: context.dlgPadding,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10.0),
                                          ),
                                          child: RegisterHost(
                                            initialTab: ActiveTab.infoTab,
                                            params: {
                                              "testUrl": _txtControllers.ctrl("hostUrl").text,
                                              "hideBackButton": true,
                                            },
                                          ),
                                        );
                                      });
                                },
                                icon: const Icon(Icons.network_check),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.l10n.addValidLink;
                              }
                              Uri? parsed = Uri.tryParse(value);
                              if (parsed == null ||
                                  parsed.host.isEmpty ||
                                  (parsed.scheme != "http" && parsed.scheme != "https")) {
                                return context.l10n.addValidLink;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: formFieldSpacing),
                          TextFormField(
                            controller: _txtControllers.ctrl("hostTitle"),
                            decoration: InputDecoration(
                              labelText: context.l10n.displayName,
                              prefixIcon: const Icon(Icons.title_outlined),
                            ),
                          ),
                          const SizedBox(height: formFieldSpacing),
                          InputDecorator(
                            decoration: const InputDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    FormField(
                                      key: _switchCacheEnabledKey,
                                      initialValue: _initEnableOfflineHost,
                                      builder: (FormFieldState<bool> field) {
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Switch.adaptive(
                                              value: _initEnableOfflineHost, // field.value!,
                                              onChanged: (val) {
                                                _initEnableOfflineHost = val;
                                                field.didChange(val);
                                              },
                                            ),
                                            Text(context.l10n.enableOfflineUse(_initEnableOfflineHost.toString())),
                                          ],
                                        );
                                      },
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            onPressed: () async {
                                              if (await yesNoDialog(context, context.l10n.delete,
                                                  context.l10n.askForDeletion(context.l10n.data))) {
                                                modelMap.clearCache(currentHostKey);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(context.l10n.msgCacheDeleted)));
                                                }
                                              }
                                            },
                                            icon: const Icon(Icons.delete_outline)),
                                        Text(context.l10n.deleteOfflineData),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: formFieldSpacing),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed: currentHostKey != null
                                      ? () async {
                                          if (await yesNoDialog(
                                              context, context.l10n.delete, context.l10n.askForDeletion("Service"))) {
                                            if (modelMap.deleteHost(currentHostKey!)) {
                                              setState(() {
                                                currentUserKey = currentHostKey = null;
                                                updateCurrentHostDefaults();
                                              });
                                            }
                                          }
                                        }
                                      : null,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                  ),
                                  label: Text(context.l10n.delete),
                                ),
                                TextButton.icon(
                                    onPressed: currentHostKey != null
                                        ? () async {
                                            Map<String, String>? result = await showDialog<Map<String, String>>(
                                              context: context, // navigatorKey.currentContext!,
                                              builder: (BuildContext context) {
                                                return Dialog(
                                                  insetPadding: context.dlgPadding,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10.0),
                                                  ),
                                                  child: RegisterHost(
                                                    initialTab: ActiveTab.hostTab,
                                                  ),
                                                );
                                              },
                                            );
                                            if (result != null) {
                                              setState(() {
                                                if (result['newHostKey'] != null) {
                                                  updateCurrentHostDefaults(hostKey: result['newHostKey']);
                                                }
                                              });
                                            }
                                          }
                                        : null,
                                    icon: const Icon(
                                      Icons.cloud_done_outlined,
                                      size: 16,
                                    ),
                                    label: Text(context.l10n.newText)),
                                TextButton.icon(
                                  onPressed: currentHostKey != null && _hostFormModified
                                      ? () {
                                          if (_hostFormKey.currentState!.validate()) {
                                            Map<dynamic, dynamic> hostMap =
                                                modelMap.settings.urlToHostMap(_txtControllers.ctrl("hostUrl").text);

                                            if (hostMap.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                content: Text(context.l10n.addValidLink),
                                                backgroundColor: Theme.of(context).colorScheme.error,
                                              ));
                                              return;
                                            }

                                            hostMap['title'] = _txtControllers.ctrl("hostTitle").text;
                                            hostMap['cacheEnabled'] = _switchCacheEnabledKey.currentState!.value;
                                            if (_switchCacheEnabledKey.currentState?.value == false) {
                                              modelMap.clearCache(currentHostKey);
                                            }
                                            if (modelMap.settings.updateHost(currentHostKey!, hostMap)) {
                                              setState(() {
                                                _hostFormModified = false;
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(context.l10n.savedSuccessfully)));
                                            }
                                          }
                                        }
                                      : null,
                                  icon: const Icon(
                                    Icons.save_outlined,
                                    size: 16,
                                  ),
                                  label: Text(context.l10n.save),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            /* Accounts */
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        'Account(s)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: formFieldSpacing),
                    DropdownButtonFormField<String>(
                      key: _userDropdownKey,
                      decoration: InputDecoration(
                          labelText: context.l10n.select("Account"), prefixIcon: const Icon(Icons.cloud_done_outlined)),
                      value: currentUserKey,
                      items: _userItems(),
                      onChanged: (userKey) async {
                        if (userKey == currentUserKey) return;
                        if (_userFormModified == true) {
                          if (!await yesNoDialog(
                              context, context.l10n.msgDataModified, context.l10n.questStillContinue)) {
                            _userDropdownKey.currentState!.reset();
                            return;
                          }
                        }
                        if (userKey != null) {
                          setState(() {
                            updateCurrentHostDefaults(userKey: userKey);
                            _userFormModified = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: formFieldSpacing),
                    Form(
                      onChanged: () {
                        if (!_userFormModified) {
                          setState(() {
                            _userFormModified = true;
                          });
                        }
                      },
                      key: _userFormKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextFormField(
                            controller: _txtControllers.ctrl("userLogin"),
                            decoration: InputDecoration(
                              labelText: context.l10n.loginname,
                              prefixIcon: const Icon(Icons.title_outlined),
                              enabled: false,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.l10n.fieldMustNotBeEmpty;
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              formUserDataMap['key'] = newValue;
                              formUserDataMap['login'] = newValue;
                            },
                          ),
                          const SizedBox(height: formFieldSpacing),
                          TextFormField(
                            controller: _txtControllers.ctrl("userName"),
                            decoration: InputDecoration(
                              labelText: context.l10n.displayName,
                              prefixIcon: const Icon(Icons.title_outlined),
                            ),
                            onSaved: (newValue) {
                              formUserDataMap['name'] = newValue;
                            },
                          ),
                          const SizedBox(height: formFieldSpacing),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                                  onPressed: currentUserKey != null
                                      ? () async {
                                          if (await yesNoDialog(
                                              context, context.l10n.delete, context.l10n.askForDeletion("Account"))) {
                                            if (modelMap.deleteUser(currentHostKey!, currentUserKey!)) {
                                              setState(() {
                                                currentUserKey = null;
                                                updateCurrentHostDefaults();
                                              });
                                            }
                                          }
                                        }
                                      : null,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                  ),
                                  label: Text(context.l10n.delete),
                                ),
                                TextButton.icon(
                                    onPressed: currentHostKey != null
                                        ? () async {
                                            Map<String, String>? result = await showDialog<Map<String, String>>(
                                              context: context, // navigatorKey.currentContext!,
                                              builder: (BuildContext context) {
                                                return Dialog(
                                                  insetPadding: context.dlgPadding,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10.0),
                                                  ),
                                                  child: RegisterHost(
                                                    initialTab: ActiveTab.loginTab,
                                                    params: {
                                                      "loginTitle": context.l10n.titleCreateAccount,
                                                      "currentHostKey": currentHostKey,
                                                    },
                                                  ),
                                                );
                                              },
                                            );
                                            if (result != null) {
                                              setState(() {
                                                if (result['newUserKey'] != null) {
                                                  updateCurrentHostDefaults(userKey: result['newUserKey']);
                                                }
                                              });
                                            }
                                          }
                                        : null,
                                    icon: const Icon(
                                      Icons.person_outline,
                                      size: 16,
                                    ),
                                    label: Text(context.l10n.newText)),
                                TextButton.icon(
                                  onPressed: (currentUserKey != null && currentHostKey != null && _userFormModified)
                                      ? () {
                                          if (_userFormKey.currentState!.validate()) {
                                            _userFormKey.currentState!.save();
                                            if (modelMap.settings.addOrUpdateUser(currentHostKey!, formUserDataMap)) {
                                              setState(() {
                                                _userFormModified = false;
                                              });

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(context.l10n.savedSuccessfully)));
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                content: Text(context.l10n.anErrorOccured),
                                                backgroundColor: Theme.of(context).colorScheme.error,
                                              ));
                                            }
                                          }
                                        }
                                      : null,
                                  icon: const Icon(
                                    Icons.save_outlined,
                                    size: 16,
                                  ),
                                  label: Text(context.l10n.save),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // Widget _infoTab() {
  //   // WpApi.getBookingStats();
  //   JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  //   String jSettings = encoder.convert(modelMap.settings.settingsBox.toMap());
  //   String jEnc =
  //       encoder.convert(modelMap.settings.encryptedBox.toMap()..updateAll((key, value) => value = "*************"));

  //   return Container(
  //     padding: const EdgeInsets.all(10),
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.start,
  //       mainAxisSize: MainAxisSize.max,
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         /*
  //         TextButton(
  //             onPressed: () async {
  //               String cache = encoder.convert(modelMap.settings.encryptedBox.toMap());
  //               // Map<dynamic, dynamic>? mapLocations =
  //               //     await Hive.lazyBox('cbappCaching').get("maplocations_https://laptrr.rr.net.eu.org");
  //               // if (mapLocations == null || (mapLocations["json"] == null && mapLocations["jsonCBAPI"] == null)) {
  //               //   //no cache data available
  //               //   throw Exception("No Service connection and empty cache");
  //               // } else {
  //               //   // if (mapLocations["date"] != null) locationCacheDateTime = mapLocations["date"];
  //               //   cache = (mapLocations["json"] != null) ? mapLocations["json"] : mapLocations["jsonCBAPI"];
  //               // }

  //               FileSaver.instance.saveFile(
  //                 name: "settings.json",
  //                 bytes: const Utf8Encoder().convert(cache),
  //                 // ext: "json",
  //                 mimeType: MimeType.other,
  //               );

  //               // WpApi.getBookingStats().then((value) => setState(
  //               //       () {
  //               //         print(value);
  //               //         _bookingStats = encoder.convert(value);
  //               //       },
  //               //     ));
  //             },
  //             child: const Text("Export")),
  //             */
  //         Text(
  //           "Settings",
  //           style: Theme.of(context).textTheme.titleLarge,
  //         ),
  //         Text(
  //           jSettings,
  //           style: Theme.of(context).textTheme.bodyLarge,
  //         ),
  //         Text(
  //           "Secrets",
  //           style: Theme.of(context).textTheme.titleLarge,
  //         ),
  //         Text(jEnc, style: Theme.of(context).textTheme.bodyLarge),
  //       ],
  //     ),
  //   );
  // }

  List<DropdownMenuItem<String>> _userItems() {
    if (!modelMap.settings.hostList.containsKey(currentHostKey)) return <DropdownMenuItem<String>>[];
    Map<dynamic, dynamic> users = modelMap.settings.hostList[currentHostKey]['users'];
    return users.entries
        .map<DropdownMenuItem<String>>(
          (e) => DropdownMenuItem<String>(
              value: e.key, child: Text((e.value['name'] as String).isEmpty ? e.value['login'] : e.value['name'])),
        )
        .toList();
  }

  List<DropdownMenuItem<String>> _hostItems() {
    return modelMap.settings.hostList.entries
        .map<DropdownMenuItem<String>>(
          (e) => DropdownMenuItem<String>(
              value: e.key, child: Text((e.value['title'] as String).isEmpty ? e.value['domain'] : e.value['title'])),
        )
        .toList();
  }
}
