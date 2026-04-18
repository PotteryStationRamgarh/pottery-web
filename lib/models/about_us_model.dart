import 'package:cloud_firestore/cloud_firestore.dart';

class AboutUsModel {
  final String intro;
  final String introImage;

  // Artisan 1
  final String artisanName1;
  final String artisanRole1;
  final String artisanAbout1;
  final String artisanPic1; // stored as 'artisianPic1' in Firestore (typo preserved)

  // Artisan 2
  final String artisanName2;
  final String artisanRole2;
  final String artisanAbout2;
  final String artisanPic2; // stored as 'artisianPic2' in Firestore (typo preserved)

  // Procedure / materials cards
  final List<String> procedureHead;
  final List<String> procedureDesc;
  final List<String> procedureImage;

  // Sustainability banner
  final String sustainabilityTitle;
  final String sustainabilityBody;

  AboutUsModel({
    required this.intro,
    required this.introImage,
    required this.artisanName1,
    required this.artisanRole1,
    required this.artisanAbout1,
    required this.artisanPic1,
    required this.artisanName2,
    required this.artisanRole2,
    required this.artisanAbout2,
    required this.artisanPic2,
    required this.procedureHead,
    required this.procedureDesc,
    required this.procedureImage,
    required this.sustainabilityTitle,
    required this.sustainabilityBody,
  });

  factory AboutUsModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return AboutUsModel(
      intro: map['intro'] as String? ?? '',
      introImage: map['introImage'] as String? ?? '',
      artisanName1: map['artisanName1'] as String? ?? '',
      artisanRole1: map['artisanRole1'] as String? ?? '',
      artisanAbout1: map['artisanAbout1'] as String? ?? '',
      // Firestore has a typo: 'artisian' (not 'artisan') — read both for compat
      artisanPic1: (map['artisianPic1'] ?? map['artisanPic1'] ?? '') as String,
      artisanName2: map['artisanName2'] as String? ?? '',
      artisanRole2: map['artisanRole2'] as String? ?? '',
      artisanAbout2: map['artisanAbout2'] as String? ?? '',
      artisanPic2: (map['artisianPic2'] ?? map['artisanPic2'] ?? '') as String,
      procedureHead: List<String>.from(map['procedureHead'] ?? []),
      procedureDesc: List<String>.from(map['procedureDesc'] ?? []),
      procedureImage: List<String>.from(map['procedureImage'] ?? []),
      sustainabilityTitle: map['sustainabilityTitle'] as String? ?? '',
      sustainabilityBody: map['sustainabilityBody'] as String? ?? '',
    );
  }

  factory AboutUsModel.empty() => AboutUsModel(
    intro: '',
    introImage: '',
    artisanName1: '',
    artisanRole1: '',
    artisanAbout1: '',
    artisanPic1: '',
    artisanName2: '',
    artisanRole2: '',
    artisanAbout2: '',
    artisanPic2: '',
    procedureHead: [],
    procedureDesc: [],
    procedureImage: [],
    sustainabilityTitle: '',
    sustainabilityBody: '',
  );

  Map<String, dynamic> toMap() => {
    'intro': intro,
    'introImage': introImage,
    'artisanName1': artisanName1,
    'artisanRole1': artisanRole1,
    'artisanAbout1': artisanAbout1,
    // Write to BOTH keys to fix the Firestore typo going forward
    'artisianPic1': artisanPic1,
    'artisanName2': artisanName2,
    'artisanRole2': artisanRole2,
    'artisanAbout2': artisanAbout2,
    'artisianPic2': artisanPic2,
    'procedureHead': procedureHead,
    'procedureDesc': procedureDesc,
    'procedureImage': procedureImage,
    'sustainabilityTitle': sustainabilityTitle,
    'sustainabilityBody': sustainabilityBody,
  };
}
