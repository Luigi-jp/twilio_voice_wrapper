import Flutter
import UIKit
import TwilioVoice
import AVFoundation

public class TwilioVoiceWrapperPlugin: NSObject, FlutterPlugin {
  private var methodChannel: FlutterMethodChannel!
  private var eventChannel: FlutterEventChannel!
  private var eventSink: FlutterEventSink?
  
  private var accessToken: String?
  private var activeCall: Call?
  private var activeCallInvite: CallInvite?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = TwilioVoiceWrapperPlugin()
    
    instance.methodChannel = FlutterMethodChannel(name: "twilio_voice_wrapper", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: instance.methodChannel)
    
    instance.eventChannel = FlutterEventChannel(name: "twilio_voice_wrapper/events", binaryMessenger: registrar.messenger())
    instance.eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "initialize":
      initialize(call: call, result: result)
    case "makeCall":
      makeCall(call: call, result: result)
    case "acceptCall":
      acceptCall(result: result)
    case "hangup":
      hangup(result: result)
    case "mute":
      mute(call: call, result: result)
    case "setSpeaker":
      setSpeaker(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let token = arguments["accessToken"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Access token is required", details: nil))
      return
    }
    
    accessToken = token
    
    TwilioVoiceSDK.register(accessToken: token, deviceToken: nil) { error in
      if let error = error {
        result(FlutterError(code: "INITIALIZATION_ERROR", message: error.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    }
  }
  
  private func makeCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let to = arguments["to"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Destination number is required", details: nil))
      return
    }
    
    guard let token = accessToken else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "Plugin not initialized", details: nil))
      return
    }
    
    let params = arguments["params"] as? [String: String] ?? [:]
    let connectOptions = ConnectOptions(accessToken: token) { builder in
      builder.params = params
      builder.to = to
    }
    
    activeCall = TwilioVoiceSDK.connect(options: connectOptions, delegate: self)
    result(nil)
  }
  
  private func acceptCall(result: @escaping FlutterResult) {
    guard let callInvite = activeCallInvite else {
      result(FlutterError(code: "NO_INCOMING_CALL", message: "No incoming call to accept", details: nil))
      return
    }
    
    let acceptOptions = AcceptOptions(callInvite: callInvite) { builder in
      // Configure accept options if needed
    }
    
    activeCall = callInvite.accept(options: acceptOptions, delegate: self)
    activeCallInvite = nil
    result(nil)
  }
  
  private func hangup(result: @escaping FlutterResult) {
    activeCall?.disconnect()
    activeCall = nil
    result(nil)
  }
  
  private func mute(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let muted = arguments["muted"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Muted state is required", details: nil))
      return
    }
    
    activeCall?.isMuted = muted
    result(nil)
  }
  
  private func setSpeaker(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let speakerOn = arguments["speakerOn"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Speaker state is required", details: nil))
      return
    }
    
    do {
      let audioSession = AVAudioSession.sharedInstance()
      if speakerOn {
        try audioSession.overrideOutputAudioPort(.speaker)
      } else {
        try audioSession.overrideOutputAudioPort(.none)
      }
      result(nil)
    } catch {
      result(FlutterError(code: "SPEAKER_ERROR", message: error.localizedDescription, details: nil))
    }
  }
  
  private func sendCallEvent(_ event: [String: Any?]) {
    eventSink?(event)
  }
}

extension TwilioVoiceWrapperPlugin: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}

extension TwilioVoiceWrapperPlugin: CallDelegate {
  public func callDidStartRinging(call: Call) {
    sendCallEvent([
      "state": "connecting",
      "direction": "outgoing",
      "callSid": call.sid ?? "",
      "to": call.to
    ])
  }
  
  public func callDidConnect(call: Call) {
    sendCallEvent([
      "state": "connected", 
      "direction": "outgoing",
      "callSid": call.sid ?? "",
      "to": call.to
    ])
  }
  
  public func callDidFailToConnect(call: Call, error: Error) {
    sendCallEvent([
      "state": "failed",
      "direction": "outgoing", 
      "callSid": call.sid ?? "",
      "error": error.localizedDescription
    ])
    activeCall = nil
  }
  
  public func callDidDisconnect(call: Call, error: Error?) {
    sendCallEvent([
      "state": "disconnected",
      "direction": "outgoing",
      "callSid": call.sid ?? "",
      "error": error?.localizedDescription
    ])
    activeCall = nil
  }
}

extension TwilioVoiceWrapperPlugin: NotificationDelegate {
  public func callInviteReceived(callInvite: CallInvite) {
    activeCallInvite = callInvite
    sendCallEvent([
      "state": "ringing",
      "direction": "incoming",
      "callSid": callInvite.callSid,
      "from": callInvite.from,
      "to": callInvite.to
    ])
  }
  
  public func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: Error) {
    activeCallInvite = nil
    sendCallEvent([
      "state": "disconnected",
      "direction": "incoming",
      "callSid": cancelledCallInvite.callSid,
      "error": error.localizedDescription
    ])
  }
}
