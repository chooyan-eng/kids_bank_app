# TECH_NOTES.md — こどもぎんこう 技術仕様メモ

最終更新: 2026-02-19

---

## 1. 使用パッケージ

| パッケージ | 用途 | Phase |
|---|---|---|
| sqflite | ローカル DB（SQLite） | 1 |
| path_provider | アプリドキュメントディレクトリのパス取得 | 1 |
| uuid | UUID 生成（Child・Transaction の id） | 1 |
| intl | 日付・金額フォーマット（日本語ロケール） | 1 |
| flutter_neumorphic_plus | ニューモーフィック UI キット（全画面デザイン統一） | 1 |
| crop_your_image | 選択画像の正方形クロップ | 2 |
| draw_your_image | 手書きキャンバス | 2 |
| fl_chart | 残高推移の折れ線グラフ | 2 |

---

## 2. UI デザイン（flutter_neumorphic_plus）

### 2.1 概要

全画面・全ウィジェットを `flutter_neumorphic_plus` で統一。`MaterialApp` を `NeumorphicApp` に置き換え、Material の Scaffold/Navigator はそのまま使用する。

### 2.2 テーマ設定

```dart
NeumorphicApp(
  theme: NeumorphicThemeData(
    baseColor: Color(0xFFE8ECF0),  // 柔らかいグレー背景
    lightSource: LightSource.topLeft,
    depth: 8,
    intensity: 0.7,
  ),
)
```

### 2.3 カラーパレット

| 用途 | カラー |
|---|---|
| 背景（baseColor） | `Color(0xFFE8ECF0)` |
| 主要アクション（保存・確定） | `Color(0xFFFFB74D)` アンバー |
| 入金ボタン | `Color(0xFFA5D6A7)` ライトグリーン |
| 出金ボタン | `Color(0xFFFFCDD2)` ライトレッド |
| アバター背景 | `Color(0xFFFFCC80)` ライトオレンジ |
| 入金金額テキスト | `Color(0xFF2E7D32)` ダークグリーン |
| 出金金額テキスト | `Color(0xFFE53935)` ダークレッド |
| 利息アイコン背景 | `Color(0xFFFFE0B2)` ライトアンバー |

### 2.4 主要ウィジェット使用パターン

**カード（浮き出し）:**
```dart
Neumorphic(
  style: NeumorphicStyle(
    depth: 6,
    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(22)),
  ),
  child: ...,
)
```

**テキストフィールド（凹み）:**
```dart
Neumorphic(
  style: NeumorphicStyle(
    depth: -4,
    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(14)),
  ),
  child: TextFormField(decoration: InputDecoration(border: InputBorder.none, ...)),
)
```

**アバター（円形）:**
```dart
Neumorphic(
  style: NeumorphicStyle(
    depth: 4,
    boxShape: NeumorphicBoxShape.circle(),
    color: Color(0xFFFFCC80),
  ),
  child: SizedBox(width: size, height: size, child: ...),
)
```

**ボタン:**
```dart
NeumorphicButton(
  style: NeumorphicStyle(
    depth: 4,
    color: Color(0xFFFFB74D),
    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
  ),
  onPressed: ...,
  child: ...,
)
```

**ダイアログ（カスタム）:**
```dart
Dialog(
  backgroundColor: Colors.transparent,
  elevation: 0,
  child: Neumorphic(
    style: NeumorphicStyle(depth: 10, boxShape: ...),
    child: ...,
  ),
)
```

### 2.5 各画面の背景色

すべての `Scaffold` に `backgroundColor: NeumorphicTheme.baseColor(context)` を設定し、ニューモーフィックの統一感を保つ。

---

## 3. アーキテクチャ・状態管理

### 2.1 状態管理方針

外部の状態管理パッケージは使用しない。

| スコープ | 手法 |
|---|---|
| ウィジェット内のローカル状態 | `setState()` |
| アプリ全体の共有状態（子ども一覧・取引履歴） | `InheritedWidget` |

**InheritedWidget の構成イメージ:**

```
AppDataScope（ルート直下に配置）
  ├─ children: List<Child>
  ├─ transactions: Map<childId, List<Transaction>>
  └─ メソッド: addChild / updateChild / deleteChild
               addTransaction / loadTransactions
               checkAndApplyInterest
```

画面ウィジェットは `AppDataScope.of(context)` でデータと操作を取得する。

### 2.2 フォルダ構成

**layer-first** を採用する。

```
lib/
  models/
    child.dart
    transaction.dart
  screens/
    home_screen.dart
    child_detail_screen.dart
    child_edit_screen.dart
    icon_select_screen.dart
    drawing_canvas_screen.dart   # Phase 2
  widgets/
    transaction_dialog.dart
    child_card.dart
    avatar_widget.dart
  db/
    database.dart
  main.dart
```

### 2.3 ルーティング

**`Navigator push/pop`**（標準 API）を採用する。外部パッケージは使用しない。

```dart
// 例: 子ども詳細画面への遷移
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => ChildDetailScreen(child: child)),
);
```

---

## 3. データベース設計（sqflite）

### 3.1 テーブル定義

```sql
-- 子どもテーブル
CREATE TABLE children (
  id                       TEXT PRIMARY KEY,
  name                     TEXT NOT NULL,
  icon_type                TEXT,          -- 'gallery' | 'drawing' | NULL
  icon_image_path          TEXT,          -- NULL = 頭文字アバターで表示
  interest_rate_percent    REAL NOT NULL DEFAULT 0.0,
  balance                  REAL NOT NULL DEFAULT 0.0,
  last_interest_applied_at TEXT,          -- ISO 8601 / NULL = 未付与
  created_at               TEXT NOT NULL  -- ISO 8601
);

-- 取引履歴テーブル
CREATE TABLE transactions (
  id           TEXT PRIMARY KEY,
  child_id     TEXT NOT NULL,
  type         TEXT NOT NULL,   -- 'deposit' | 'withdrawal' | 'interest'
  amount       REAL NOT NULL,   -- 常に正の値
  balance_after REAL NOT NULL,
  memo         TEXT NOT NULL DEFAULT '',
  date         TEXT NOT NULL,   -- ISO 8601
  created_at   TEXT NOT NULL,   -- ISO 8601
  FOREIGN KEY (child_id) REFERENCES children(id) ON DELETE CASCADE
);
```

### 3.2 マイグレーション方針

- DB バージョンは `sqflite` の `version` パラメータで管理
- 初回作成: `onCreate` コールバックで全テーブルを `CREATE TABLE`
- スキーマ変更: `onUpgrade` コールバックでバージョン番号を上げ `ALTER TABLE` 等で差分適用
- `ON DELETE CASCADE` により子どもを削除すると関連取引も自動削除される

---

## 4. 画像管理

- **保存先**: `path_provider` の `getApplicationDocumentsDirectory()` 配下
  - パス例: `<appDocDir>/icons/<childId>.png`
- **ギャラリー選択フロー** (Phase 2):
  1. Method Channel 経由で iOS (Swift) のネイティブフォトライブラリ UI を呼び出す
  2. Swift 側で選択された画像データを `FlutterResult` で返す
  3. `crop_your_image` で 1:1 正方形にクロップ
  4. PNG として保存し `iconImagePath` に更新
- **手書きキャンバスフロー** (Phase 2):
  1. `draw_your_image` で描画
  2. `toImage()` → PNG エンコード → 保存

---

## 5. 利息自動付与ロジック

```dart
/// アプリ起動時と子ども詳細画面の initState() から呼び出す
void checkAndApplyInterest(Child child) {
  if (child.interestRatePercent == 0.0) return;

  final now = DateTime.now();
  final lastApplied = child.lastInterestAppliedAt ?? child.createdAt;

  if (now.difference(lastApplied).inDays < 30) return;

  // 利息 = 残高 × 年利 ÷ 12（月利）、1円未満切り捨て
  final interest = (child.balance * child.interestRatePercent / 100.0 / 12.0)
      .floorToDouble();

  if (interest <= 0.0) return;

  // Transaction(type: interest) を追加し balance と lastInterestAppliedAt を更新
}
```

---

## 6. 数値・日付フォーマット（intl）

```dart
// 金額表示: ¥1,000
final yenFormat = NumberFormat.currency(
  locale: 'ja',
  symbol: '¥',
  decimalDigits: 0,
);

// 日付表示: 2026年2月19日
final dateFormat = DateFormat('yyyy年M月d日', 'ja');

// 取引履歴の月ヘッダー: 2026年2月
final monthFormat = DateFormat('yyyy年M月', 'ja');
```

---

## 7. iOS ネイティブ連携（Method Channel）

**iOS (Swift) のみ実装する**。Android 対応は省略。

### 7.1 ギャラリー画像選択（Phase 2）

| 項目 | 内容 |
|---|---|
| チャンネル名 | `com.kids_bank_app/image_picker` |
| メソッド名 | `pickImage` |
| 戻り値 | 選択画像のバイト列（`FlutterStandardTypedData(bytes:)`）または `nil`（キャンセル時） |

**Flutter 側（Dart）:**
```dart
static const _channel = MethodChannel('com.kids_bank_app/image_picker');

Future<Uint8List?> pickImageFromGallery() async {
  final result = await _channel.invokeMethod<Uint8List>('pickImage');
  return result;
}
```

**iOS 側（Swift）— `AppDelegate.swift` または専用ハンドラ:**
```swift
// PHPickerViewController を使用（iOS 14+）
let channel = FlutterMethodChannel(
    name: "com.kids_bank_app/image_picker",
    binaryMessenger: controller.binaryMessenger
)
channel.setMethodCallHandler { call, result in
    if call.method == "pickImage" {
        // PHPickerViewController を表示し、選択画像を result() で返す
    }
}
```

---

