
import 'twilio_voice_wrapper_platform_interface.dart';

class TwilioVoiceWrapper {
  Future<String?> getPlatformVersion() {
    return TwilioVoiceWrapperPlatform.instance.getPlatformVersion();
  }
}
