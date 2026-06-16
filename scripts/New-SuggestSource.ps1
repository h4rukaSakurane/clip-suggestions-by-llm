### LLM切り抜き候補自動提示
### 主な機能
### 1. 配信録画データをこの制作フローで管理する名前にする(管理の開始)
### 2. 配信録画から音声のみを取り出す
### 3. SRTファイルを作る
function New-SuggestSource {
<#
.SYNOPSIS
OBS録画からLLM切り抜き候補作成用のSRTファイルを生成します

.DESCRIPTION
録画ファイルを管理用フォルダへ移動し、指定した音声トラックを抽出して
WhisperでSRT字幕ファイルを作成します

.PARAMETER Input
処理対象の録画ファイルを指定します
省略した場合は SourceVideoDir 内の最新 mp4 を使用します
TargetFile の短縮名です

.PARAMETER BaseName
管理用ファイル名のベース名を指定します
TargetFile を指定する場合は BaseName も同時に指定します

.PARAMETER Track
文字起こし対象にする音声トラック番号を指定します
VoiceTrack の短縮名です

.PARAMETER Redo
指定した TargetFile を移動せず、管理済み動画として再利用します
同じ録画を別トラックで再処理したい場合に使用します
UseManagedVideo の短縮名です

.PARAMETER Force
既存の wav / srt がある場合でも上書きして再生成します

.EXAMPLE
New-Clip
録画フォルダ内の最新 mp4 を処理します

.EXAMPLE
New-Clip -Track 2
2番目の音声トラックを使用して処理します

.EXAMPLE
New-Clip -UseManagedVideo -TargetFile "D:\ClipSuggestionsByLLM\managed-videos\2026-06-16_午前配信.mp4" -Track 2
管理済み動画を移動せずに、2番目の音声トラックで再処理します

.EXAMPLE
New-Clip -UseManagedVideo -TargetFile "D:\ClipSuggestionsByLLM\managed-videos\2026-06-16_午前配信.mp4" -Track 2 -Force
既存の音声ファイルやSRTを上書きして再生成します
#>
  param(
    [string]$BaseName = $null,
    [Parameter(ValueFromPipeline = $true)]
    [Alias("InputFile", "Input")]
    [System.IO.FileInfo]$TargetFile = $null,
    [Alias("Redo")]
    [switch]$UseManagedVideo,
    [switch]$Force,
    [string]$SourceVideoDir = (Get-DefaultValue -PropertyName "SourceVideoDir"),
    [string]$WorkDir = (Get-DefaultValue -PropertyName "WorkDir"),
    [string]$ManagedVideoDir = (Get-DefaultValue -PropertyName "ManagedVideoDir"),
    [string]$SrtDir = (Get-DefaultValue -PropertyName "SrtDir"),
    [string]$VoiceTrackDir = (Get-DefaultValue -PropertyName "VoiceTrackDir"),
    [Alias("Track")]
    [int]$VoiceTrack = [int](Get-DefaultValue -PropertyName "VoiceTrack"),
    [string]$WhisperExe = (Join-Path $WorkDir ".venv/Scripts/whisper.exe"),
    [string]$WhisperModel = "turbo",
    [string]$WhisperLanguage = "ja"
  )
  
  $isTargetFileSpecified = $PSBoundParameters.ContainsKey("TargetFile")
  $isBaseNameSpecified = $PSBoundParameters.ContainsKey("BaseName")

  if($UseManagedVideo){
    if(-not $isTargetFileSpecified){
      throw "UseManagedVideo を指定する場合は、TargetFile も指定してください。"
    }
  }
  elseif($isTargetFileSpecified -ne $isBaseNameSpecified){
    throw "TargetFile と BaseName は同時に指定してください。どちらも指定しない場合は、録画フォルダ内の最新mp4から自動判定します。"
  }

  # ターゲットファイルが存在しなかったら処理できない
  if($null -ne $TargetFile){
    if (-not (Test-Path -LiteralPath $TargetFile.FullName)) {
      throw "ファイルが見つかりません: $($TargetFile.FullName)"
    }
  }

  # なかった場合は録画フォルダを降順に取得した、先頭ファイルにする
  if($null -eq $TargetFile) {
    $TargetFile = (
      Get-ChildItem -Path $SourceVideoDir -File |
      Where-Object { $_.Extension -eq ".mp4" } |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1
    )
    if($null -eq $TargetFile) {
       throw "対象となる録画ファイルが見つかりませんでした: $SourceVideoDir"
    }
  }

  # ファイル名を渡され、かぶっていたら中止
  if ($null -ne $BaseName) {
    $dest = Join-Path $ManagedVideoDir "$BaseName$($TargetFile.Extension)"
    if (Test-Path -LiteralPath $dest) {
      throw "ファイルが重複しています: $dest"
    }
  }

  New-Item -ItemType Directory -Force -Path $ManagedVideoDir | Out-Null
  New-Item -ItemType Directory -Force -Path $SrtDir | Out-Null
  New-Item -ItemType Directory -Force -Path $VoiceTrackDir | Out-Null

  if($UseManagedVideo){
    if($null -eq $BaseName) {
      $BaseName = $TargetFile.BaseName
    }

    $managedVideoFile = Get-Item -LiteralPath $TargetFile.FullName
    $voiceTrackFile = New-VoiceTrack -TargetFile $managedVideoFile -VoiceTrackDir $VoiceTrackDir -VoiceTrack $VoiceTrack -Force:$Force
    $srtFile = New-VoiceSrt -VoiceTrackFile $voiceTrackFile -SrtDir $SrtDir -WhisperExe $WhisperExe -WhisperModel $WhisperModel -WhisperLanguage $WhisperLanguage -Force:$Force

    return [pscustomobject]@{
      BaseName       = $BaseName
      InputFile      = $managedVideoFile.FullName
      VoiceTrackFile = $voiceTrackFile.FullName
      SrtFile        = $srtFile.FullName
    }
  }

  
  if($null -eq $BaseName) {
    $BaseName = (Resolve-ClipSuggestBaseName $TargetFile $ManagedVideoDir)
  }

  # LLM管理開始のため、ファイルを引っ越す
  $dest = (Join-Path $ManagedVideoDir "$($BaseName)$($TargetFile.Extension)")
  Move-Item -LiteralPath $TargetFile.FullName -Destination $dest
  
  $managedVideoFile = Get-Item -LiteralPath $dest
  $voiceTrackFile = New-VoiceTrack -TargetFile $managedVideoFile -VoiceTrackDir $VoiceTrackDir -VoiceTrack $VoiceTrack -Force:$Force
  $srtFile = New-VoiceSrt -VoiceTrackFile $voiceTrackFile -SrtDir $SrtDir -WhisperExe $WhisperExe -WhisperModel $WhisperModel -WhisperLanguage $WhisperLanguage -Force:$Force

  return [pscustomobject]@{
    BaseName       = $BaseName
    InputFile      = $managedVideoFile.FullName
    VoiceTrackFile = $voiceTrackFile.FullName
    SrtFile        = $srtFile.FullName
  }
}

# このコマンドがこのツールセットで唯一手で叩かれるものなので、短い別名を張る
Set-Alias -Name New-Clip -Value New-SuggestSource