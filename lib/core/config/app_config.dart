class AppPlatformConfig {
  const AppPlatformConfig({
    required this.defaultPlatformFeeRate,
    required this.mechanicCommissionDefault,
  });

  final double defaultPlatformFeeRate;
  final double mechanicCommissionDefault;

  factory AppPlatformConfig.fromJson(Map<String, dynamic> json) {
    return AppPlatformConfig(
      defaultPlatformFeeRate: (json['defaultPlatformFeeRate'] as num?)?.toDouble() ?? 10,
      mechanicCommissionDefault: (json['mechanicCommissionDefault'] as num?)?.toDouble() ?? 15,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultPlatformFeeRate': defaultPlatformFeeRate,
        'mechanicCommissionDefault': mechanicCommissionDefault,
      };
}

class AppUiConfig {
  const AppUiConfig({
    required this.homeBackgroundUrl,
    required this.brandName,
  });

  final String homeBackgroundUrl;
  final String brandName;

  factory AppUiConfig.fromJson(Map<String, dynamic> json) {
    return AppUiConfig(
      homeBackgroundUrl: (json['homeBackgroundUrl'] as String?)?.trim() ?? '',
      brandName: (json['brandName'] as String?)?.trim().isNotEmpty == true
          ? (json['brandName'] as String).trim()
          : 'SOSBIKE',
    );
  }

  Map<String, dynamic> toJson() => {
        'homeBackgroundUrl': homeBackgroundUrl,
        'brandName': brandName,
      };
}

class AppFeatureFlags {
  const AppFeatureFlags({
    required this.maintenanceMode,
    required this.sosEnabled,
    required this.customerRegisterEnabled,
    required this.mechanicRegisterEnabled,
  });

  final bool maintenanceMode;
  final bool sosEnabled;
  final bool customerRegisterEnabled;
  final bool mechanicRegisterEnabled;

  factory AppFeatureFlags.fromJson(Map<String, dynamic> json) {
    return AppFeatureFlags(
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
      sosEnabled: json['sosEnabled'] as bool? ?? true,
      customerRegisterEnabled: json['customerRegisterEnabled'] as bool? ?? true,
      mechanicRegisterEnabled: json['mechanicRegisterEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'maintenanceMode': maintenanceMode,
        'sosEnabled': sosEnabled,
        'customerRegisterEnabled': customerRegisterEnabled,
        'mechanicRegisterEnabled': mechanicRegisterEnabled,
      };
}

class AppConfig {
  const AppConfig({
    required this.platform,
    required this.ui,
    required this.featureFlags,
  });

  final AppPlatformConfig platform;
  final AppUiConfig ui;
  final AppFeatureFlags featureFlags;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      platform: AppPlatformConfig.fromJson((json['platform'] as Map?)?.cast<String, dynamic>() ?? const {}),
      ui: AppUiConfig.fromJson((json['ui'] as Map?)?.cast<String, dynamic>() ?? const {}),
      featureFlags:
          AppFeatureFlags.fromJson((json['featureFlags'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'platform': platform.toJson(),
        'ui': ui.toJson(),
        'featureFlags': featureFlags.toJson(),
      };

  double get defaultPlatformFeeRate => platform.defaultPlatformFeeRate;
  double get mechanicCommissionDefault => platform.mechanicCommissionDefault;
  String get homeBackgroundUrl => ui.homeBackgroundUrl;
  String get brandName => ui.brandName;
  AppFeatureFlags get flags => featureFlags;

  AppConfig copyWith({
    AppPlatformConfig? platform,
    AppUiConfig? ui,
    AppFeatureFlags? featureFlags,
  }) {
    return AppConfig(
      platform: platform ?? this.platform,
      ui: ui ?? this.ui,
      featureFlags: featureFlags ?? this.featureFlags,
    );
  }
}

const AppConfig defaultAppConfig = AppConfig(
  platform: AppPlatformConfig(
    defaultPlatformFeeRate: 10,
    mechanicCommissionDefault: 15,
  ),
  ui: AppUiConfig(
    homeBackgroundUrl: '',
    brandName: 'SOSBIKE',
  ),
  featureFlags: AppFeatureFlags(
    maintenanceMode: false,
    sosEnabled: true,
    customerRegisterEnabled: true,
    mechanicRegisterEnabled: true,
  ),
);
