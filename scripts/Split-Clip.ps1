### LLMの切り抜き箇所を元に切り出しを行うプログラム
function Split-Clip {
  param(
    [Parameter(Mandatory=$true)][string]$InputFile,
    [Parameter(Mandatory=$true)][string]$OutDir,
    [Parameter(Mandatory=$true)][string]$Start,
    [Parameter(Mandatory=$true)][string]$Duration,
    [Parameter(Mandatory=$true)][string]$ClipName,
    [switch]$CUDA,
    [switch]$CPU
  )

  if($CUDA -and $CPU) {
    throw "CUDA と CPU は同時に指定できません"
  }

  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

  $outputFile = Join-Path $OutDir $ClipName
  $videoEncodeArgs = if($CPU) {
    @("-c:v", "libx264", "-preset", "medium", "-crf", "22")
  }
  else {
    @("-c:v", "h264_nvenc", "-preset", "p3", "-cq", "22", "-b:v", "0")
  }

  $ffmpegArgs = @(
    "-hide_banner", "-loglevel", "error", "-nostats",
    "-ss", $Start,
    "-i", $InputFile,
    "-t", $Duration,
    "-vf", "format=yuv420p"
  ) + $videoEncodeArgs + @(
    "-c:a", "aac", "-b:a", "160k",
    $outputFile
  )

  & ffmpeg @ffmpegArgs

  if($LASTEXITCODE -ne 0) {
    throw "ffmpegの実行に失敗しました (NVIDIAのGPUを使用できない場合は -CPUをつけて再実行してください)"
  }
}
