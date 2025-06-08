# Twilio Voice Wrapper - シーケンス図

## 概要

このドキュメントでは、Twilio Voice WrapperプラグインのMVP機能における処理フローをシーケンス図で示します。

## 処理フロー全体図

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant Plugin as Flutter Plugin
    participant MC as Method Channel
    participant EC as Event Channel
    participant Native as Native Plugin
    participant Twilio as Twilio SDK

    Note over App,Twilio: === 初期化フロー ===
    App->>Plugin: initialize(accessToken)
    Plugin->>MC: invokeMethod('initialize')
    MC->>Native: initialize(accessToken)
    Native->>Native: Setup Event Channel
    Native->>Twilio: Voice.register(accessToken)
    Twilio-->>Native: Registration Success/Error
    Native-->>MC: Result
    MC-->>Plugin: Result
    Plugin-->>App: Result

    Note over App,Twilio: === 発信フロー ===
    App->>Plugin: makeCall(to, params)
    Plugin->>MC: invokeMethod('makeCall')
    MC->>Native: makeCall(to, params)
    Native->>Twilio: Voice.connect(connectOptions)
    Twilio-->>Native: Call object created
    Note over Native: Store active call reference
    Native-->>MC: Success
    MC-->>Plugin: Success
    Plugin-->>App: Success

    Note over Twilio,App: === 通話状態変更通知 (Event Channel) ===
    Twilio->>Native: CallListener.onConnecting()
    Native->>EC: send(CallEvent: connecting)
    EC->>Plugin: Stream event
    Plugin->>App: onCallEvents stream

    Twilio->>Native: CallListener.onConnected()
    Native->>EC: send(CallEvent: connected)
    EC->>Plugin: Stream event
    Plugin->>App: onCallEvents stream

    Note over App,Twilio: === 着信フロー ===
    Twilio->>Native: onIncomingCall(callInvite)
    Native->>EC: send(CallEvent: ringing)
    EC->>Plugin: Stream event
    Plugin->>App: onCallEvents stream
    
    App->>Plugin: acceptCall()
    Plugin->>MC: invokeMethod('acceptCall')
    MC->>Native: acceptCall()
    Native->>Twilio: callInvite.accept()
    Twilio-->>Native: Call object created
    Native-->>MC: Success
    MC-->>Plugin: Success
    Plugin-->>App: Success

    Twilio->>Native: CallListener.onConnected()
    Native->>EC: send(CallEvent: connected)
    EC->>Plugin: Stream event
    Plugin->>App: onCallEvents stream

    Note over App,Twilio: === 通話終了フロー ===
    App->>Plugin: hangup()
    Plugin->>MC: invokeMethod('hangup')
    MC->>Native: hangup()
    Native->>Twilio: call.disconnect()
    Twilio-->>Native: Disconnect initiated
    Native-->>MC: Success
    MC-->>Plugin: Success
    Plugin-->>App: Success

    Twilio->>Native: CallListener.onDisconnected()
    Native->>EC: send(CallEvent: disconnected)
    EC->>Plugin: Stream event
    Plugin->>App: onCallEvents stream

    Note over App,Twilio: === 音声制御フロー ===
    App->>Plugin: mute(true)
    Plugin->>MC: invokeMethod('mute')
    MC->>Native: mute(true)
    Native->>Twilio: call.mute(true)
    Twilio-->>Native: Mute applied
    Native-->>MC: Success
    MC-->>Plugin: Success
    Plugin-->>App: Success

    App->>Plugin: setSpeaker(true)
    Plugin->>MC: invokeMethod('setSpeaker')
    MC->>Native: setSpeaker(true)
    Native->>Native: AudioManager configuration
    Native-->>MC: Success
    MC-->>Plugin: Success
    Plugin-->>App: Success

    Note over App,Twilio: === エラー処理フロー ===
    Twilio->>Native: CallListener.onError(error)
    Native->>EC: send(CallEvent: failed, error)
    EC->>Plugin: Stream event
    Plugin->>App: onCallEvents stream
    App->>App: Display error UI
```

## 詳細フロー

### 1. 初期化フロー

SDK の初期化とEvent Channel の設定を行います。

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant Plugin as Flutter Plugin
    participant MC as Method Channel
    participant EC as Event Channel
    participant Native as Native Plugin
    participant Twilio as Twilio SDK

    App->>Plugin: initialize(accessToken)
    Plugin->>MC: invokeMethod('initialize', {accessToken})
    MC->>Native: TwilioVoiceWrapperPlugin.initialize()
    
    Note over Native: Event Channel Setup
    Native->>EC: Configure event stream handler
    
    Note over Native: Twilio SDK Initialize
    Native->>Twilio: Voice.register(accessToken, listener)
    Twilio-->>Native: RegistrationListener.onSuccess()
    
    Native-->>MC: Success result
    MC-->>Plugin: Success
    Plugin-->>App: Initialization complete
```

### 2. 発信フロー

電話番号またはSIPアドレスへの発信を開始します。

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant Plugin as Flutter Plugin
    participant MC as Method Channel
    participant EC as Event Channel
    participant Native as Native Plugin
    participant Twilio as Twilio SDK

    App->>Plugin: makeCall(to, params)
    Plugin->>MC: invokeMethod('makeCall', {to, params})
    MC->>Native: makeCall(to, params)
    
    Note over Native: Create Connect Options
    Native->>Native: ConnectOptions.Builder()
    
    Native->>Twilio: Voice.connect(connectOptions, callListener)
    Twilio-->>Native: Call object
    
    Note over Native: Store active call
    Native->>Native: activeCall = call
    
    Native-->>MC: Success
    MC-->>Plugin: Success
    Plugin-->>App: Call initiated
    
    Note over Native,App: Async state updates
    Twilio->>Native: CallListener.onConnecting()
    Native->>EC: CallEvent(state: connecting)
    EC->>App: onCallEvents.listen()
    
    Twilio->>Native: CallListener.onConnected()
    Native->>EC: CallEvent(state: connected)
    EC->>App: onCallEvents.listen()
```

### 3. 着信応答フロー

着信通話の受信と応答処理を行います。

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant Plugin as Flutter Plugin
    participant MC as Method Channel
    participant EC as Event Channel
    participant Native as Native Plugin
    participant Twilio as Twilio SDK

    Note over Twilio,Native: Incoming call received
    Twilio->>Native: RegistrationListener.onIncomingCall(callInvite)
    
    Note over Native: Store call invite
    Native->>Native: activeCallInvite = callInvite
    
    Native->>EC: CallEvent(state: ringing, from: caller)
    EC->>App: onCallEvents.listen()
    
    Note over App: User accepts call
    App->>Plugin: acceptCall()
    Plugin->>MC: invokeMethod('acceptCall')
    MC->>Native: acceptCall()
    
    Native->>Twilio: callInvite.accept(context, callListener)
    Twilio-->>Native: Call object
    
    Note over Native: Update active call
    Native->>Native: activeCall = call, activeCallInvite = null
    
    Native-->>MC: Success
    MC-->>Plugin: Success
    Plugin-->>App: Call accepted
    
    Note over Native,App: Connection established
    Twilio->>Native: CallListener.onConnected()
    Native->>EC: CallEvent(state: connected)
    EC->>App: onCallEvents.listen()
```

## Platform Channels 詳細

### Method Channel
- **チャンネル名**: `twilio_voice_wrapper`
- **用途**: 同期的な操作指示
- **メソッド一覧**:
  - `initialize`
  - `makeCall`
  - `acceptCall`
  - `hangup`
  - `mute`
  - `setSpeaker`

### Event Channel
- **チャンネル名**: `twilio_voice_wrapper/events`
- **用途**: 非同期の状態通知
- **イベント内容**: CallEvent オブジェクト

## エラーハンドリング

### 操作エラー
Method Channel のレスポンスでエラー情報を返します。

### 非同期エラー
Event Channel で `CallEvent(state: failed, error: message)` を送信します。

## 実装時の考慮点

1. **Native側でのCall オブジェクト管理**
   - アクティブな通話の参照を保持
   - CallInvite と Call の適切な管理

2. **Event Channel の初期化タイミング**
   - SDK初期化時に Event Channel も準備
   - アプリ起動時から状態監視可能

3. **スレッド管理**
   - Twilio SDK のコールバックは適切なスレッドで処理
   - UI更新のためのメインスレッド考慮

4. **状態管理**
   - 通話状態の整合性を保持
   - 複数の状態変更イベントの順序管理