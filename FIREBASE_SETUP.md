# Firebase セットアップガイド

このアプリはFirebaseを使用しています。以下の手順に従ってFirebaseプロジェクトを設定してください。

## 1. Firebaseプロジェクトの作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 新しいプロジェクトを作成
3. プロジェクト名: `cheat-days` (任意)

## 2. Firebase CLI のインストール

```bash
# Firebase CLIをインストール
npm install -g firebase-tools

# Firebaseにログイン
firebase login

# FlutterFire CLIをインストール
dart pub global activate flutterfire_cli
```

## 3. FlutterアプリとFirebaseを連携

プロジェクトのルートディレクトリで以下を実行:

```bash
flutterfire configure
```

これにより以下のファイルが自動生成されます:
- `lib/firebase_options.dart`
- iOS/Android/Web用の設定ファイル

## 4. Firebase Authentication の有効化

1. Firebase Console で「Authentication」を開く
2. 「始める」をクリック
3. 以下のログイン方法を有効化:
   - メール/パスワード
   - Google

### Google ログインの設定 (Android)

1. Firebase Console で「Authentication > Sign-in method > Google」
2. SHA-1フィンガープリントを追加:

```bash
cd android
./gradlew signingReport
```

3. 表示されたSHA-1をFirebase Consoleに登録

### Google ログインの設定 (iOS)

1. `ios/Runner/Info.plist` に以下を追加:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- GoogleService-Info.plistのREVERSED_CLIENT_IDの値 -->
      <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
    </array>
  </dict>
</array>
```

## 5. Cloud Firestore の有効化

1. Firebase Console で「Firestore Database」を開く
2. 「データベースの作成」をクリック
3. 「本番環境モード」を選択
4. ロケーション: `asia-northeast1` (東京) を推奨

### セキュリティルールの設定

Firebase Console の「Firestore Database > ルール」で以下を設定:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーコレクション
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;

      // ユーザーのメモ
      match /memos/{memoId} {
        allow read, write: if request.auth.uid == userId;
      }
    }

    // チートデイコレクション
    match /cheatDays/{cheatDayId} {
      allow read: if resource.data.isPublic == true || request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.userId;

      // コメント
      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow delete: if request.auth.uid == resource.data.userId;
      }
    }

    // スケジュール通知
    match /scheduledNotifications/{notificationId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
  }
}
```

## 6. Firebase Storage の有効化

1. Firebase Console で「Storage」を開く
2. 「始める」をクリック
3. デフォルトのセキュリティルールで開始

### セキュリティルールの更新

Firebase Console の「Storage > ルール」で以下を設定:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /cheatDays/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

## 7. Firebase Cloud Messaging の有効化

### Android

1. Firebase Console で「プロジェクトの設定 > クラウド メッセージング」
2. Server key をコピー

`android/app/src/main/AndroidManifest.xml` に追加:

```xml
<manifest ...>
  <application ...>
    <meta-data
      android:name="com.google.firebase.messaging.default_notification_channel_id"
      android:value="high_importance_channel" />
  </application>
</manifest>
```

### iOS

1. Apple Developer でプッシュ通知証明書を作成
2. Firebase Console にアップロード

`ios/Runner/Info.plist` に追加:

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

## 8. インデックスの作成

Firestoreで複雑なクエリを実行するためのインデックス:

Firebase Console の「Firestore Database > インデックス」で以下を作成:

1. コレクション: `cheatDays`
   - フィールド: `isPublic` (昇順)
   - フィールド: `date` (降順)

2. コレクション: `cheatDays`
   - フィールド: `userId` (昇順)
   - フィールド: `date` (降順)

3. コレクション: `cheatDays/{cheatDayId}/comments`
   - フィールド: `createdAt` (降順)

## 9. アプリの実行

```bash
# 依存関係のインストール
flutter pub get

# アプリの実行
flutter run
```

## トラブルシューティング

### Android ビルドエラー

`android/build.gradle` でminSdkVersionを確認:

```gradle
minSdkVersion 21  // 最小21以上
```

### iOS ビルドエラー

```bash
cd ios
pod install
cd ..
flutter clean
flutter run
```

### Firebase初期化エラー

`lib/firebase_options.dart` が存在することを確認し、再度 `flutterfire configure` を実行

## 本番環境へのデプロイ

1. Firestore セキュリティルールの最終確認
2. Storage セキュリティルールの最終確認
3. アプリのバージョン番号を更新
4. リリースビルドの作成

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 参考リンク

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
