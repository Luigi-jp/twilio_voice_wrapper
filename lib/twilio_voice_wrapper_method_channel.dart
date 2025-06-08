import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'twilio_voice_wrapper_platform_interface.dart';

/// An implementation of [TwilioVoiceWrapperPlatform] that uses method channels.
class MethodChannelTwilioVoiceWrapper extends TwilioVoiceWrapperPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('twilio_voice_wrapper');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
