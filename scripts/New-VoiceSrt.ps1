# SRT形式のファイルを作成
function New-VoiceSrt{
  param(
    [Parameter(Mandatory = $true)][System.IO.FileInfo]$VoiceTrackFile,
    [Parameter(Mandatory = $true)][string]$SrtDir,
    [Parameter(Mandatory = $true)][string]$WhisperExe,
    [Parameter(Mandatory = $true)][string]$WhisperModel,
    [Parameter(Mandatory = $true)][string]$WhisperLanguage,
    [switch]$Force
  )

  $localErrMsg = @{
    whisperNotFound = "whisper.exe が見つかりません: $WhisperExe"
    trackSrtAlreadyExists = "すでに同一トラックのSRTファイルが書き出されています"
    whisperFailed = "WhisperによるSRTファイル生成に失敗しました"
  } 

  if (-not (Test-Path -LiteralPath $WhisperExe)) {
    throw $localErrMsg.whisperNotFound
  }

  $srtPath = Join-Path $SrtDir "$($VoiceTrackFile.BaseName).srt"
  if((Test-Path -LiteralPath $srtPath) -and (-not $Force)) {
    throw $localErrMsg.trackSrtAlreadyExists
  }

  New-Item -ItemType Directory -Force -Path $SrtDir | Out-Null

  & $WhisperExe $VoiceTrackFile.FullName --language $WhisperLanguage --model $WhisperModel --output_format srt --output_dir $SrtDir 
  
  if ($LASTEXITCODE -ne 0) {
    throw $localErrMsg.whisperFailed
  }
  
  return Get-Item -LiteralPath $srtPath
}