import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'twilio_voice_wrapper_method_channel.dart';
import 'twilio_voice_wrapper.dart';

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> initialize(String accessToken) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> makeCall(String to, Map<String, String>? params) {
    throw UnimplementedError('makeCall() has not been implemented.');
  }

  Future<void> acceptCall() {
    throw UnimplementedError('acceptCall() has not been implemented.');
  }

  Future<void> hangup() {
    throw UnimplementedError('hangup() has not been implemented.');
  }

  Future<void> mute(bool muted) {
    throw UnimplementedError('mute() has not been implemented.');
  }

  Future<void> setSpeaker(bool speakerOn) {
    throw UnimplementedError('setSpeaker() has not been implemented.');
  }

  Stream<CallEvent> get onCallEvents {
    throw UnimplementedError('onCallEvents has not been implemented.');
  }
}
