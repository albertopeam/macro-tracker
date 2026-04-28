extension SpeechErrorX on String {
  String get friendlyMessage {
    switch (this) {
      case 'error_no_match':
        return 'No speech detected. Please try speaking more clearly.';
      case 'error_speech_timeout':
        return 'Listening timed out. Please try again.';
      case 'error_audio':
        return 'Audio error. Please check your microphone and try again.';
      case 'error_permission':
        return 'Microphone permission denied. Please allow access in Settings.';
      case 'error_network':
        return 'Network error. Please check your internet connection.';
      case 'error_busy':
        return 'Speech recognizer is busy. Please wait a moment and try again.';
      case 'error_language_unavailable':
        return 'Language not available. Try changing your system language.';
      default:
        return 'Recognition failed. Please try again.';
    }
  }
}
