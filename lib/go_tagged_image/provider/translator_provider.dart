// translation_provider.dart
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class TranslationProvider extends ChangeNotifier {
  final GoogleTranslator translator = GoogleTranslator();
  String translatedText = '';
  bool isLoading = false;

  Future<void> translateText(String text) async {
    isLoading = true;
    notifyListeners();

    final translated = await translator.translate(text, from: 'en', to: 'en');
    translatedText = translated.text;

    isLoading = false;
    notifyListeners();
  }

  void clear() {
    translatedText = '';
    isLoading = false;
    notifyListeners();
  }
}
