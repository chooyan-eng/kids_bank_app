# TASKS.md — こどもぎんこう タスク一覧

最終更新: 2026-02-19

凡例: ⬜ 未着手 / 🔄 作業中 / ✅ 完了

---

## Phase 1: MVP

### T01 プロジェクト初期設定

| # | タスク | 詳細 |
|---|---|---|
| T01-1 | ✅ pubspec.yaml にパッケージ追加 | `sqflite`, `path_provider`, `uuid`, `intl` を dependencies に追加 |
| T01-2 | ✅ 依存関係を解決 | `fvm flutter pub get` |
| T01-3 | ✅ フォルダ構成を作成 | `lib/models/`, `lib/screens/`, `lib/widgets/`, `lib/db/`, `lib/services/` を作成 |

---

### T02 データクラス（models/）

| # | タスク | 詳細 |
|---|---|---|
| T02-1 | ⬜ `transaction_type.dart` | `enum TransactionType { deposit, withdrawal, interest }` |
| T02-2 | ⬜ `child.dart` | Child クラス。フィールド・`fromMap` / `toMap` / `copyWith` を実装 |
| T02-3 | ⬜ `transaction.dart` | Transaction クラス。フィールド・`fromMap` / `toMap` を実装 |

---

### T03 リポジトリ抽象インターフェース（db/）

| # | タスク | 詳細 |
|---|---|---|
| T03-1 | ⬜ `app_repository.dart` | abstract class `AppRepository` を定義。下記メソッドを宣言する |

```dart
abstract class AppRepository {
  Future<List<Child>> loadChildren();
  Future<void> saveChild(Child child);
  Future<void> updateChild(Child child);
  Future<void> deleteChild(String childId);

  Future<List<Transaction>> loadTransactions(String childId);
  Future<void> saveTransaction(Transaction transaction);

  // balance と lastInterestAppliedAt をアトミックに更新
  Future<void> updateChildBalance(
    String childId,
    double newBalance, {
    DateTime? lastInterestAppliedAt,
  });
}
```

---

### T04 ダミーリポジトリ（db/）

| # | タスク | 詳細 |
|---|---|---|
| T04-1 | ⬜ `dummy_repository.dart` | `AppRepository` を実装。ハードコードのダミーデータを返すインメモリ実装 |

ダミーデータの内容（例）:
- 子ども 2 人（名前・残高・利率あり）
- 各子どもに取引履歴 3〜5 件

---

### T05 InheritedWidget（widgets/）

| # | タスク | 詳細 |
|---|---|---|
| T05-1 | ⬜ `app_data_scope.dart` | `AppDataScope` を実装（下記仕様） |

`AppDataScope` の仕様:
- `AppRepository` を注入して保持する（DI）
- `children: List<Child>` と `transactions: Map<String, List<Transaction>>` をステートとして保持
- 画面から呼び出すメソッドを公開:
  - `addChild(Child)`, `updateChild(Child)`, `deleteChild(String)`
  - `addTransaction(Transaction)` — balance / lastInterestAppliedAt も同時に更新
  - `loadTransactionsFor(String childId)` — 未ロードなら Repository から取得
  - `checkAndApplyInterest(Child)` — 1ヶ月経過判定・自動付与
- `AppDataScope.of(context)` で取得できるよう `static` メソッドを提供

---

### T06 アプリ基盤・テーマ

| # | タスク | 詳細 |
|---|---|---|
| T06-1 | ⬜ `main.dart` を書き換え | `AppDataScope`（DummyRepository を注入）をルートに配置。`MaterialApp` に Material 3 テーマ（暖色系 ColorScheme）を設定 |

---

### T07 UI 実装（ダミーデータで動作確認）

ウィジェット・画面は `AppDataScope.of(context)` からデータを取得する。

| # | タスク | 画面/ウィジェット | 主な実装内容 |
|---|---|---|---|
| T07-1 | ⬜ `avatar_widget.dart` | 共通 | 名前の頭文字を円形に表示するウィジェット |
| T07-2 | ⬜ `child_card.dart` | S01 用 | アイコン・名前・残高・利率・「入金」「出金」ボタンを持つカード |
| T07-3 | ⬜ `home_screen.dart` | S01 | カード一覧（ListView）、FAB（子ども追加）、空状態の案内 |
| T07-4 | ⬜ `transaction_dialog.dart` | D01 | 入金/出金セグメント・金額・日付・メモ入力。「確定」で `addTransaction()` を呼ぶ |
| T07-5 | ⬜ `child_detail_screen.dart` | S02 | ヘッダー（残高・利率）・取引履歴リスト（月ヘッダー区切り）・入金/出金ボタン・編集/削除メニュー |
| T07-6 | ⬜ `child_edit_screen.dart` | S03 | 名前・利率フォーム。新規追加と編集を兼用。「保存」で `addChild()` / `updateChild()` を呼ぶ |

---

### T08 SQLite リポジトリ実装（db/）

| # | タスク | 詳細 |
|---|---|---|
| T08-1 | ⬜ `database.dart` | `openDatabase()` でDBを開く。`onCreate` で `children` / `transactions` テーブルを作成（TECH_NOTES.md のDDL参照）。`onUpgrade` のスケルトンを用意 |
| T08-2 | ⬜ `sqlite_repository.dart` | `AppRepository` を SQLite で実装。`loadChildren`, `saveChild`, `updateChild`, `deleteChild`, `loadTransactions`, `saveTransaction`, `updateChildBalance` をすべて実装 |

---

### T09 ダミー → SQLite への切り替え

| # | タスク | 詳細 |
|---|---|---|
| T09-1 | ⬜ `main.dart` を更新 | `DummyRepository` → `SqliteRepository` に差し替え |
| T09-2 | ⬜ 起動時データロード | `AppDataScope` の初期化時に `loadChildren()` を呼び、全子どものデータをステートに読み込む |

---

### T10 利息自動付与の接続

| # | タスク | 詳細 |
|---|---|---|
| T10-1 | ⬜ `home_screen.dart` の `initState` | 起動時に全子どもに対して `checkAndApplyInterest()` を呼ぶ |
| T10-2 | ⬜ `child_detail_screen.dart` の `initState` | 詳細画面を開いたタイミングでも `checkAndApplyInterest()` を呼ぶ |

---

### T11 動作確認・仕上げ

| # | タスク | 詳細 |
|---|---|---|
| T11-1 | ⬜ macOS で起動確認 | `fvm flutter run -d macos` でエラーなく起動することを確認 |
| T11-2 | ⬜ スモークテスト | 子ども追加 → 入金 → 出金 → 履歴確認 → 再起動後にデータが保持されているか確認 |
| T11-3 | ⬜ 利息テスト | `lastInterestAppliedAt` を 31 日前に手動設定し、起動時に自動付与されることを確認 |

---

## Phase 2

---

### P2-T01 ギャラリーアイコン

**概要**: Method Channel (iOS Swift) でフォトライブラリから画像を取得し、`crop_your_image` で正方形クロップしてアイコンに設定する。

| # | タスク | 詳細 |
|---|---|---|
| P2-T01-1 | ⬜ pubspec に `crop_your_image` を追加 | `fvm flutter pub get` で依存解決 |
| P2-T01-2 | ⬜ `Info.plist` に権限を追加 | `NSPhotoLibraryUsageDescription` を記載（例: "アイコン用の写真を選択するために使用します"） |
| P2-T01-3 | ⬜ iOS Method Channel ハンドラを実装 | `AppDelegate.swift` または専用クラスで `com.kids_bank_app/image_picker` チャンネルを登録。`PHPickerViewController`（iOS 14+）を表示し、選択画像を `Data` (JPEG) として `FlutterResult` で返す |
| P2-T01-4 | ⬜ `lib/services/image_picker_channel.dart` を作成 | Dart 側 Method Channel ラッパー。`Future<Uint8List?> pickImageFromGallery()` を実装 |
| P2-T01-5 | ⬜ `icon_select_screen.dart` に「ギャラリー」フローを繋ぐ | タップ → `pickImageFromGallery()` → キャンセルなら何もしない → `crop_your_image` のクロップ UI へ渡す |
| P2-T01-6 | ⬜ クロップ後に PNG 保存 | `<appDocDir>/icons/<childId>.png` に書き込む（既存ファイルは上書き） |
| P2-T01-7 | ⬜ Child を更新して DB に反映 | `iconType: gallery`・`iconImagePath: <保存パス>` を `updateChild()` で保存 |
| P2-T01-8 | ⬜ `avatar_widget.dart` を更新 | `iconImagePath` が非 null かつファイルが存在する場合は `Image.file()` で表示。存在しない場合は頭文字アバターにフォールバック |
| P2-T01-9 | ⬜ 動作確認 | 画像選択 → クロップ → ホーム画面のカードにアイコンが表示されることを確認 |

---

### P2-T02 手描きアイコン

**概要**: `draw_your_image` でインアプリキャンバスを提供し、描いた絵を PNG として保存してアイコンに使用する。

| # | タスク | 詳細 |
|---|---|---|
| P2-T02-1 | ⬜ pubspec に `draw_your_image` を追加 | `fvm flutter pub get` |
| P2-T02-2 | ⬜ `lib/screens/drawing_canvas_screen.dart` を作成 | 以下の UI を実装（詳細は下記） |
| P2-T02-3 | ⬜ キャンバス本体 | `draw_your_image` の描画ウィジェットを正方形（画面幅いっぱい）で配置 |
| P2-T02-4 | ⬜ ペン色セレクタ | 黒・赤・青・黄の 4 色をトグルボタンで切り替え |
| P2-T02-5 | ⬜ ペン太さセレクタ | 細（2px）・中（5px）・太（10px）の 3 段階をスライダーまたはトグルで切り替え |
| P2-T02-6 | ⬜ 消しゴムモード | 消しゴムボタンで ON/OFF 切り替え。ON 時はペンカラーを背景色に変えて描画 |
| P2-T02-7 | ⬜ Undo ボタン | `draw_your_image` の undo API を呼び出す |
| P2-T02-8 | ⬜ 完了ボタン | キャンバス → `toImage()` → PNG エンコード → `<appDocDir>/icons/<childId>.png` に保存 |
| P2-T02-9 | ⬜ `icon_select_screen.dart` に「手書き」フローを繋ぐ | タップ → `DrawingCanvasScreen` へ遷移。戻り値（保存パス）を受け取って Child を更新 |
| P2-T02-10 | ⬜ Child を更新して DB に反映 | `iconType: drawing`・`iconImagePath: <保存パス>` を `updateChild()` で保存 |
| P2-T02-11 | ⬜ 動作確認 | 描画 → 完了 → ホーム画面のカードに手書きアイコンが表示されることを確認 |

> **備考**: `avatar_widget.dart` の画像表示分岐は P2-T01-8 で実装済みのため流用。

---

### P2-T03 履歴フィルタ

**概要**: `child_detail_screen.dart` の取引履歴に種別・期間でのフィルタ UI を追加する。フィルタはメモリ内でリストに適用する（SQL クエリ変更なし）。

| # | タスク | 詳細 |
|---|---|---|
| P2-T03-1 | ⬜ `TransactionFilter` クラスを定義 | `lib/models/transaction_filter.dart`。フィールド: `type: TransactionType?`（null = 全種別）、`dateFrom: DateTime?`、`dateTo: DateTime?` |
| P2-T03-2 | ⬜ フィルタ適用ロジックを実装 | `TransactionFilter.apply(List<Transaction>)` メソッド。type / dateFrom / dateTo で絞り込んだリストを返す |
| P2-T03-3 | ⬜ `child_detail_screen.dart` にフィルターバーを追加 | SliverAppBar の下、またはリスト上部に固定表示 |
| P2-T03-4 | ⬜ 種別フィルタ UI | `FilterChip` を横並びで表示（全て・入金・出金・利息）。選択状態をトグル管理 |
| P2-T03-5 | ⬜ 期間フィルタ UI | 「期間を指定」ボタン → `showDateRangePicker()` で開始〜終了日を選択 |
| P2-T03-6 | ⬜ フィルタ適用中の表示 | フィルタが有効なとき「クリア」ボタンを表示。適用件数をリスト上部に表示（例: "3件 / 全12件"） |
| P2-T03-7 | ⬜ 動作確認 | 種別フィルタ・期間フィルタ単独および組み合わせ、クリア動作を確認 |

---

### P2-T04 残高グラフ

**概要**: 取引履歴をもとに残高推移を折れ線グラフで表示する。チャートライブラリは `fl_chart` を使用。

| # | タスク | 詳細 |
|---|---|---|
| P2-T04-1 | ⬜ pubspec に `fl_chart` を追加 | `fvm flutter pub get` |
| P2-T04-2 | ⬜ `lib/widgets/balance_chart_widget.dart` を作成 | `fl_chart` の `LineChart` を使用。引数: `List<Transaction> transactions`、`DateTime createdAt`、`double initialBalance` |
| P2-T04-3 | ⬜ チャートデータ変換ロジック | transactions を新しい順 → 古い順に並び替え。先頭に「口座作成時・残高 0」の点を追加。各取引の `(date, balanceAfter)` を `FlSpot` に変換 |
| P2-T04-4 | ⬜ 軸の設定 | X軸: Unix epoch（秒）で表現し、ラベルは `M月` 形式で月単位に表示。Y軸: ¥ 表示、最小値はマイナス残高を考慮して動的に設定 |
| P2-T04-5 | ⬜ スタイリング | 折れ線の色はテーマカラーに合わせる。グラフエリア下を薄い塗りつぶしで表示。タッチで tooltip（日付・残高）を表示 |
| P2-T04-6 | ⬜ `child_detail_screen.dart` に組み込む | ヘッダー（残高・利率）の直下、取引履歴リストの上に高さ 200px 固定で配置 |
| P2-T04-7 | ⬜ エッジケース対応 | 取引が 0 件のときはグラフを非表示（または「まだ取引がありません」プレースホルダーを表示） |
| P2-T04-8 | ⬜ 動作確認 | 取引 0 件・1 件・多件、マイナス残高ありのケースで表示を確認 |

---

### Phase 2 残項目（詳細化は後回し）

| 機能 | 概要 |
|---|---|
| 利息付与通知 | 自動付与時のプッシュ通知（`flutter_local_notifications` 予定） |
| テーマカラー変更 | 子どもごとのカードカラーカスタマイズ |
| データエクスポート | CSV 形式で取引履歴を書き出し（`share_plus` 予定） |
