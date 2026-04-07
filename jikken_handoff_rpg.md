# RPG開発：屋内マップ化＆姫救出クエスト 引継ぎ資料

## 1. 現在の状態（Progress Status）
コードの整合性が一時的に崩れたため、`index.html` の修復を行っている最中です。

- [x] **新アセットの統合**: `new_chars_raw.jpg` を分割し、透過PNG化済み。
    - `npc_chancellor.png` (大臣), `npc_inn.png` (宿屋), `npc_ai.png` (AI助手), `npc_princess.png` (姫)
- [x] **タイル描画ロジック**: `drawTile` 関数にタイルID `35-39`（床、壁、机、ベッド、本棚）を追加済み。
- [/] **マップデータの修復**: `maps` オブジェクトの構造を修正中。
    - `castle`: 復元済み。大臣に新アセットを適用。
    - `village` & `port`: 30x20 拡張版（未流し込み）。
    - `demon_castle`: 25x20 拡張版（未流し込み）。
- [x] **シナリオ設計**: 姫のメタなセリフ（Wi-Fi、動画ダウンロード等）を設計済み。

## 2. 主要ファイルとパス
- **メインコード**: `jikken_rpg/index.html`
- **新キャラクターアセット**:
    - `jikken_rpg/npc_chancellor.png`
    - `jikken_rpg/npc_inn.png`
    - `jikken_rpg/npc_ai.png`
    - `jikken_rpg/npc_princess.png`

## 3. 次のステップ（To Do）
1. **`index.html` のマップ定義完成**:
   - `NEXT_MAP_HERE` プレースホルダーがある箇所から、残りのマップ（port, demon_castle等）を流し込む。
   - `field` マップの `exits` 座標を、拡張後の各マップ入り口に調整する。
2. **当たり判定確認**:
   - 新しい壁（タイル 36）や障害物が `canWalk` でブロックされるか確認。
3. **イベントテスト**:
   - 姫の救出フラグ `flags.princess_rescued` が正しく動作するかチェック。

## 4. 特記事項
現在 `index.html` の 200行目以降が不完全なため、ゲームが正常に動作しない可能性があります。修復のためのデータは設計済みなので、次のセッションで続きを行いましょう。
