# clip-suggestions-by-llm

Copyright (c) 2026 Sakurane Haruka
Released under the MIT License.

OBSで保存した配信録画から、LLMに切り抜き候補を提示してもらうための下準備を行うPowerShellツールです。

配信録画から配信者の音声トラックだけを取り出し、WhisperでSRT字幕ファイルを生成します。  
生成したSRTファイルとプロンプトをChatGPTなどのLLMに渡すことで、切り抜き候補の時間帯・理由・タイトル案・切り出しコマンドを作りやすくします。

このツールは、切り抜き動画を自動で完成させるものではありません。  
候補探しと素材準備を軽くし、最終的なカット判断・テロップ入れ・演出は人間が行う前提です。

```text
OBS録画
  ↓
音声トラック抽出
  ↓
WhisperでSRT生成
  ↓
LLMに切り抜き候補を提示してもらう
  ↓
Premiere Proなどで最終調整
```

## このツールでできること

- OBSで録画した配信ファイルを、切り抜き制作フロー用の名前に変更して管理する
- 録画ファイルから指定した音声トラックだけを取り出す
- Whisperで文字起こしし、SRTファイルを生成する
- LLMに渡すためのプロンプトファイルを作成する
- PowerShellから切り抜き候補作成の準備を実行できるようにする

## 想定している使い方

このツールは、主に以下のような配信者向けです。

- Windows PCでOBS録画をしている
- 配信録画から切り抜き動画を作りたい
- Whisperで文字起こしを作りたい
- ChatGPTなどのLLMに切り抜き候補を考えてもらいたい
- 手作業を減らし、切り抜き制作をライン化したい

## 対応環境

このツールは Windows 環境を前提にしています。

- Windows
- PowerShell 7 以降
- Python 3.11
- ffmpeg
- openai-whisper
- NVIDIA GPU がある場合は CUDA 対応 PyTorch を自動で導入

macOS / Linux は現在サポート対象外です。

## 事前準備

### PowerShell 7

Windows PowerShell 5.1 では動作しません。  
PowerShell 7 をインストールしてから実行してください。

```powershell
winget install --id Microsoft.PowerShell --source winget
```

PowerShell 7 を起動できているか分からない場合は、開いた画面で以下を入力してください。

```powershell
$PSVersionTable.PSVersion
```

`Major` が `7` 以上であればOKです。  
`5` と表示された場合は Windows PowerShell なので、PowerShell 7 を開き直してください。

### Python 3.11

Python 3.11 が必要です。  
セットアップ時に `py -3.11` が使用できるか確認します。
https://www.python.org/downloads/release/python-3110/

### ffmpeg

ffmpeg が必要です。  
セットアップ時に `ffmpeg` がPATHから実行できるか確認します。
https://ffmpeg.org/download.html

## セットアップ

PowerShell 7 を起動し、`Setup.ps1` を実行してください。

```powershell
.\Setup.ps1
```

スタートメニューから「PowerShell 7」を起動し、開いた画面に `Setup.ps1` をドラッグ&ドロップして Enter を押すことでも実行できます。

セットアップでは以下を行います。

- 必要なフォルダを作成
- Whisper用のPython仮想環境を作成
- `openai-whisper` をインストール
- NVIDIA GPU がある場合は CUDA 版 PyTorch をインストール
- ChatGPT用プロンプトファイルを作成
- PowerShellの `$PROFILE` に設定とスクリプト読み込み処理を追加

セットアップ後、PowerShell 7 を開き直すとコマンドが使えるようになります。

## インストール方法

`Setup.ps1` 実行時に、以下のどちらかを選べます。

```text
おすすめ設定: Y / 上級者設定: n [Y]
```

### おすすめ設定

Enter または `Y` を入力すると、桜音おすすめの決め打ち構成でセットアップします。

### 上級者設定

`n` を入力すると、各フォルダを自分で指定できます。  
何も入力せず Enter を押した場合は、表示されているデフォルト値が使われます。

中止したい場合は `Ctrl + C` を押してください。

## 基本的な使い方

PowerShell 7 を開き直したあと、以下のコマンドを実行します。

```powershell
New-SuggestSource
```

または、以下の短縮版のコマンドも準備しています
これは上記と全く同じ振る舞いをします

```powershell
New-Clip
```

このコマンドは、録画フォルダ内の最新の `.mp4` ファイルを対象にします。

処理が完了すると、以下の情報を含む結果が表示されます。

- 管理用のベース名
- 管理対象になった録画ファイル
- 抽出した音声トラックファイル
- 生成されたSRTファイル

生成されたSRTファイルを、`ClipSuggestionsByLLM.md` のプロンプトと一緒にChatGPTなどのLLMへ渡してください。

## OBSの録画ファイル名について

このツールは、OBSの録画ファイル名が以下の形式で保存されている前提で、録画フォルダ内の最新ファイルを自動選択します。

```text
%CCYY-%MM-%DD %hh-%mm-%ss
```

例：

```text
2026-06-16 05-12-19.mp4
```

OBSの録画設定で、録画ファイル名の書式を上記に変更してください。

このツールでは、録画ファイル名から配信日と開始時刻を読み取り、以下のような管理用ファイル名に変換します。

```text
2026-06-16_午前配信.mp4
2026-06-16_午後配信.mp4
```

## OBSの録画ファイル名を変更したくない場合

OBSの録画ファイル名が推奨形式ではない場合は、`TargetFile` と `BaseName` を手動で指定してください。

```powershell
New-SuggestSource `
  -TargetFile "D:\recordings\my-stream.mp4" `
  -BaseName "2026-06-16_午前配信"
```

`TargetFile` と `BaseName` は同時に指定する必要があります。

| 指定内容                            | 動作                              |
| ----------------------------------- | --------------------------------- |
| `TargetFile` なし / `BaseName` なし | 録画フォルダ内の最新mp4を自動処理 |
| `TargetFile` あり / `BaseName` あり | 指定ファイルを指定名で処理        |
| `TargetFile` あり / `BaseName` なし | エラー                            |
| `TargetFile` なし / `BaseName` あり | エラー                            |

## 音声トラックについて

デフォルトでは、録画ファイルの2番目の音声トラックを配信者の声として扱います。

```powershell
New-SuggestSource -VoiceTrack 2
```

OBSでマルチトラック録画をしている場合は、配信者の声だけが入っているトラック番号の指定をおすすめします。

## 注意事項

- 初回セットアップでは、WhisperやPyTorchのインストールに時間がかかります
- NVIDIA GPU がある場合は CUDA 版 PyTorch を導入します
- NVIDIA GPU が見つからない場合は、openai-whisper標準のPyTorch構成を使用します
- 生成された切り抜き候補は、最終的にPremiere Proなどの編集ソフトで確認・調整する前提です
- このツールは切り抜き動画を自動完成させるものではなく、候補出しと素材準備を補助するためのものです

## 既定の音声トラックを変更したい場合

セットアップ時に上級者設定を選ぶと、既定の音声トラック番号を指定できます。

後から変更したい場合は、PowerShellのprofileに追加された以下の設定を編集してください。

```powershell

$global:ClipSuggestionsByLLMProfile = [pscustomobject]@{
  BaseDir = "..."
  WorkDir = "..."
  RecDir = "..."
  VoiceTrackDir = "..."
  SrtDir = "..."
  OutputDir = "..."
  VoiceTrack = 1
}

```
## コンセプト

切り抜き制作では、すべてを人力で確認すると時間がかかります。
一方で、無言のゲームプレイ部分まで切り抜き候補にする必要はあまりありません。

そこでこのツールでは、配信者の発話を文字起こしし、LLMに「どこが切り抜きとして成立しそうか」を考えてもらいます。

最終判断は人間が行い、LLMは候補出しと作業量削減に使う。
そのための、小さな制作ラインです。

## おまけ
OBSの録画を使う場合、オーディオトラックを2つに増やし
2つ目のトラックを配信者のマイクのみとすると自分のトークのみをもとに文字起こし
そして切り抜き候補の提示に繋げることができます

コラボ配信などでは有用かもしれません

オーディオトラックの設定が済んだら以下の手順でLLMに渡すデフォルトのトラックを変更できます
まずは次のコマンドを実行してください
```
notepad $PROFILE
```

その後、メモ帳が立ち上がるので
`VoiceTrack = 1`を`VoiceTrack = 2`に変更してください

## GUI版について

現在はPowerShell版として公開しています
まずは処理手順を明確にし、CUIで再現可能な制作ラインとして整備しています

実際に利用する方が増え、GUI化した方がよい操作やつまずきどころが見えてきた場合は
ドラッグ&ドロップで使えるGUI版の開発も検討します

## 応援

このツールは、桜音はるかの配信活動・切り抜き制作の中で生まれた補助ツールです
たま〜にでも、配信に遊びに来てくれたら嬉しいです