# CLAUDE.md

このファイルは、このリポジトリでコードを使用する際のClaude Code (claude.ai/code) へのガイダンスを提供します。

## 開発コマンド

### テスト実行
```bash
# すべてのテストを実行
flutter test

# 単一テストファイルを実行
flutter test test/twilio_voice_wrapper_test.dart
```

### リント
```bash
flutter analyze
```

### 依存関係管理
```bash
# 依存関係のインストール
flutter pub get

# パッケージの更新
flutter pub upgrade
```

### プラットフォーム固有の開発
```bash
# Android用のビルド（example/androidディレクトリで実行）
cd example && flutter build apk

# iOS用のビルド（example/iosディレクトリで実行）
cd example && flutter build ios
```

## アーキテクチャ構造

### プラグインアーキテクチャ
このプロジェクトは標準的なFlutterプラグインアーキテクチャを採用しています：

- **Dart API Layer** (`lib/twilio_voice_wrapper.dart`): メインのパブリックAPI
- **Platform Interface** (`lib/twilio_voice_wrapper_platform_interface.dart`): プラットフォーム固有実装の抽象化レイヤー
- **Method Channel Implementation** (`lib/twilio_voice_wrapper_method_channel.dart`): MethodChannelを使用したネイティブコードとの通信
- **Native Android** (`android/src/main/kotlin/`): Kotlin実装
- **Native iOS** (`ios/Classes/`): Swift実装

### メソッドチャネル通信
プラグインは `'twilio_voice_wrapper'` という名前のMethodChannelを使用してFlutterとネイティブコード間の通信を行います。現在実装されているメソッド：
- `getPlatformVersion`: プラットフォームのバージョン情報を取得

### プラットフォーム実装
- Android: `com.example.twilio_voice_wrapper` パッケージ内の `TwilioVoiceWrapperPlugin.kt`
- iOS: `TwilioVoiceWrapperPlugin.swift`

新しいメソッドを追加する際は、以下の3箇所を更新する必要があります：
1. Platform Interfaceに抽象メソッドを追加
2. Method Channel実装にDart側の実装を追加  
3. Android/iOS両方のネイティブ実装にメソッドハンドラーを追加

### テスト構造
- モックプラットフォーム実装を使用したユニットテスト
- Platform Interface パターンによりテスタビリティを確保