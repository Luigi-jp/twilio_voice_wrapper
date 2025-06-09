/// Exception thrown by Twilio Voice operations
class TwilioVoiceException implements Exception {
  /// The error message describing what went wrong
  final String message;
  
  /// Optional error code for more specific error identification
  final String? code;

  /// Creates a new [TwilioVoiceException]
  const TwilioVoiceException(this.message, {this.code});

  @override
  String toString() => 'TwilioVoiceException: $message${code != null ? ' (code: $code)' : ''}';
}