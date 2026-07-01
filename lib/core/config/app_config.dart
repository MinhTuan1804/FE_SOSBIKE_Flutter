import 'package:flutter/material.dart';

Color parseHexColor(String hexString, Color fallback) {
  try {
    String hex = hexString.trim();
    if (hex.startsWith('#')) {
      hex = hex.replaceFirst('#', '');
    }
    if (hex.length == 6) {
      hex = 'ff$hex';
    }
    return Color(int.parse(hex, radix: 16));
  } catch (_) {
    return fallback;
  }
}

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
    required this.appBackgroundColor,
    required this.appNavbarBottomColor,
    required this.appNavbarHeaderColor,
  });

  final String homeBackgroundUrl;
  final String brandName;
  final String appBackgroundColor;
  final String appNavbarBottomColor;
  final String appNavbarHeaderColor;

  factory AppUiConfig.fromJson(Map<String, dynamic> json) {
    return AppUiConfig(
      homeBackgroundUrl: (json['homeBackgroundUrl'] as String?)?.trim() ?? '',
      brandName: (json['brandName'] as String?)?.trim().isNotEmpty == true
          ? (json['brandName'] as String).trim()
          : 'SOSBIKE',
      appBackgroundColor: (json['appBackgroundColor'] as String?)?.trim() ?? '#FFFFFF',
      appNavbarBottomColor: (json['appNavbarBottomColor'] as String?)?.trim() ?? '#D02121',
      appNavbarHeaderColor: (json['appNavbarHeaderColor'] as String?)?.trim() ?? '#D02121',
    );
  }

  Map<String, dynamic> toJson() => {
        'homeBackgroundUrl': homeBackgroundUrl,
        'brandName': brandName,
        'appBackgroundColor': appBackgroundColor,
        'appNavbarBottomColor': appNavbarBottomColor,
        'appNavbarHeaderColor': appNavbarHeaderColor,
      };

  Color get backgroundColor => parseHexColor(appBackgroundColor, Colors.white);
  Color get navbarBottomColor => parseHexColor(appNavbarBottomColor, const Color(0xFFD02121));
  Color get navbarHeaderColor => parseHexColor(appNavbarHeaderColor, const Color(0xFFD02121));
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

class AppThirdPartyConfig {
  const AppThirdPartyConfig({
    required this.goongApiKey,
    required this.googleMapApiKey,
  });

  final String goongApiKey;
  final String googleMapApiKey;

  factory AppThirdPartyConfig.fromJson(Map<String, dynamic> json) {
    return AppThirdPartyConfig(
      goongApiKey: (json['goongApiKey'] as String?)?.trim() ?? '',
      googleMapApiKey: (json['googleMapApiKey'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'goongApiKey': goongApiKey,
        'googleMapApiKey': googleMapApiKey,
      };
}

class AppLandingPageConfig {
  const AppLandingPageConfig({
    required this.hotline,
    required this.facebookUrl,
    required this.appStoreUrl,
    required this.googlePlayUrl,
    required this.backgroundImageUrl,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String hotline;
  final String facebookUrl;
  final String appStoreUrl;
  final String googlePlayUrl;
  final String backgroundImageUrl;
  final String primaryColor;
  final String secondaryColor;

  factory AppLandingPageConfig.fromJson(Map<String, dynamic> json) {
    return AppLandingPageConfig(
      hotline: (json['hotline'] as String?)?.trim() ?? '0982815244',
      facebookUrl: (json['facebookUrl'] as String?)?.trim() ?? 'https://www.facebook.com/profile.php?id=61572062824222',
      appStoreUrl: (json['appStoreUrl'] as String?)?.trim() ?? 'https://www.facebook.com/profile.php?id=61572062824222',
      googlePlayUrl: (json['googlePlayUrl'] as String?)?.trim() ?? 'https://www.facebook.com/profile.php?id=61572062824222',
      backgroundImageUrl: (json['backgroundImageUrl'] as String?)?.trim() ?? '',
      primaryColor: (json['primaryColor'] as String?)?.trim() ?? '#DA251D',
      secondaryColor: (json['secondaryColor'] as String?)?.trim() ?? '#3B82F6',
    );
  }

  Map<String, dynamic> toJson() => {
        'hotline': hotline,
        'facebookUrl': facebookUrl,
        'appStoreUrl': appStoreUrl,
        'googlePlayUrl': googlePlayUrl,
        'backgroundImageUrl': backgroundImageUrl,
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
      };

  Color get lpPrimaryColor => parseHexColor(primaryColor, const Color(0xFFDA251D));
  Color get lpSecondaryColor => parseHexColor(secondaryColor, const Color(0xFF3B82F6));
}

class AppConfig {
  const AppConfig({
    required this.platform,
    required this.ui,
    required this.featureFlags,
    required this.thirdParty,
    required this.landingPage,
  });

  static AppConfig current = defaultAppConfig;

  final AppPlatformConfig platform;
  final AppUiConfig ui;
  final AppFeatureFlags featureFlags;
  final AppThirdPartyConfig thirdParty;
  final AppLandingPageConfig landingPage;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      platform: AppPlatformConfig.fromJson((json['platform'] as Map?)?.cast<String, dynamic>() ?? const {}),
      ui: AppUiConfig.fromJson((json['ui'] as Map?)?.cast<String, dynamic>() ?? const {}),
      featureFlags:
          AppFeatureFlags.fromJson((json['featureFlags'] as Map?)?.cast<String, dynamic>() ?? const {}),
      thirdParty:
          AppThirdPartyConfig.fromJson((json['thirdParty'] as Map?)?.cast<String, dynamic>() ?? const {}),
      landingPage:
          AppLandingPageConfig.fromJson((json['landingPage'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'platform': platform.toJson(),
        'ui': ui.toJson(),
        'featureFlags': featureFlags.toJson(),
        'thirdParty': thirdParty.toJson(),
        'landingPage': landingPage.toJson(),
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
    AppThirdPartyConfig? thirdParty,
    AppLandingPageConfig? landingPage,
  }) {
    return AppConfig(
      platform: platform ?? this.platform,
      ui: ui ?? this.ui,
      featureFlags: featureFlags ?? this.featureFlags,
      thirdParty: thirdParty ?? this.thirdParty,
      landingPage: landingPage ?? this.landingPage,
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
    appBackgroundColor: '#FFFFFF',
    appNavbarBottomColor: '#D02121',
    appNavbarHeaderColor: '#D02121',
  ),
  featureFlags: AppFeatureFlags(
    maintenanceMode: false,
    sosEnabled: true,
    customerRegisterEnabled: true,
    mechanicRegisterEnabled: true,
  ),
  thirdParty: AppThirdPartyConfig(
    goongApiKey: 'J7uk8GJZvzozpZ8p631cnxMVXUNVz0O0juQCSAJq',
    googleMapApiKey: '',
  ),
  landingPage: AppLandingPageConfig(
    hotline: '0982815244',
    facebookUrl: 'https://www.facebook.com/profile.php?id=61572062824222',
    appStoreUrl: 'https://www.facebook.com/profile.php?id=61572062824222',
    googlePlayUrl: 'https://www.facebook.com/profile.php?id=61572062824222',
    backgroundImageUrl: '',
    primaryColor: '#DA251D',
    secondaryColor: '#3B82F6',
  ),
);
