import 'package:cloud_firestore/cloud_firestore.dart';

class AboutUsModel {
  final String intro;
  final String introImage;
  final String artisanName1;
  final String artisanAbout1;
  final String artisanName2;
  final String artisanAbout2;
  final List<String> procedureHead;
  final List<String> procedureDesc;
  final List<String> procedureImage;

  AboutUsModel({
    required this.intro,
    required this.introImage,
    required this.artisanName1,
    required this.artisanAbout1,
    required this.artisanName2,
    required this.artisanAbout2,
    required this.procedureHead,
    required this.procedureDesc,
    required this.procedureImage,
  });

  factory AboutUsModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return AboutUsModel(
      intro: map['intro'] as String? ?? '',
      introImage: map['introImage'] as String? ?? '',
      artisanName1: map['artisanName1'] as String? ?? '',
      artisanAbout1: map['artisanAbout1'] as String? ?? '',
      artisanName2: map['artisanName2'] as String? ?? '',
      artisanAbout2: map['artisanAbout2'] as String? ?? '',
      procedureHead: List<String>.from(map['procedureHead'] ?? []),
      procedureDesc: List<String>.from(map['procedureDesc'] ?? []),
      procedureImage: List<String>.from(map['procedureImage'] ?? []),
    );
  }

  factory AboutUsModel.empty() {
    return AboutUsModel(
      intro: '',
      introImage: '',
      artisanName1: '',
      artisanAbout1: '',
      artisanName2: '',
      artisanAbout2: '',
      procedureHead: [],
      procedureDesc: [],
      procedureImage: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'intro': intro,
      'introImage': introImage,
      'artisanName1': artisanName1,
      'artisanAbout1': artisanAbout1,
      'artisanName2': artisanName2,
      'artisanAbout2': artisanAbout2,
      'procedureHead': procedureHead,
      'procedureDesc': procedureDesc,
      'procedureImage': procedureImage,
    };
  }
}
