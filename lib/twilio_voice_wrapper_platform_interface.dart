import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'twilio_voice_wrapper_method_channel.dart';

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
}
