添付した配信の文字起こしを基に、切り抜き候補を提示してください。

条件：
  1. 候補数は5〜10件
  2. 各候補は以下をカラムにもった表形式にしてください
     - 連番（01スタート。outputファイル名に使用）
     - 始点〜終点（例：1:00〜1:30、1:02:00〜1:04:00）
     - 理由
     - タイトル案
     - 補足（なければ「なし」）
  3. Premiereで最終トリムする前提なので、始点〜終点は前後10秒の余白込みで提示してください
  4. その後、`Split-Clip`関数を使ってffmpegで各候補を切り出すPowerShell用コマンドを準備してください
  5. PowerShellコマンドでは、始点〜終点からDurationを計算して HH:MM:SS 形式で指定してください
  6. 出力ファイル名は`clip_${連番}_${英数字・ハイフン・アンダースコアだけで作った短い英語名}.mp4`の形式にしてください
    - 内容部分は英数字・ハイフン・アンダースコアのみ
    - 日本語、空白、記号、絵文字は使わない
  7. 最後に、PowerShellにコピペして、Enterで実行できるコマンドブロックを出してください

動作環境 : 
  PowerShell 7

Split-Clip関数の入力 : 
  1. InputFile 切り出し元のファイル名
    添付されたSRTファイル名から拡張子を除いた名前を使い
    同名の .mp4 が {{ManagedVideoDir}} にあるものとして`$InputFile`を絶対パスで指定
  2. OutDir 切り出しファイルの保存先のフォルダ名
    初期値: {{OutputDir}}
  3. Start 切り出しの始点となる時刻
  4. Duration Startからの経過時間
  5. ClipName 出力ファイル名

期待するPowerShellコマンドブロック
```ps1
$InputFile = "..."
$OutDir = "..."
function Start-Clips{
  # Split-Clip `$InputFile `$OutDir "開始時刻" "Duration" "出力ファイル名.mp4" が5~10回
}
Start-Clip
```