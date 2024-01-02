import 'package:flutter/material.dart';
import 'package:expandable/expandable.dart';
import 'package:recase/recase.dart';
import 'package:cb_app/parts/utils.dart';
import 'package:cb_app/wp/cb_map_model.dart';
import 'package:cb_app/data/host_info_provider.dart';
import 'package:provider/provider.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';

enum ActiveTab { hostTab, infoTab, loginTab, maxindex }

class RegisterHost extends StatefulWidget {
  final Map<String, dynamic> params = <String, dynamic>{};
  final ActiveTab? initialTab;
  RegisterHost({this.initialTab, params, super.key}) {
    if (params != null) this.params.addAll(params);
  }

  @override
  State<RegisterHost> createState() => _RegisterHost();
}

class _RegisterHost extends State<RegisterHost> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  bool hasApplicationKey = false;
  Map<String, dynamic> formHostDataMap = <String, dynamic>{};

  ExpandableController expCtrlAppPassword = ExpandableController();
  ExpandableController expCtrlLoginPassword = ExpandableController(initialExpanded: true);
  ExpandableController expPasswordHelp = ExpandableController();

  late FocusNode _userPasswordFocusNode;
  late FocusNode _appPasswordFocusNode;

  final ScrollController _scrollController = ScrollController();
  late TabController tabController;
  late ModelMapData modelMap;

  final FormItemControllers<TextEditingController> _txtControllers =
      FormItemControllers<TextEditingController>(() => TextEditingController());

  void goTo(int index) {
    // tabController.animateTo(index);
    setState(() {
      // currentTab = index;
      tabController.animateTo(index);
    });
  }

  @override
  void dispose() {
    _txtControllers.dispose();
    _userPasswordFocusNode.dispose();
    _appPasswordFocusNode.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    modelMap = Provider.of<ModelMapData>(context, listen: false);

    tabController = TabController(
        length: ActiveTab.maxindex.index,
        vsync: this,
        initialIndex: (widget.initialTab?.index ?? ActiveTab.hostTab.index));
    _userPasswordFocusNode = FocusNode();
    _appPasswordFocusNode = FocusNode();

    // currentTab = 2;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 500,
        maxHeight: 350,
      ),
      child: LoaderOverlay(
        overlayWholeScreen: false,
        child: TabBarView(
          controller: tabController,
          children: <Widget>[
            SingleChildScrollView(
              child: _hostsForm(),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.params["hideBackButton"] == null)
                  BackButton(
                    onPressed: () {
                      goTo(ActiveTab.hostTab.index);
                    },
                  ),
                _hostInfo(),
              ],
            ),
            SingleChildScrollView(
              child: _loginTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingStateSymbol(LoadingState loadingState) {
    return switch (loadingState) {
      LoadingState.failed => const Icon(Icons.clear, color: Colors.red),
      LoadingState.unknown => const Icon(
          Icons.question_mark,
          size: 14,
        ),
      LoadingState.loading => const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      LoadingState.loaded => const Icon(Icons.done, color: Colors.green),
      LoadingState.inactive => const Icon(Icons.more_horiz),
    };
  }

  Widget _hostInfo() {
    String strTestUrl = "";
    if (formHostDataMap['hostUrl'] == null && widget.params["testUrl"] == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          context.l10n.addValidLink,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red),
        ),
      );
    } else {
      strTestUrl = (formHostDataMap['hostUrl'] ?? widget.params["testUrl"]) ?? "";
    }

    return ChangeNotifierProvider(
      create: (context) => HostInfoProvider(Uri.tryParse(strTestUrl)!,
          connectionTestUri: Uri.tryParse(modelMap.settings.getSetting("connectionTestUrl", "https://1.1.1.1/"))),
      child: Expanded(
        child: Consumer<HostInfoProvider>(builder: (BuildContext context, HostInfoProvider hostInfo, child) {
          if (hostInfo.finalCheck && _scrollController.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // setState(() {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
              // });
            });
          }
          return ListView(
            controller: _scrollController,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10),
                child: Text(
                  strTestUrl,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const Divider(
                indent: 5,
                endIndent: 5,
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.public_outlined),
                  title: Text(context.l10n.netwokTest),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _loadingStateSymbol(hostInfo.hasNetwork),
                  ),
                  subtitle: Text(hostInfo.msgs["hasNetworkConnection"] ?? hostInfo.errorMsg),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.public_outlined),
                  title: Text(context.l10n.siteConnectionTest),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _loadingStateSymbol(hostInfo.mainUrlConnection),
                  ),
                  subtitle: Text(hostInfo.msgs["mainUrlConnection"] ?? hostInfo.errorMsg),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.public_outlined),
                  title: Text(context.l10n.restAPITest),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _loadingStateSymbol(hostInfo.restApiConnection),
                  ),
                  subtitle: Text(hostInfo.msgs["restApiConnection"] ?? hostInfo.errorMsg),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.public_outlined),
                  title: Text(context.l10n.cbAPITest),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _loadingStateSymbol(hostInfo.hasCBApi),
                  ),
                  subtitle: Text(hostInfo.msgs["cbApiConnection"] ?? hostInfo.errorMsg),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.public_outlined),
                  title: Text(context.l10n.loginTest),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _loadingStateSymbol(hostInfo.supportsAuthentication),
                  ),
                  subtitle: Text(hostInfo.msgs["supportsAuthentication"] ?? hostInfo.errorMsg),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.public_outlined),
                  title: Text(context.l10n.appExtensionAPITest),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _loadingStateSymbol(hostInfo.hasCBAppApi),
                  ),
                  subtitle: Text(hostInfo.msgs["cbAppApiConnection"] ?? hostInfo.errorMsg),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _hostsForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0), //const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ReCase(context.l10n.register(context.l10n.service)).sentenceCase,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              keyboardType: TextInputType.url,
              autofocus: true,
              initialValue: formHostDataMap['hostUrl'], // hostUrl,
              onSaved: (newValue) => formHostDataMap['hostUrl'] = newValue,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.addValidLink;
                }
                Uri? parsed = Uri.tryParse(value);
                if (parsed == null || parsed.host.isEmpty || (parsed.scheme != "http" && parsed.scheme != "https")) {
                  return context.l10n.addValidLink;
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: '${context.l10n.service} Url *',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  color: Theme.of(context).colorScheme.tertiary,
                  tooltip: context.l10n.netwokTest,
                  onPressed: () async {
                    FocusScope.of(context).unfocus();

                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      goTo(ActiveTab.infoTab.index);
                    }
                  },
                  icon: const Icon(Icons.network_check),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              onSaved: (newValue) => formHostDataMap['title'] = newValue,
              decoration: InputDecoration(
                labelText: context.l10n.displayName,
                prefixIcon: const Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              // mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.tertiary),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 16,
                  ),
                  label: Text(context.l10n.cancel),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      widget.params['currentHostKey'] = modelMap.addHostSync(formHostDataMap);
                      goTo(ActiveTab.loginTab.index);
                    }
                  },
                  icon: const Icon(
                    Icons.save_outlined,
                    size: 16,
                  ),
                  label: Text(context.l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginTab() {
    Map<String, dynamic> formUserDataMap = <String, dynamic>{"user": <dynamic, dynamic>{}};

    if (widget.params['currentHostKey'] != null && widget.params['currentUserKey'] != null) {
      Map<dynamic, dynamic>? curUser =
          modelMap.settings.hostList[widget.params['currentHostKey']]?['users']?[widget.params['currentUserKey']];
      if (curUser != null) {
        _txtControllers.ctrl('userName').text = curUser['name'];
        _txtControllers.ctrl('userLogin').text = curUser['login'];
      }
    }

    return Form(
      key: _loginFormKey,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.params['loginTitle'] ?? 'Login',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            TextFormField(
              controller: _txtControllers.ctrl('userName'),
              autofocus: (widget.params['formTask'] != 'login'),
              enabled: (widget.params['formTask'] != 'login'),
              decoration: InputDecoration(
                labelText: context.l10n.displayName,
                prefixIcon: const Icon(Icons.title_outlined),
              ),
              onSaved: (newValue) {
                formUserDataMap['user']['name'] = newValue;
              },
            ),
            const SizedBox(height: 10.0),
            TextFormField(
              controller: _txtControllers.ctrl('userLogin'),
              enabled: !(widget.params['formTask'] == 'login' && _txtControllers.ctrl('userLogin').text.isNotEmpty),
              decoration: InputDecoration(
                labelText: context.l10n.accountLoginName,
                prefixIcon: const Icon(Icons.title_outlined),
                suffixIcon: const Icon(
                  Icons.star,
                  size: 14,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.fieldMustNotBeEmpty;
                }
                return null;
              },
              onSaved: (newValue) {
                formUserDataMap['user']['key'] = newValue;
                formUserDataMap['user']['login'] = newValue;
              },
            ),
            const SizedBox(height: 10.0),
            ExpandablePanel(
              controller: expCtrlLoginPassword
                ..addListener(() {
                  if (expCtrlLoginPassword.expanded) {
                    Timer(const Duration(milliseconds: 100), () => _userPasswordFocusNode.requestFocus());
                  }
                }),
              collapsed: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: RichText(
                  text: TextSpan(children: [
                    WidgetSpan(
                      child: InkWell(
                        onTap: () {
                          expPasswordHelp.toggle();
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: Icon(
                            Icons.help_outline,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: context.l10n.orAddAccountPassword,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontStyle: FontStyle.italic, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          expCtrlLoginPassword.toggle();
                          expCtrlAppPassword.toggle();
                        },
                    ),
                  ]),
                ),
              ),
              expanded: TextFormField(
                autofocus: (widget.params['formTask'] == 'login'),
                focusNode: _userPasswordFocusNode,
                controller: _txtControllers.ctrl('userPassword'),
                obscureText: true,
                validator: (value) {
                  if (widget.params['formTask'] == 'login') {
                    if (_txtControllers.ctrl('userAppPassword').text.isNotEmpty ||
                        (value != null && value.isNotEmpty)) {
                      return null;
                    }
                    return context.l10n.accountOrApplicationPasswordMustBeFilled;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: context.l10n.accountPassword,
                  prefixIcon: const Icon(Icons.password_outlined),
                ),
                onSaved: (newValue) {
                  formUserDataMap['accountPassword'] = newValue;
                },
              ),
            ),
            const SizedBox(height: 10.0),
            ExpandablePanel(
              controller: expCtrlAppPassword
                ..addListener(() {
                  if (expCtrlAppPassword.expanded) {
                    Timer(const Duration(milliseconds: 100), () => _appPasswordFocusNode.requestFocus());
                  }
                }),
              collapsed: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: RichText(
                  text: TextSpan(children: [
                    WidgetSpan(
                      child: InkWell(
                        onTap: () {
                          expPasswordHelp.toggle();
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: Icon(
                            Icons.help_outline,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: context.l10n.orAddApplicationPassword,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontStyle: FontStyle.italic, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          expCtrlAppPassword.toggle();
                          expCtrlLoginPassword.toggle();
                        },
                    ),
                  ]),
                ),
              ),
              expanded: TextFormField(
                controller: _txtControllers.ctrl('userAppPassword'),
                focusNode: _appPasswordFocusNode,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.l10n.applicationPassword,
                  prefixIcon: const Icon(Icons.password_outlined),
                ),
                validator: (value) {
                  if (widget.params['formTask'] == 'login') {
                    if (_txtControllers.ctrl('userPassword').text.isNotEmpty || (value != null && value.isNotEmpty)) {
                      return null;
                    }
                    return context.l10n.accountOrApplicationPasswordMustBeFilled;
                  }
                  return null;
                },
                onSaved: (newValue) {
                  formUserDataMap['appPassword'] = newValue;
                },
              ),
            ),
            ExpandableNotifier(
              controller: expPasswordHelp,
              child: ScrollOnExpand(
                child: ExpandablePanel(
                  // controller: expPasswordHelp,
                  collapsed: const SizedBox.shrink(),
                  expanded: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Stack(
                      children: [
                        Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(context.l10n.infoAppPassword),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                            ),
                            onPressed: () => expPasswordHelp.toggle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.tertiary),
                  onPressed: () =>
                      Navigator.pop(context, <String, String>{"newHostKey": widget.params['currentHostKey']}),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 16,
                  ),
                  label: Text(context.l10n.cancel),
                ),
                TextButton.icon(
                  onPressed: () async {
                    String appPasswordSaved = "unknown";
                    String errorMsg = "";
                    String appPassword = "";

                    if (_loginFormKey.currentState!.validate()) {
                      _loginFormKey.currentState!.save();

                      if (castDef<String>(formUserDataMap['accountPassword'], "").isNotEmpty &&
                          castDef<String>(formUserDataMap['appPassword'], "").isEmpty) {
                        try {
                          if (mounted && !context.loaderOverlay.visible) context.loaderOverlay.show();
                          appPassword = await modelMap.retrieveAppPassword(formUserDataMap['user']['login'],
                              formUserDataMap['accountPassword'], widget.params['currentHostKey']);

                          appPasswordSaved = "true";
                        } catch (ex) {
                          appPasswordSaved = "false";
                          errorMsg += context.mounted
                              ? context.l10n.errRetrieveAppPassword
                              : "Error: Application password not determined\n";
                        }
                      }

                      if (castDef<String>(formUserDataMap['appPassword'], "").isNotEmpty) {
                        if (mounted && !context.loaderOverlay.visible) context.loaderOverlay.show();
                        appPassword = formUserDataMap['appPassword'];
                        if (!await modelMap.checkAuth(formUserDataMap['user']['login'], formUserDataMap['appPassword'],
                                modelMap.settings.uriFromHostKey(widget.params['currentHostKey'])!) &&
                            mounted) {
                          errorMsg += "Error: ${context.l10n.errLoginFailed}\n";
                          appPasswordSaved = "false";
                        } else {
                          appPasswordSaved = "true";
                        }
                      }
                      if (mounted && context.loaderOverlay.visible) context.loaderOverlay.hide();

                      if (widget.params['formTask'] != 'login') {
                        if (mounted &&
                            appPasswordSaved == "false" &&
                            !(await yesNoDialog(context, context.l10n.errSaveAccountAnyway, errorMsg))) {
                          if (mounted) {
                            Navigator.pop(context, <String, String>{"newHostKey": widget.params['currentHostKey']});
                          }
                          return;
                        }
                        modelMap.settings.addOrUpdateUser(widget.params['currentHostKey'], formUserDataMap['user']);
                        widget.params['currentUserKey'] = formUserDataMap['user']['key'];
                        if (appPassword.isNotEmpty) {
                          modelMap.updateAppPassword(
                              formUserDataMap['user']['login'], appPassword, widget.params['currentHostKey']);
                        }
                      } else {
                        if (appPassword.isNotEmpty && appPasswordSaved == "true") {
                          modelMap.updateAppPassword(
                              formUserDataMap['user']['login'], appPassword, widget.params['currentHostKey']);
                        }
                      }

                      if (mounted) {
                        Navigator.pop(context, <String, String>{
                          "newUserKey": widget.params['currentUserKey'],
                          "newHostKey": widget.params['currentHostKey'],
                          "appPasswordSaved": appPasswordSaved,
                          "errorMsg": errorMsg,
                        });
                      }
                    }
                  },
                  icon: Icon(
                    (widget.params['formTask'] == "login") ? Icons.login_outlined : Icons.save_outlined,
                    size: 16,
                  ),
                  label: Text((widget.params['formTask'] == "login") ? context.l10n.logIn : context.l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
