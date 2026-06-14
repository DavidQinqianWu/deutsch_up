import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> initialize() async {
    await _flutterTts.setLanguage('de-DE');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> speakWord(String word) async {
    await speak(word);
  }

  Future<void> speakSentence(String sentence) async {
    await speak(sentence);
  }

  Future<void> speakWordAndSentence(String word, String sentence) async {
    await speak('$word. $sentence');
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
