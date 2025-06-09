import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models/call_event.dart';
import 'twilio_voice_wrapper_method_channel.dart';

/// The interface that implementations of twilio_voice_wrapper must implement.
///
/// Platform implementations should extend this class rather than implement it as `TwilioVoiceWrapper`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [TwilioVoiceWrapperPlatform] methods.
abstract class TwilioVoiceWrapperPlatform extends PlatformInterface {
  /// Constructs a TwilioVoiceWrapperPlatform.
  TwilioVoiceWrapperPlatform() : super(token: _token);

  static final Object _token = Object();

  static TwilioVoiceWrapperPlatform _instance = MethodChannelTwilioVoiceWrapper();

  /// The default instance of [TwilioVoiceWrapperPlatform] to use.
  ///
  /// Defaults to [MethodChannelTwilioVoiceWrapper].
  static TwilioVoiceWrapperPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TwilioVoiceWrapperPlatform] when
  /// they register themselves.
  static set instance(TwilioVoiceWrapperPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Gets the platform version (for testing purposes)
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Initializes the Twilio Voice SDK with the provided access token
  Future<void> initialize(String accessToken) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Makes an outgoing call to the specified destination
  Future<void> makeCall(String to, Map<String, String>? params) {
    throw UnimplementedError('makeCall() has not been implemented.');
  }

  /// Accepts an incoming call
  Future<void> acceptCall() {
    throw UnimplementedError('acceptCall() has not been implemented.');
  }

  /// Ends the current call
  Future<void> hangup() {
    throw UnimplementedError('hangup() has not been implemented.');
  }

  /// Mutes or unmutes the current call
  Future<void> mute(bool muted) {
    throw UnimplementedError('mute() has not been implemented.');
  }

  /// Switches audio output between speaker and earpiece
  Future<void> setSpeaker(bool speakerOn) {
    throw UnimplementedError('setSpeaker() has not been implemented.');
  }

  /// Stream of call events that occur during call lifecycle
  Stream<CallEvent> get onCallEvents {
    throw UnimplementedError('onCallEvents has not been implemented.');
  }
}