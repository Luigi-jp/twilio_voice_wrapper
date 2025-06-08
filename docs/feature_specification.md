# Twilio Voice Wrapper - 機能設計書

## 1. プロジェクト概要

### 1.1 目的
Twilio Programmable Voice SDKの公式iOS・Android SDKをFlutterアプリから利用可能にするプラグインを開発する。

### 1.2 開発方針
- **MVP (Minimum Viable Product)** から開始
- Platform Channels（Method Channel + Event Channel）を使用
- 段階的な機能拡張に対応可能な設計

### 1.3 対象プラットフォーム
- iOS: Twilio Voice iOS SDK
- Android: Twilio Voice Android SDK

## 2. MVP機能仕様

### 2.1 基本通話制御
- **発信**: 電話番号・SIPアドレスへの発信
- **着信応答**: 着信通話の応答
- **通話終了**: 発信者・着信者からの通話終了

### 2.2 音声制御
- **ミュート制御**: マイクのオン/オフ
- **オーディオデバイス切り替え**: スピーカー/イヤピース

### 2.3 認証
- **アクセストークン認証**: Twilio Access Tokenによる初期化

### 2.4 状態管理
- **通話状態イベント**: connecting, connected, disconnected, failed, ringing
- **基本エラー情報**: 接続失敗、認証エラーなど

## 3. API設計

### 3.1 メインAPIクラス
- **クラス名**: `TwilioVoiceWrapper`
- **Method Channel**: `twilio_voice_wrapper`
- **Event Channel**: `twilio_voice_wrapper/events`

### 3.2 提供メソッド

| メソッド名 | パラメータ | 説明 |
|-----------|-----------|------|
| `initialize` | accessToken | SDK初期化 |
| `makeCall` | to, params | 発信開始 |
| `acceptCall` | なし | 着信応答 |
| `hangup` | なし | 通話終了 |
| `mute` | muted | ミュート制御 |
| `setSpeaker` | speakerOn | スピーカー制御 |
| `onCallEvents` | - | イベントストリーム |

## 4. データモデル設計

### 4.1 CallEvent
通話に関するイベント情報を格納するモデル

**プロパティ**:
- `state`: 通話状態（CallState enum）
- `direction`: 通話方向（CallDirection enum）
- `callSid`: 通話識別子
- `from`: 発信者情報
- `to`: 着信先情報
- `error`: エラー情報

### 4.2 列挙型定義

#### CallState
- `connecting`: 接続中
- `connected`: 通話中
- `disconnected`: 切断
- `failed`: 失敗
- `ringing`: 着信中

#### CallDirection
- `incoming`: 着信
- `outgoing`: 発信

#### AudioDevice
- `earpiece`: イヤピース
- `speaker`: スピーカー

### 4.3 例外クラス
- **TwilioVoiceException**: プラグイン固有のエラー処理

## 5. Platform Channels設計

### 5.1 Method Channel
- **チャンネル名**: `twilio_voice_wrapper`
- **用途**: Flutter → Native の非同期メソッド呼び出し
- **データ形式**: JSON互換のMap/List

### 5.2 Event Channel
- **チャンネル名**: `twilio_voice_wrapper/events`
- **用途**: Native → Flutter のリアルタイムイベント送信
- **データ形式**: CallEventオブジェクトのMap表現

## 6. 技術仕様

### 6.1 Flutter要件
- **SDK**: 2.17.0以上
- **Flutter**: 3.0.0以上

### 6.2 依存関係
- iOS: TwilioVoice SDK
- Android: Twilio Voice Android SDK
- Flutter: plugin_platform_interface

### 6.3 権限要件
- **Android**: RECORD_AUDIO, INTERNET, ACCESS_NETWORK_STATE
- **iOS**: NSMicrophoneUsageDescription

## 7. 将来の拡張計画

### Phase 2: 標準版
- 保留機能
- DTMF送信
- Bluetoothデバイス対応
- 詳細な音声品質情報
- トークン更新機能

### Phase 3: フル機能版
- 通話録音
- 会議通話
- 音声コーデック選択
- カスタムSIPヘッダー

## 8. 開発ステップ

1. **プロジェクト作成**: Flutter pluginプロジェクトの初期化
2. **Flutter側実装**: メインAPIクラスとデータモデルの実装
3. **Android側実装**: Kotlin プラグインクラスの実装
4. **iOS側実装**: Swift プラグインクラスの実装
5. **サンプルアプリ**: 動作確認用のexampleアプリ作成
6. **テスト**: ユニットテスト・結合テストの実装
7. **ドキュメント**: README、API仕様書の作成
8. **パッケージ公開**: pub.devへの公開準備