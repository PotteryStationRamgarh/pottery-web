import 'package:flutter/material.dart';

class AppRefreshProvider extends ChangeNotifier {
  int _dataVersion = 0;
  int _imageVersion = 0;

  int get dataVersion => _dataVersion;
  int get imageVersion => _imageVersion;

  void invalidateAll({bool bumpImages = true}) {
    _dataVersion++;
    if (bumpImages) {
      _imageVersion++;
    }

    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();
    notifyListeners();
  }
}
