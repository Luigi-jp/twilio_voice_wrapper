twilio_voice_wrapper/
├── docs/                                  # ドキュメント管理
│   ├── design/                           # 設計ドキュメント
│   │   ├── feature_specification.md     # 機能設計書
│   │   └── sequence_diagrams.md         # シーケンス図
│   ├── api/                              # API仕様書
│   │   └── api_reference.md             # API リファレンス
│   └── development/                      # 開発ドキュメント
│       ├── setup_guide.md               # セットアップガイド
│       └── contribution_guide.md        # コントリビューションガイド
├── lib/
│   ├── twilio_voice_wrapper.dart         # メインAPIクラス
│   └── src/
│       ├── models/                       # データモデル
│       ├── enums/                        # 列挙型定義
│       └── exceptions/                   # 例外クラス
├── android/
│   └── src/main/kotlin/                  # Android実装
├── ios/
│   └── Classes/                          # iOS実装
├── example/                              # サンプルアプリ
├── test/                                 # テストコード
└── pubspec.yaml                          # パッケージ設定