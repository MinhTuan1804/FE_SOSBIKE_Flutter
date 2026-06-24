import 'package:flutter/foundation.dart';

import 'app_config.dart';
import 'app_config_repository.dart';

class AppConfigProvider extends ChangeNotifier {
  AppConfigProvider(this._repository);

  final AppConfigRepository _repository;

  AppConfig _config = defaultAppConfig;
  bool _isLoading = false;
  String? _errorMessage;

  AppConfig get config => _config;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _config = await _repository.loadConfig();
      AppConfig.current = _config;
    } catch (e) {
      _errorMessage = e.toString();
      _config = defaultAppConfig;
      AppConfig.current = defaultAppConfig;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLocalFallback(AppConfig config) {
    _config = config;
    AppConfig.current = config;
    notifyListeners();
  }
}

