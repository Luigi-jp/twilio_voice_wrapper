
import 'twilio_voice_wrapper_platform_interface.dart';

enum CallState {
  connecting,
  connected,
  disconnected,
  failed,
  ringing,
}

enum CallDirection {
  incoming,
  outgoing,
}

enum AudioDevice {
  earpiece,
  speaker,
}

class CallEvent {
  final CallState state;
  final CallDirection direction;
  final String? callSid;
  final String? from;
  final String? to;
  final String? error;

  const CallEvent({
    required this.state,
    required this.direction,
    this.callSid,
    this.from,
    this.to,
    this.error,
  });

  factory CallEvent.fromMap(Map<String, dynamic> map) {
    return CallEvent(
      state: CallState.values.firstWhere(
        (e) => e.toString().split('.').last == map['state'],
      ),
      direction: CallDirection.values.firstWhere(
        (e) => e.toString().split('.').last == map['direction'],
      ),
      callSid: map['callSid'],
      from: map['from'],
      to: map['to'],
      error: map['error'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'state': state.toString().split('.').last,
      'direction': direction.toString().split('.').last,
      'callSid': callSid,
      'from': from,
      'to': to,
      'error': error,
    };
  }
}

class TwilioVoiceException implements Exception {
  final String message;
  final String? code;

  const TwilioVoiceException(this.message, {this.code});

  @override
  String toString() => 'TwilioVoiceException: $message${code != null ? ' (code: $code)' : ''}';
}

class TwilioVoiceWrapper {
  Future<String?> getPlatformVersion() {
    return TwilioVoiceWrapperPlatform.instance.getPlatformVersion();
  }

  Future<void> initialize(String accessToken) {
    return TwilioVoiceWrapperPlatform.instance.initialize(accessToken);
  }

  Future<void> makeCall(String to, {Map<String, String>? params}) {
    return TwilioVoiceWrapperPlatform.instance.makeCall(to, params);
  }

  Future<void> acceptCall() {
    return TwilioVoiceWrapperPlatform.instance.acceptCall();
  }

  Future<void> hangup() {
    return TwilioVoiceWrapperPlatform.instance.hangup();
  }

  Future<void> mute(bool muted) {
    return TwilioVoiceWrapperPlatform.instance.mute(muted);
  }

  Future<void> setSpeaker(bool speakerOn) {
    return TwilioVoiceWrapperPlatform.instance.setSpeaker(speakerOn);
  }

  Stream<CallEvent> get onCallEvents {
    return TwilioVoiceWrapperPlatform.instance.onCallEvents;
  }
}
