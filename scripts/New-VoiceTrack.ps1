# ffmpegでファイルの読み取りを行う
function New-VoiceTrack{
  param(
    [Parameter(Mandatory = $true)][System.IO.FileInfo]$TargetFile,
    [Parameter(Mandatory = $true)][string]$VoiceTrackDir,
    [Parameter(Mandatory = $true)][int]$VoiceTrack,
    [switch]$Force
  )

  $localErrMsgs = @{
    invalidTrackNum = "VoiceTrack は 1 以上を指定してください"
    trackWavAlreadyExists = "すでに同一トラックのファイルが書き出されています"
    ffmpegFailed = "ffmpegによる音声トラック抽出に失敗しました"
  }

  if($VoiceTrack -lt 1) {
    throw $localErrMsgs.invalidTrackNum
  }
  New-Item -ItemType Directory -Force -Path $VoiceTrackDir | Out-Null

  $ffmpegTrackIndex = $VoiceTrack - 1
  $mapParam = "0:a:$ffmpegTrackIndex"

  $outputFile = Join-Path $VoiceTrackDir "$($TargetFile.BaseName).track$VoiceTrack.wav"
  if((Test-Path -LiteralPath $outputFile) -and (-not $Force)) {
    throw $localErrMsgs.trackWavAlreadyExists
  }

  ffmpeg -y -i $TargetFile.FullName -map $mapParam -vn -ac 1 -ar 16000 $outputFile

  if ($LASTEXITCODE -ne 0) {
    throw $localErrMsgs.ffmpegFailed
  }

  return Get-Item -LiteralPath $outputFile
}
