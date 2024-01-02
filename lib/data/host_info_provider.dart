import 'package:flutter/foundation.dart';
import 'package:cb_app/wp/cb_map_model.dart';
import 'package:cb_app/wp/wp_api.dart';
import 'package:cb_app/parts/utils.dart';

class HostInfoProvider extends ChangeNotifier {
  final Uri hostUrl;
  Uri? connectionTestUri;
  final Map<String, String> msgs = <String, String>{};
  final String errorMsg = l10n().msgFailed;

  HostInfoProvider(this.hostUrl, {bool silent = false, Uri? connectionTestUri}) {
    if (connectionTestUri != null) this.connectionTestUri = connectionTestUri;
    if (!silent) WpApi.testHost(this);
  }

  void onNotify() {
    notifyListeners();
  }

  bool finalCheck = false;
  LoadingState hasCBApi = LoadingState.unknown;
  LoadingState hasCBAppApi = LoadingState.unknown;
  LoadingState supportsAuthentication = LoadingState.unknown;
  LoadingState mapTilesAvailable = LoadingState.unknown;

  LoadingState _hasNetwork = LoadingState.unknown;
  LoadingState get hasNetwork => _hasNetwork;
  set hasNetwork(loadingState) {
    _hasNetwork = loadingState;
    notifyListeners();
  }

  LoadingState _mainUrlConnection = LoadingState.unknown;
  LoadingState get mainUrlConnection => _mainUrlConnection;
  set mainUrlConnection(loadingState) {
    _mainUrlConnection = loadingState;
    notifyListeners();
  }

  LoadingState _restApiConnection = LoadingState.unknown;
  LoadingState get restApiConnection => _restApiConnection;
  set restApiConnection(loadingState) {
    _restApiConnection = loadingState;
    notifyListeners();
  }
}
