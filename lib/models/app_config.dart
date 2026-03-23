import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
// BRANDING
// ─────────────────────────────────────────

class AppBranding {
  final String appName;
  final String logoUrl;
  final String heroText;
  final String heroDesc;
  final String storeBannerTitle;
  final String storeBannerDesc;

  const AppBranding({
    required this.appName,
    required this.logoUrl,
    required this.heroText,
    required this.heroDesc,
    required this.storeBannerTitle,
    required this.storeBannerDesc,
  });

  factory AppBranding.fromMap(Map<String, dynamic> map) {
    return AppBranding(
      appName:          map['appName']          as String? ?? 'Pottery Station',
      logoUrl:          map['logoUrl']          as String? ?? '',
      heroText:         map['heroText']         as String? ?? '',
      heroDesc:         map['heroDesc']         as String? ?? '',
      storeBannerTitle: map['storeBannerTitle'] as String? ?? '',
      storeBannerDesc:  map['storeBannerDesc']  as String? ?? '',
    );
  }

  factory AppBranding.empty() => const AppBranding(
        appName:          'Pottery Station',
        logoUrl:          '',
        heroText:         'The art of intentional form.',
        heroDesc:         '',
        storeBannerTitle: '',
        storeBannerDesc:  '',
      );
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