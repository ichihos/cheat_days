# チートデイズ ~目で食べる~

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.7.2-blue" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-Enabled-orange" alt="Firebase">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

ダイエット中にお腹がすいた時に、高カロリーの食べ物の写真を連続的に見ることで空腹を和らげる（少量のごはんで満足させる）ことを目的にしたモバイルアプリケーションです。

## 📱 主な機能

### 🎬 スライドショー機能
- 2秒間隔で自動画像切り替え
- タイマー機能（5分、10分、15分）
- リアルタイムカウントダウン表示
- 開始/停止コントロール

### 📸 チートデイ管理
- 写真のアップロード（ギャラリー/カメラ）
- 説明と日付の記録
- マイ写真のグリッド表示
- 削除機能

### 🗓️ カレンダー
- 月間カレンダー表示
- チートデイのマーカー
- 日付別写真一覧

### 📝 メモ機能
- 次のチートデイの予定メモ
- 完了/未完了の管理
- チェックリスト形式

### 🔥 Firebase統合機能
- **認証**: Google認証、メール/パスワード認証
- **共有**: 他のユーザーの写真を閲覧
- **いいね**: 写真にいいねを追加
- **コメント**: 写真にコメントを投稿
- **プッシュ通知**: チートデイリマインダー

## 🏗️ アーキテクチャ

**Clean Architecture + Riverpod** を採用

```
lib/
├── domain/              # ビジネスロジック層
│   ├── entities/        # エンティティ
│   └── repositories/    # リポジトリインターフェース
├── data/                # データ層
│   ├── models/          # データモデル
│   ├── repositories/    # リポジトリ実装
│   └── datasources/     # Firebase/ローカルストレージ
└── presentation/        # プレゼンテーション層
    ├── providers/       # Riverpod状態管理
    ├── screens/         # 画面
    └── widgets/         # 再利用可能なウィジェット
```

## 🔧 技術スタック

| カテゴリ | 技術 |
|---------|------|
| **フレームワーク** | Flutter 3.7.2 |
| **状態管理** | Riverpod 2.6.1 |
| **バックエンド** | Firebase (Auth, Firestore, Storage, Messaging) |
| **認証** | Firebase Auth, Google Sign-In |
| **画像処理** | image_picker 1.1.2 |
| **UI** | table_calendar 3.1.2 |
| **ユーティリティ** | uuid 4.5.1, intl 0.19.0 |

## 🚀 セットアップ

### 前提条件
- Flutter SDK 3.7.2以上
- Dart 3.0以上
- Firebase プロジェクト
- Android Studio / Xcode (モバイル開発用)

### インストール手順

1. **リポジトリのクローン**
```bash
git clone https://github.com/ichihos/cheat_days.git
cd cheat_days
```

2. **依存関係のインストール**
```bash
flutter pub get
```

3. **Firebaseの設定**
詳細は [FIREBASE_SETUP.md](FIREBASE_SETUP.md) を参照してください。

```bash
# Firebase CLIのインストール
npm install -g firebase-tools
firebase login

# FlutterFire CLIのインストール
dart pub global activate flutterfire_cli

# Firebaseプロジェクトと連携
flutterfire configure
```

4. **アプリの実行**
```bash
flutter run
```

## 📚 Firebase設定

以下のFirebaseサービスを有効化する必要があります：

- ✅ **Authentication** (Google, Email/Password)
- ✅ **Cloud Firestore**
- ✅ **Firebase Storage**
- ✅ **Cloud Messaging**

詳細な設定手順は [FIREBASE_SETUP.md](FIREBASE_SETUP.md) を参照してください。

## 📂 プロジェクト構造

```
cheat_days/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   └── utils/
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── auth_service.dart
│   │   │   ├── firestore_service.dart
│   │   │   ├── local_storage.dart
│   │   │   └── notification_service.dart
│   │   ├── models/
│   │   │   ├── app_user_model.dart
│   │   │   ├── cheat_day_model.dart
│   │   │   ├── cheat_memo_model.dart
│   │   │   └── comment_model.dart
│   │   └── repositories/
│   │       ├── firebase_cheat_day_repository.dart
│   │       ├── firebase_cheat_memo_repository.dart
│   │       └── firebase_comment_repository.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── app_user.dart
│   │   │   ├── cheat_day.dart
│   │   │   ├── cheat_memo.dart
│   │   │   └── comment.dart
│   │   └── repositories/
│   │       ├── cheat_day_repository.dart
│   │       ├── cheat_memo_repository.dart
│   │       └── comment_repository.dart
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── auth_provider.dart
│   │   │   ├── cheat_day_provider.dart
│   │   │   ├── cheat_memo_provider.dart
│   │   │   ├── comment_provider.dart
│   │   │   ├── firebase_providers.dart
│   │   │   └── slideshow_provider.dart
│   │   └── screens/
│   │       ├── auth/
│   │       │   ├── login_screen.dart
│   │       │   └── signup_screen.dart
│   │       ├── add_cheat_day_screen.dart
│   │       ├── calendar_screen.dart
│   │       ├── home_screen.dart
│   │       ├── memo_screen.dart
│   │       ├── my_cheat_days_screen.dart
│   │       └── slideshow_screen.dart
│   └── main.dart
├── FIREBASE_SETUP.md
└── README.md
```

## 🎨 画面構成

1. **ログイン/サインアップ画面**
   - メール/パスワード認証
   - Google認証

2. **ホーム画面**
   - 4つのタブナビゲーション
   - 目で食べる、マイ写真、カレンダー、メモ

3. **スライドショー画面**
   - 自動画像切り替え
   - タイマー設定
   - いいね・コメント機能

4. **チートデイ管理画面**
   - 写真アップロード
   - グリッド表示
   - 詳細表示

5. **カレンダー画面**
   - 月間カレンダー
   - 日付別写真一覧

6. **メモ画面**
   - 予定メモの追加
   - 完了管理

## 🔐 セキュリティ

Firestoreセキュリティルール、Firebase Storageルールが適切に設定されています。
詳細は [FIREBASE_SETUP.md](FIREBASE_SETUP.md) を参照してください。

## 📝 ライセンス

MIT License

## 👥 貢献

プルリクエストを歓迎します！

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## 📞 サポート

質問や問題がある場合は、[Issues](https://github.com/ichihos/cheat_days/issues) で報告してください。
