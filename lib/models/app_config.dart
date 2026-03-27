import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
// BRANDING
// ─────────────────────────────────────────

class AppBranding {
  final String appName;
  final String logoUrl;
  final String authImageUrl;
  final String heroText;
  final String heroDesc;
  final String storeBannerTitle;
  final String storeBannerDesc;

  const AppBranding({
    required this.appName,
    required this.logoUrl,
    required this.authImageUrl,
    required this.heroText,
    required this.heroDesc,
    required this.storeBannerTitle,
    required this.storeBannerDesc,
  });

  factory AppBranding.fromMap(Map<String, dynamic> map) {
    return AppBranding(
      appName:          map['appName']          as String? ?? 'Pottery Station',
      logoUrl:          map['logoUrl']          as String? ?? '',
      authImageUrl:     map['authImageUrl']     as String? ?? '',
      heroText:         map['heroText']         as String? ?? '',
      heroDesc:         map['heroDesc']         as String? ?? '',
      storeBannerTitle: map['storeBannerTitle'] as String? ?? '',
      storeBannerDesc:  map['storeBannerDesc']  as String? ?? '',
    );
  }

  factory AppBranding.empty() => const AppBranding(
        appName:          'Pottery Station',
        logoUrl:          '',
        authImageUrl:     '',
        heroText:         'The art of intentional form.',
        heroDesc:         '',
        storeBannerTitle: '',
        storeBannerDesc:  '',
      );

  Map<String, dynamic> toMap() {
    return {
      'appName':          appName,
      'logoUrl':          logoUrl,
      'authImageUrl':     authImageUrl,
      'heroText':         heroText,
      'heroDesc':         heroDesc,
      'storeBannerTitle': storeBannerTitle,
      'storeBannerDesc':  storeBannerDesc,
    };
  }

  AppBranding copyWith({
    String? appName,
    String? logoUrl,
    String? authImageUrl,
    String? heroText,
    String? heroDesc,
    String? storeBannerTitle,
    String? storeBannerDesc,
  }) {
    return AppBranding(
      appName:          appName          ?? this.appName,
      logoUrl:          logoUrl          ?? this.logoUrl,
      authImageUrl:     authImageUrl     ?? this.authImageUrl,
      heroText:         heroText         ?? this.heroText,
      heroDesc:         heroDesc         ?? this.heroDesc,
      storeBannerTitle: storeBannerTitle ?? this.storeBannerTitle,
      storeBannerDesc:  storeBannerDesc  ?? this.storeBannerDesc,
    );
  }
}

// ─────────────────────────────────────────
// CONTACT
// ─────────────────────────────────────────

class AppContact {
  final String supportEmail;
  final String supportPhone;
  final String address;

  const AppContact({
    required this.supportEmail,
    required this.supportPhone,
    required this.address,
  });

  factory AppContact.fromMap(Map<String, dynamic> map) {
    return AppContact(
      supportEmail: map['supportEmail'] as String? ?? '',
      supportPhone: map['supportPhone'] as String? ?? '',
      address:      map['address']      as String? ?? '',
    );
  }

  factory AppContact.empty() => const AppContact(
        supportEmail: '',
        supportPhone: '',
        address:      '',
      );

  Map<String, dynamic> toMap() {
    return {
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'address':      address,
    };
  }

  AppContact copyWith({
    String? supportEmail,
    String? supportPhone,
    String? address,
  }) {
    return AppContact(
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      address:      address      ?? this.address,
    );
  }
}

// ─────────────────────────────────────────
// CONTENT
// ─────────────────────────────────────────

class AppContent {
  final String aboutUs;
  final String termsConditions;
  final String privacyPolicy;
  final String helpText;

  const AppContent({
    required this.aboutUs,
    required this.termsConditions,
    required this.privacyPolicy,
    required this.helpText,
  });

  factory AppContent.fromMap(Map<String, dynamic> map) {
    return AppContent(
      aboutUs:         map['aboutUs']         as String? ?? '',
      termsConditions: map['termsConditions'] as String? ?? '',
      privacyPolicy:   map['privacyPolicy']   as String? ?? '',
      helpText:        map['helpText']        as String? ?? '',
    );
  }

  factory AppContent.empty() => const AppContent(
        aboutUs:         '',
        termsConditions: '',
        privacyPolicy:   '',
        helpText:        '',
      );

  Map<String, dynamic> toMap() {
    return {
      'aboutUs':         aboutUs,
      'termsConditions': termsConditions,
      'privacyPolicy':   privacyPolicy,
      'helpText':        helpText,
    };
  }

  AppContent copyWith({
    String? aboutUs,
    String? termsConditions,
    String? privacyPolicy,
    String? helpText,
  }) {
    return AppContent(
      aboutUs:         aboutUs         ?? this.aboutUs,
      termsConditions: termsConditions ?? this.termsConditions,
      privacyPolicy:   privacyPolicy   ?? this.privacyPolicy,
      helpText:        helpText        ?? this.helpText,
    );
  }
}

// ─────────────────────────────────────────
// SOCIAL
// ─────────────────────────────────────────

class AppSocial {
  final String instagramUrl;
  final String facebookUrl;
  final String websiteUrl;

  const AppSocial({
    required this.instagramUrl,
    required this.facebookUrl,
    required this.websiteUrl,
  });

  factory AppSocial.fromMap(Map<String, dynamic> map) {
    return AppSocial(
      instagramUrl: map['instagramUrl'] as String? ?? '',
      facebookUrl:  map['facebookUrl']  as String? ?? '',
      websiteUrl:   map['websiteUrl']   as String? ?? '',
    );
  }

  factory AppSocial.empty() => const AppSocial(
        instagramUrl: '',
        facebookUrl:  '',
        websiteUrl:   '',
      );

  Map<String, dynamic> toMap() {
    return {
      'instagramUrl': instagramUrl,
      'facebookUrl':  facebookUrl,
      'websiteUrl':   websiteUrl,
    };
  }

  AppSocial copyWith({
    String? instagramUrl,
    String? facebookUrl,
    String? websiteUrl,
  }) {
    return AppSocial(
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl:  facebookUrl  ?? this.facebookUrl,
      websiteUrl:   websiteUrl   ?? this.websiteUrl,
    );
  }
}

// ─────────────────────────────────────────
// FEATURES
// ─────────────────────────────────────────

class AppFeatures {
  final bool maintenanceMode;

  const AppFeatures({required this.maintenanceMode});

  factory AppFeatures.fromMap(Map<String, dynamic> map) {
    return AppFeatures(
      maintenanceMode: map['maintenanceMode'] as bool? ?? false,
    );
  }

  factory AppFeatures.empty() => const AppFeatures(maintenanceMode: false);

  Map<String, dynamic> toMap() {
    return {
      'maintenanceMode': maintenanceMode,
    };
  }

  AppFeatures copyWith({bool? maintenanceMode}) {
    return AppFeatures(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
    );
  }
}

// ─────────────────────────────────────────
// EXHIBITION
// ─────────────────────────────────────────

class AppExhibition {
  final String title;
  final String location;
  final String address;
  final DateTime? startDate;
  final DateTime? endDate;
  final String openTime;
  final String closeTime;
  final String displayTime;
  final String imageUrl;
  final bool isActive;
  final String thankYouMessage;
  final String lastDayMessage;
  final String upcomingMessage;

  const AppExhibition({
    required this.title,
    required this.location,
    required this.address,
    this.startDate,
    this.endDate,
    required this.openTime,
    required this.closeTime,
    required this.displayTime,
    required this.imageUrl,
    required this.isActive,
    required this.thankYouMessage,
    required this.lastDayMessage,
    required this.upcomingMessage,
  });

  factory AppExhibition.fromMap(Map<String, dynamic> map) {
    return AppExhibition(
      title:           map['title']           as String? ?? '',
      location:        map['location']        as String? ?? '',
      address:         map['address']         as String? ?? '',
      startDate:       (map['startDate']  as Timestamp?)?.toDate(),
      endDate:         (map['endDate']    as Timestamp?)?.toDate(),
      openTime:        map['openTime']        as String? ?? '',
      closeTime:       map['closeTime']       as String? ?? '',
      displayTime:     map['displayTime']     as String? ?? '',
      imageUrl:        map['imageUrl']        as String? ?? '',
      isActive:        map['isActive']        as bool?   ?? false,
      thankYouMessage: map['thankYouMessage'] as String? ?? '',
      lastDayMessage:  map['lastDayMessage']  as String? ?? '',
      upcomingMessage: map['upcomingMessage'] as String? ?? '',
    );
  }

  factory AppExhibition.empty() => const AppExhibition(
        title:           '',
        location:        '',
        address:         '',
        openTime:        '',
        closeTime:       '',
        displayTime:     '',
        imageUrl:        '',
        isActive:        false,
        thankYouMessage: '',
        lastDayMessage:  '',
        upcomingMessage: '',
      );

  Map<String, dynamic> toMap() {
    return {
      'title':           title,
      'location':        location,
      'address':         address,
      'startDate':       startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate':         endDate != null ? Timestamp.fromDate(endDate!) : null,
      'openTime':        openTime,
      'closeTime':       closeTime,
      'displayTime':     displayTime,
      'imageUrl':        imageUrl,
      'isActive':        isActive,
      'thankYouMessage': thankYouMessage,
      'lastDayMessage':  lastDayMessage,
      'upcomingMessage': upcomingMessage,
    };
  }

  AppExhibition copyWith({
    String? title,
    String? location,
    String? address,
    DateTime? startDate,
    DateTime? endDate,
    String? openTime,
    String? closeTime,
    String? displayTime,
    String? imageUrl,
    bool? isActive,
    String? thankYouMessage,
    String? lastDayMessage,
    String? upcomingMessage,
  }) {
    return AppExhibition(
      title:           title           ?? this.title,
      location:        location        ?? this.location,
      address:         address         ?? this.address,
      startDate:       startDate       ?? this.startDate,
      endDate:         endDate         ?? this.endDate,
      openTime:        openTime        ?? this.openTime,
      closeTime:       closeTime       ?? this.closeTime,
      displayTime:     displayTime     ?? this.displayTime,
      imageUrl:        imageUrl        ?? this.imageUrl,
      isActive:        isActive        ?? this.isActive,
      thankYouMessage: thankYouMessage ?? this.thankYouMessage,
      lastDayMessage:  lastDayMessage  ?? this.lastDayMessage,
      upcomingMessage: upcomingMessage ?? this.upcomingMessage,
    );
  }

  /// Before start → upcomingMessage
  /// On end date  → lastDayMessage
  /// After end    → thankYouMessage
  /// During       → empty (show normal info)
  String get contextualMessage {
    final now = DateTime.now();

    if (startDate != null && now.isBefore(startDate!)) {
      return upcomingMessage;
    }

    if (endDate != null) {
      final lastDay = DateTime(endDate!.year, endDate!.month, endDate!.day);
      final today   = DateTime(now.year, now.month, now.day);
      if (today.isAtSameMomentAs(lastDay)) return lastDayMessage;
      if (now.isAfter(endDate!))           return thankYouMessage;
    }

    return '';
  }
}