import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'twilio_voice_wrapper_platform_interface.dart';
import 'models/call_event.dart';
import 'exceptions/twilio_voice_exception.dart';

/// An implementation of [TwilioVoiceWrapperPlatform] that uses method channels.
class MethodChannelTwilioVoiceWrapper extends TwilioVoiceWrapperPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('twilio_voice_wrapper');

  /// The event channel used to receive call events from the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel('twilio_voice_wrapper/events');

  Stream<CallEvent>? _onCallEventsStream;

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> initialize(String accessToken) async {
    try {
      await methodChannel.invokeMethod('initialize', {
        'accessToken': accessToken,
      });
    } on PlatformException catch (e) {
      throw TwilioVoiceException(
        e.message ?? 'Failed to initialize Twilio Voice',
        code: e.code,
      );
    }
  }

  @override
  Future<void> makeCall(String to, Map<String, String>? params) async {
    try {
      await methodChannel.invokeMethod('makeCall', {
        'to': to,
        'params': params ?? {},
      });
    } on PlatformException catch (e) {
      throw TwilioVoiceException(
        e.message ?? 'Failed to make call',
        code: e.code,
      );
    }
  }

  @override
  Future<void> acceptCall() async {
    try {
      await methodChannel.invokeMethod('acceptCall');
    } on PlatformException catch (e) {
      throw TwilioVoiceException(
        e.message ?? 'Failed to accept call',
        code: e.code,
      );
    }
  }

  @override
  Future<void> hangup() async {
    try {
      await methodChannel.invokeMethod('hangup');
    } on PlatformException catch (e) {
      throw TwilioVoiceException(
        e.message ?? 'Failed to hangup call',
        code: e.code,
      );
    }
  }

  @override
  Future<void> mute(bool muted) async {
    try {
      await methodChannel.invokeMethod('mute', {
        'muted': muted,
      });
    } on PlatformException catch (e) {
      throw TwilioVoiceException(
        e.message ?? 'Failed to toggle mute',
        code: e.code,
      );
    }
  }

  @override
  Future<void> setSpeaker(bool speakerOn) async {
    try {
      await methodChannel.invokeMethod('setSpeaker', {
        'speakerOn': speakerOn,
      });
    } on PlatformException catch (e) {
      throw TwilioVoiceException(
        e.message ?? 'Failed to set speaker',
        code: e.code,
      );
    }
  }

  @override
  Stream<CallEvent> get onCallEvents {
    _onCallEventsStream ??= eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => CallEvent.fromMap(Map<String, dynamic>.from(event)));
    return _onCallEventsStream!;
  }
}