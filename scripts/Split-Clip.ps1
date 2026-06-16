### LLMの切り抜き箇所を元に切り出しを行うプログラム
function Split-Clip {
  param(
    [Parameter(Mandatory=$true)][string]$InputFile,
    [Parameter(Mandatory=$true)][string]$OutDir,
    [Parameter(Mandatory=$true)][string]$Start,
    [Parameter(Mandatory=$true)][string]$Duration,
    [Parameter(Mandatory=$true)][string]$ClipName
  )

  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

  ffmpeg -hide_banner -loglevel error -nostats `
    -ss $Start `
    -i $InputFile `
    -t $Duration `
    -vf format=yuv420p `
    -c:v h264_nvenc -preset p3 -cq 22 -b:v 0 `
    -c:a aac -b:a 160k `
    (Join-Path $OutDir $ClipName)
}