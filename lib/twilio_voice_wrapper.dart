
import 'src/twilio_voice_wrapper_platform_interface.dart';
import 'src/models/call_event.dart';

// Public API exports
export 'src/enums/audio_device.dart';
export 'src/enums/call_direction.dart';
export 'src/enums/call_state.dart';
export 'src/exceptions/twilio_voice_exception.dart';
export 'src/models/call_event.dart';

/// The main entry point for Twilio Voice functionality.
/// 
/// This class provides a high-level API for making and receiving voice calls
/// using the Twilio Programmable Voice SDK.
///
/// Example usage:
/// ```dart
/// final twilioVoice = TwilioVoiceWrapper();
/// 
/// // Initialize with access token
/// await twilioVoice.initialize('your_access_token');
/// 
/// // Listen to call events
/// twilioVoice.onCallEvents.listen((event) {
///   print('Call state: ${event.state}');
/// });
/// 
/// // Make a call
/// await twilioVoice.makeCall('+1234567890');
/// ```
class TwilioVoiceWrapper {
  /// Gets the platform version (primarily for testing)
  Future<String?> getPlatformVersion() {
    return TwilioVoiceWrapperPlatform.instance.getPlatformVersion();
  }

  /// Initializes the Twilio Voice SDK with the provided access token.
  /// 
  /// The [accessToken] should be generated on your server using your Twilio
  /// Account SID and Auth Token. The token grants access to make and receive calls.
  /// 
  /// Throws [TwilioVoiceException] if initialization fails.
  Future<void> initialize(String accessToken) {
    return TwilioVoiceWrapperPlatform.instance.initialize(accessToken);
  }

  /// Makes an outgoing call to the specified destination.
  /// 
  /// [to] can be a phone number (e.g., '+1234567890') or a SIP address.
  /// [params] is an optional map of custom parameters to pass with the call.
  /// 
  /// Throws [TwilioVoiceException] if the call cannot be initiated.
  Future<void> makeCall(String to, {Map<String, String>? params}) {
    return TwilioVoiceWrapperPlatform.instance.makeCall(to, params);
  }

  /// Accepts an incoming call.
  /// 
  /// This should be called when you receive a [CallEvent] with state [CallState.ringing].
  /// 
  /// Throws [TwilioVoiceException] if there's no incoming call to accept.
  Future<void> acceptCall() {
    return TwilioVoiceWrapperPlatform.instance.acceptCall();
  }

  /// Ends the current call.
  /// 
  /// This can be used to hang up both incoming and outgoing calls.
  /// 
  /// Throws [TwilioVoiceException] if the operation fails.
  Future<void> hangup() {
    return TwilioVoiceWrapperPlatform.instance.hangup();
  }

  /// Mutes or unmutes the microphone during a call.
  /// 
  /// [muted] should be `true` to mute the microphone, `false` to unmute.
  /// 
  /// Throws [TwilioVoiceException] if the operation fails.
  Future<void> mute(bool muted) {
    return TwilioVoiceWrapperPlatform.instance.mute(muted);
  }

  /// Switches audio output between speaker and earpiece.
  /// 
  /// [speakerOn] should be `true` to route audio to the speaker, 
  /// `false` to route to the earpiece.
  /// 
  /// Throws [TwilioVoiceException] if the operation fails.
  Future<void> setSpeaker(bool speakerOn) {
    return TwilioVoiceWrapperPlatform.instance.setSpeaker(speakerOn);
  }

  /// Stream of call events that occur during the call lifecycle.
  /// 
  /// Listen to this stream to receive notifications about call state changes,
  /// incoming calls, errors, and other call-related events.
  /// 
  /// Example:
  /// ```dart
  /// twilioVoice.onCallEvents.listen((event) {
  ///   switch (event.state) {
  ///     case CallState.ringing:
  ///       print('Incoming call from ${event.from}');
  ///       break;
  ///     case CallState.connected:
  ///       print('Call connected');
  ///       break;
  ///     case CallState.disconnected:
  ///       print('Call ended');
  ///       break;
  ///     case CallState.failed:
  ///       print('Call failed: ${event.error}');
  ///       break;
  ///   }
  /// });
  /// ```
  Stream<CallEvent> get onCallEvents {
    return TwilioVoiceWrapperPlatform.instance.onCallEvents;
  }
}
