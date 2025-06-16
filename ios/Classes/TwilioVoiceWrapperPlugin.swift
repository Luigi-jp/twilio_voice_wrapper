import Flutter
import UIKit
import TwilioVoice
import AVFoundation
import PushKit
import CallKit

public class TwilioVoiceWrapperPlugin: NSObject, FlutterPlugin {

    private let pushRegistry: PKPushRegistry
    private let callProvider: CXProvider
    private let callKitController: CXCallController
    private var deviceToken: Data?
    private var callInvite: CallInvite?
    private var activeCall: Call?

    public static func register(with registrar: any FlutterPluginRegistrar) {
        let instance = TwilioVoiceWrapperPlugin()

        let methodChannel = FlutterMethodChannel(name: "twilio_voice_wrapper", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        switch call.method {
        case "registerTwilio":
            guard let accessToken = arguments?["accessToken"] as? String else {
                result(FlutterError(
                    code: "MISSING_ACCESS_TOKEN",
                    message: "Device token not found.",
                    details: "Ensure the device is properly registered for push notifications."
                ))
                return
            }
            self.registerTwilio(accessToken: accessToken, result: result)
        default:
            result(nil)
        }
    }

    public override init() {
        self.pushRegistry = PKPushRegistry(queue: .main)

        let config = CXProviderConfiguration(localizedName: "twilio_voice")
        config.supportsVideo = false
        config.supportedHandleTypes = [.phoneNumber]
        config.maximumCallGroups = 1
        config.maximumCallsPerCallGroup = 1
        self.callProvider = CXProvider(configuration: config)

        self.callKitController = CXCallController()

        super.init()

        // Setup PKPushRegistry
        self.pushRegistry.delegate = self
        self.pushRegistry.desiredPushTypes = [.voIP]

        // Setup CXProvider
        self.callProvider.setDelegate(self, queue: nil)
    }
}

extension TwilioVoiceWrapperPlugin {

    func registerTwilio(accessToken: String, result: @escaping FlutterResult) {
        guard let token = self.deviceToken else {
            result(FlutterError(
                code: "MISSING_DEVICE_TOKEN",
                message: "Device token not found.",
                details: "Ensure the device is properly registered for push notifications."
            ))
            return
        }

        TwilioVoiceSDK.register(accessToken: accessToken, deviceToken: token) { error in
            if let error = error {
                result(FlutterError(
                    code: "INITIALIZATION_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
                return
            } else {
                result(nil)
                return
            }
        }
    }
}

// MARK: - PKPushRegistryDelegate
extension TwilioVoiceWrapperPlugin: PKPushRegistryDelegate {

    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if type == .voIP {
            self.deviceToken = pushCredentials.token
        }
    }

    public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        // TODO: device tokenが無効化されたので登録解除する
    }

    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        defer {
            completion()
        }

        guard type == .voIP else {
            return
        }

        TwilioVoiceSDK.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: nil)
    }
}

// MARK: - CXProviderDelegate
extension TwilioVoiceWrapperPlugin: CXProviderDelegate {

    // プロバイダがリセットされたときに呼ばれる
    public func providerDidReset(_ provider: CXProvider) {
        if let call = self.activeCall {
            let endCallAction = CXEndCallAction(call: call.uuid!)
            let transaction = CXTransaction(action: endCallAction)
            self.callKitController.request(transaction) { _ in
                // NOP
            }
        }
    }
    
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let callInvite = self.callInvite,
              callInvite.uuid.uuidString == action.callUUID.uuidString else {
            // TODO: この対応でいいか（Twilio側への対応は不要かなど）は確認が必要
            action.fail()
            return
        }

        // TODO: configure AudioSettion

        let acceptOption = AcceptOptions(callInvite: callInvite) { builder in
            builder.uuid = callInvite.uuid
        }
        let call = callInvite.accept(options: acceptOption, delegate: self)

        // TODO: CallDelegateのcallDidConnectが呼ばれたタイミングでfulfillするべきかも
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        if let callInvite = self.callInvite {
            callInvite.reject()
        } else if let call = self.activeCall {
            call.disconnect()
        }

        action.fulfill()
    }

    // ミュート状態の変更リクエストを受け取ったとき
    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard let call = self.activeCall else {
            action.fail()
            return
        }

        call.isMuted = action.isMuted
        action.fulfill()
    }
}

// MARK: - NotificationDelegate
extension TwilioVoiceWrapperPlugin: NotificationDelegate {

    // CallInviteを受信したことを通知する
    public func callInviteReceived(callInvite: CallInvite) {
        let from = (callInvite.from ?? "").replacingOccurrences(of: "client", with: "")
        let callUpdate = CXCallUpdate()
        let phoneNumber = CXHandle(type: .phoneNumber, value: from)
        callUpdate.remoteHandle = phoneNumber

        self.callProvider.reportNewIncomingCall(with: callInvite.uuid, update: callUpdate) { error in
            if error != nil {
                self.callInvite = callInvite
            }
        }
    }

    // キャンセルされたCallInviteを受信したことを通知する
    public func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: any Error) {
        guard let callInvite = self.callInvite else { return }

        let endCallAction = CXEndCallAction(call: callInvite.uuid)
        let transaction = CXTransaction(action: endCallAction)
        self.callKitController.request(transaction) { _ in
            // NOP
        }
    }
}

// MARK: - CallDelegate
extension TwilioVoiceWrapperPlugin: CallDelegate {

    // Callが接続されたことを通知する
    public func callDidConnect(call: Call) {
        self.activeCall = call
    }

    // Callが接続に失敗したことを通知する
    public func callDidFailToConnect(call: Call, error: any Error) {
        self.callProvider.reportCall(with: call.uuid!, endedAt: Date(), reason: .failed)
        self.callDisConnected()
    }

    // Callが切断されたことを通知する
    public func callDidDisconnect(call: Call, error: (any Error)?) {
        var reason = CXCallEndedReason.remoteEnded
        if error != nil {
            reason = CXCallEndedReason.failed
        }
        self.callProvider.reportCall(with: call.uuid!, endedAt: Date(), reason: reason)
        self.callDisConnected()
    }

    func callDisConnected() {
        self.callInvite = nil
        self.activeCall = nil
    }
}

//public class TwilioVoiceWrapperPlugin: NSObject, FlutterPlugin {
//  private var methodChannel: FlutterMethodChannel!
//  private var eventChannel: FlutterEventChannel!
//  private var eventSink: FlutterEventSink?
//  
//  private var accessToken: String?
//  private var activeCall: Call?
//  private var activeCallInvite: CallInvite?
//  
//  public static func register(with registrar: FlutterPluginRegistrar) {
//    let instance = TwilioVoiceWrapperPlugin()
//    
//    instance.methodChannel = FlutterMethodChannel(name: "twilio_voice_wrapper", binaryMessenger: registrar.messenger())
//    registrar.addMethodCallDelegate(instance, channel: instance.methodChannel)
//    
//    instance.eventChannel = FlutterEventChannel(name: "twilio_voice_wrapper/events", binaryMessenger: registrar.messenger())
//    instance.eventChannel.setStreamHandler(instance)
//  }
//
//  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//     switch call.method {
//     case "getPlatformVersion":
//       result("iOS " + UIDevice.current.systemVersion)
//     case "initialize":
//       initialize(call: call, result: result)
//     case "makeCall":
//       makeCall(call: call, result: result)
//     case "acceptCall":
//       acceptCall(result: result)
//     case "hangup":
//       hangup(result: result)
//     case "mute":
//       mute(call: call, result: result)
//     case "setSpeaker":
//       setSpeaker(call: call, result: result)
//     default:
//       result(FlutterMethodNotImplemented)
//     }
//  }
//  
//   private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
//     guard let arguments = call.arguments as? [String: Any],
//           let token = arguments["accessToken"] as? String else {
//       result(FlutterError(code: "INVALID_ARGUMENT", message: "Access token is required", details: nil))
//       return
//     }
//    
//     accessToken = token
//    
//     TwilioVoiceSDK.register(accessToken: token, deviceToken: "") { error in
//       if let error = error {
//         result(FlutterError(code: "INITIALIZATION_ERROR", message: error.localizedDescription, details: nil))
//       } else {
//         result(nil)
//       }
//     }
//   }
//  
//   private func makeCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
//     guard let arguments = call.arguments as? [String: Any],
//           let to = arguments["to"] as? String else {
//       result(FlutterError(code: "INVALID_ARGUMENT", message: "Destination number is required", details: nil))
//       return
//     }
//    
//     guard let token = accessToken else {
//       result(FlutterError(code: "NOT_INITIALIZED", message: "Plugin not initialized", details: nil))
//       return
//     }
//    
//     let params = arguments["params"] as? [String: String] ?? [:]
//     let connectOptions = ConnectOptions(accessToken: token) { builder in
//       builder.params = params
//       builder.to = to
//     }
//    
//     activeCall = TwilioVoiceSDK.connect(options: connectOptions, delegate: self)
//     result(nil)
//   }
//  
//   private func acceptCall(result: @escaping FlutterResult) {
//     guard let callInvite = activeCallInvite else {
//       result(FlutterError(code: "NO_INCOMING_CALL", message: "No incoming call to accept", details: nil))
//       return
//     }
//    
//     let acceptOptions = AcceptOptions(callInvite: callInvite) { builder in
//       // Configure accept options if needed
//     }
//    
//     activeCall = callInvite.accept(options: acceptOptions, delegate: self)
//     activeCallInvite = nil
//     result(nil)
//   }
//  
//   private func hangup(result: @escaping FlutterResult) {
//     activeCall?.disconnect()
//     activeCall = nil
//     result(nil)
//   }
//  
//   private func mute(call: FlutterMethodCall, result: @escaping FlutterResult) {
//     guard let arguments = call.arguments as? [String: Any],
//           let muted = arguments["muted"] as? Bool else {
//       result(FlutterError(code: "INVALID_ARGUMENT", message: "Muted state is required", details: nil))
//       return
//     }
//    
//     activeCall?.isMuted = muted
//     result(nil)
//   }
//  
//   private func setSpeaker(call: FlutterMethodCall, result: @escaping FlutterResult) {
//     guard let arguments = call.arguments as? [String: Any],
//           let speakerOn = arguments["speakerOn"] as? Bool else {
//       result(FlutterError(code: "INVALID_ARGUMENT", message: "Speaker state is required", details: nil))
//       return
//     }
//    
//     do {
//       let audioSession = AVAudioSession.sharedInstance()
//       if speakerOn {
//         try audioSession.overrideOutputAudioPort(.speaker)
//       } else {
//         try audioSession.overrideOutputAudioPort(.none)
//       }
//       result(nil)
//     } catch {
//       result(FlutterError(code: "SPEAKER_ERROR", message: error.localizedDescription, details: nil))
//     }
//   }
//  
//  private func sendCallEvent(_ event: [String: Any?]) {
//     eventSink?(event)
//  }
//}
//
//extension TwilioVoiceWrapperPlugin: FlutterStreamHandler {
//  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
//    eventSink = events
//    return nil
//  }
//  
//  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
//    eventSink = nil
//    return nil
//  }
//}
//
//extension TwilioVoiceWrapperPlugin: CallDelegate {
//  public func callDidStartRinging(call: Call) {
//    sendCallEvent([
//      "state": "connecting",
//      "direction": "outgoing",
//      "callSid": call.sid ?? "",
//      "to": call.to
//    ])
//  }
//  
//  public func callDidConnect(call: Call) {
//    sendCallEvent([
//      "state": "connected", 
//      "direction": "outgoing",
//      "callSid": call.sid ?? "",
//      "to": call.to
//    ])
//  }
//  
//  public func callDidFailToConnect(call: Call, error: Error) {
//    sendCallEvent([
//      "state": "failed",
//      "direction": "outgoing", 
//      "callSid": call.sid ?? "",
//      "error": error.localizedDescription
//    ])
//    activeCall = nil
//  }
//  
//  public func callDidDisconnect(call: Call, error: Error?) {
//    sendCallEvent([
//      "state": "disconnected",
//      "direction": "outgoing",
//      "callSid": call.sid ?? "",
//      "error": error?.localizedDescription
//    ])
//    activeCall = nil
//  }
//}
//
//extension TwilioVoiceWrapperPlugin: NotificationDelegate {
//  public func callInviteReceived(callInvite: CallInvite) {
//    activeCallInvite = callInvite
//    sendCallEvent([
//      "state": "ringing",
//      "direction": "incoming",
//      "callSid": callInvite.callSid,
//      "from": callInvite.from,
//      "to": callInvite.to
//    ])
//  }
//  
//  public func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: Error) {
//    activeCallInvite = nil
//    sendCallEvent([
//      "state": "disconnected",
//      "direction": "incoming",
//      "callSid": cancelledCallInvite.callSid,
//      "error": error.localizedDescription
//    ])
//  }
//}
