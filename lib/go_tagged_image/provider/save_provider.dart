// save_provider.dart
import 'package:flutter/material.dart';

class SaveProvider extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  void startSaving() {
    _isSaving = true;
    notifyListeners();
  }

  void stopSaving() {
    _isSaving = false;
    notifyListeners();
  }
}
