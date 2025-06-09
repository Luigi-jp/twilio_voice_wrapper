import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_voice_wrapper/twilio_voice_wrapper.dart';
import 'package:twilio_voice_wrapper/src/twilio_voice_wrapper_platform_interface.dart';
import 'package:twilio_voice_wrapper/src/twilio_voice_wrapper_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTwilioVoiceWrapperPlatform
    with MockPlatformInterfaceMixin
    implements TwilioVoiceWrapperPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> initialize(String accessToken) => Future.value();

  @override
  Future<void> makeCall(String to, Map<String, String>? params) => Future.value();

  @override
  Future<void> acceptCall() => Future.value();

  @override
  Future<void> hangup() => Future.value();

  @override
  Future<void> mute(bool muted) => Future.value();

  @override
  Future<void> setSpeaker(bool speakerOn) => Future.value();

  @override
  Stream<CallEvent> get onCallEvents => Stream.empty();
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

  test('initialize', () async {
    TwilioVoiceWrapper twilioVoiceWrapperPlugin = TwilioVoiceWrapper();
    MockTwilioVoiceWrapperPlatform fakePlatform = MockTwilioVoiceWrapperPlatform();
    TwilioVoiceWrapperPlatform.instance = fakePlatform;

    await twilioVoiceWrapperPlugin.initialize('test_token');
    // Should complete without error
  });

  test('makeCall', () async {
    TwilioVoiceWrapper twilioVoiceWrapperPlugin = TwilioVoiceWrapper();
    MockTwilioVoiceWrapperPlatform fakePlatform = MockTwilioVoiceWrapperPlatform();
    TwilioVoiceWrapperPlatform.instance = fakePlatform;

    await twilioVoiceWrapperPlugin.makeCall('+1234567890');
    // Should complete without error
  });

  test('CallEvent fromMap', () {
    final eventMap = {
      'state': 'connected',
      'direction': 'outgoing',
      'callSid': 'test_sid',
      'from': '+1234567890',
      'to': '+0987654321',
    };

    final callEvent = CallEvent.fromMap(eventMap);

    expect(callEvent.state, CallState.connected);
    expect(callEvent.direction, CallDirection.outgoing);
    expect(callEvent.callSid, 'test_sid');
    expect(callEvent.from, '+1234567890');
    expect(callEvent.to, '+0987654321');
  });

  test('CallEvent toMap', () {
    const callEvent = CallEvent(
      state: CallState.ringing,
      direction: CallDirection.incoming,
      callSid: 'test_sid',
      from: '+1234567890',
      to: '+0987654321',
    );

    final eventMap = callEvent.toMap();

    expect(eventMap['state'], 'ringing');
    expect(eventMap['direction'], 'incoming');
    expect(eventMap['callSid'], 'test_sid');
    expect(eventMap['from'], '+1234567890');
    expect(eventMap['to'], '+0987654321');
  });
}
