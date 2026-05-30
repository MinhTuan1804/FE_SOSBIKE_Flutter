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

class AppConfig {
  const AppConfig({
    required this.platform,
    required this.ui,
  });

  final AppPlatformConfig platform;
  final AppUiConfig ui;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      platform: AppPlatformConfig.fromJson((json['platform'] as Map?)?.cast<String, dynamic>() ?? const {}),
      ui: AppUiConfig.fromJson((json['ui'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'platform': platform.toJson(),
        'ui': ui.toJson(),
      };

  double get defaultPlatformFeeRate => platform.defaultPlatformFeeRate;
  double get mechanicCommissionDefault => platform.mechanicCommissionDefault;
  String get homeBackgroundUrl => ui.homeBackgroundUrl;
  String get brandName => ui.brandName;

  AppConfig copyWith({
    AppPlatformConfig? platform,
    AppUiConfig? ui,
  }) {
    return AppConfig(
      platform: platform ?? this.platform,
      ui: ui ?? this.ui,
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
);
