import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/media_service.dart';

class AdminBrandingController {
  // ── Image state ──
  String currentLogoUrl = '';
  String currentAuthUrl = '';
  String currentHeroUrl = '';    // ← NEW

  Uint8List? newLogoBytes;
  Uint8List? newAuthBytes;
  Uint8List? newHeroBytes;       // ← NEW

  // ── Branding ──
  final appNameCtrl     = TextEditingController();
  final heroTextCtrl    = TextEditingController();
  final heroDescCtrl    = TextEditingController();
  final bannerTitleCtrl = TextEditingController();
  final bannerDescCtrl  = TextEditingController();

  // ── Contact ──
  final addressCtrl = TextEditingController();
  final emailCtrl   = TextEditingController();
  final phoneCtrl   = TextEditingController();

  // ── Content ──
  final aboutCtrl   = TextEditingController();
  final helpCtrl    = TextEditingController();
  final privacyCtrl = TextEditingController();
  final termsCtrl   = TextEditingController();

  // ── Social ──
  final igCtrl  = TextEditingController();
  final fbCtrl  = TextEditingController();
  final webCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final MediaService _media = MediaService();

  Future<void> loadAll() async {
    final results = await Future.wait([
      FirestoreService.getBranding(),
      FirestoreService.getContact(),
      FirestoreService.getContent(),
      FirestoreService.getSocial(),
    ]);

    final branding = results[0] as dynamic;
    final contact  = results[1] as dynamic;
    final content  = results[2] as dynamic;
    final social   = results[3] as dynamic;

    currentLogoUrl       = branding.logoUrl          as String? ?? '';
    currentAuthUrl       = branding.authImageUrl     as String? ?? '';
    currentHeroUrl       = branding.heroImageUrl     as String? ?? '';  // ← NEW
    appNameCtrl.text     = branding.appName          as String? ?? '';
    heroTextCtrl.text    = branding.heroText         as String? ?? '';
    heroDescCtrl.text    = branding.heroDesc         as String? ?? '';
    bannerTitleCtrl.text = branding.storeBannerTitle as String? ?? '';
    bannerDescCtrl.text  = branding.storeBannerDesc  as String? ?? '';

    addressCtrl.text = contact.address      as String? ?? '';
    emailCtrl.text   = contact.supportEmail as String? ?? '';
    phoneCtrl.text   = contact.supportPhone as String? ?? '';

    aboutCtrl.text   = content.aboutUs         as String? ?? '';
    helpCtrl.text    = content.helpText        as String? ?? '';
    privacyCtrl.text = content.privacyPolicy   as String? ?? '';
    termsCtrl.text   = content.termsConditions as String? ?? '';

    igCtrl.text  = social.instagramUrl as String? ?? '';
    fbCtrl.text  = social.facebookUrl  as String? ?? '';
    webCtrl.text = social.websiteUrl   as String? ?? '';
  }

  Future<Uint8List?> pickImage(String type) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (type == 'logo') newLogoBytes = bytes;
    if (type == 'auth') newAuthBytes = bytes;
    if (type == 'hero') newHeroBytes = bytes;  // ← NEW
    return bytes;
  }

  Future<void> saveAll() async {
    String logoUrl = currentLogoUrl;
    String authUrl = currentAuthUrl;
    String heroUrl = currentHeroUrl;  // ← NEW

    // Fixed R2 paths — uploading overwrites the old file automatically
    if (newLogoBytes != null) {
      final urls = await _media.uploadImages(
        docId: 'logo.png', pathPrefix: 'branding', files: [newLogoBytes!],
      );
      logoUrl = urls.first;
    }

    if (newAuthBytes != null) {
      final urls = await _media.uploadImages(
        docId: 'auth.png', pathPrefix: 'branding', files: [newAuthBytes!],
      );
      authUrl = urls.first;
    }

    if (newHeroBytes != null) {  // ← NEW
      final urls = await _media.uploadImages(
        docId: 'hero.png', pathPrefix: 'branding', files: [newHeroBytes!],
      );
      heroUrl = urls.first;
    }

    await Future.wait(<Future>[
      FirestoreService.updateConfig('branding', {
        'appName':          appNameCtrl.text.trim(),
        'heroText':         heroTextCtrl.text.trim(),
        'heroDesc':         heroDescCtrl.text.trim(),
        'storeBannerTitle': bannerTitleCtrl.text.trim(),
        'storeBannerDesc':  bannerDescCtrl.text.trim(),
        'logoUrl':          logoUrl,
        'authImageUrl':     authUrl,
        'heroImageUrl':     heroUrl,  // ← NEW
      }),
      FirestoreService.updateConfig('contact', {
        'address':      addressCtrl.text.trim(),
        'supportEmail': emailCtrl.text.trim(),
        'supportPhone': phoneCtrl.text.trim(),
      }),
      FirestoreService.updateConfig('content', {
        'aboutUs':         aboutCtrl.text.trim(),
        'helpText':        helpCtrl.text.trim(),
        'privacyPolicy':   privacyCtrl.text.trim(),
        'termsConditions': termsCtrl.text.trim(),
      }),
      FirestoreService.updateConfig('social', {
        'instagramUrl': igCtrl.text.trim(),
        'facebookUrl':  fbCtrl.text.trim(),
        'websiteUrl':   webCtrl.text.trim(),
      }),
    ]);

    currentLogoUrl = logoUrl;
    currentAuthUrl = authUrl;
    currentHeroUrl = heroUrl;  // ← NEW
    newLogoBytes   = null;
    newAuthBytes   = null;
    newHeroBytes   = null;     // ← NEW
  }

  void dispose() {
    appNameCtrl.dispose();
    heroTextCtrl.dispose();
    heroDescCtrl.dispose();
    bannerTitleCtrl.dispose();
    bannerDescCtrl.dispose();
    addressCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    aboutCtrl.dispose();
    helpCtrl.dispose();
    privacyCtrl.dispose();
    termsCtrl.dispose();
    igCtrl.dispose();
    fbCtrl.dispose();
    webCtrl.dispose();
  }
}