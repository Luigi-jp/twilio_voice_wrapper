import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_voice_wrapper/twilio_voice_wrapper.dart';
import 'package:twilio_voice_wrapper/twilio_voice_wrapper_platform_interface.dart';
import 'package:twilio_voice_wrapper/twilio_voice_wrapper_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTwilioVoiceWrapperPlatform
    with MockPlatformInterfaceMixin
    implements TwilioVoiceWrapperPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final TwilioVoiceWrapperPlatform initialPlatform = TwilioVoiceWrapperPlatform.instance;

  test('$MethodChannelTwilioVoiceWrapper is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTwilioVoiceWrapper>());
  });

  test('getPlatformVersion', () async {
    TwilioVoiceWrapper twilioVoiceWrapperPlugin = TwilioVoiceWrapper();
    MockTwilioVoiceWrapperPlatform fakePlatform = MockTwilioVoiceWrapperPlatform();
    TwilioVoiceWrapperPlatform.instance = fakePlatform;

    expect(await twilioVoiceWrapperPlugin.getPlatformVersion(), '42');
  });
}
