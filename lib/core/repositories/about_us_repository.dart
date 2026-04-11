import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/about_us_model.dart';

class AboutUsRepository {
  static final _db = FirebaseFirestore.instance;

  static Future<AboutUsModel> getAboutUs() async {
    try {
      final doc = await _db.collection('app_config').doc('about_us').get();
      if (doc.exists) {
        return AboutUsModel.fromDoc(doc);
      }
      return AboutUsModel.empty();
    } catch (e) {
      return AboutUsModel.empty();
    }
  }

  static Future<void> updateAboutUs(AboutUsModel aboutUs) async {
    await _db.collection('app_config').doc('about_us').set(
      aboutUs.toMap(),
      SetOptions(merge: true),
    );
  }
}
