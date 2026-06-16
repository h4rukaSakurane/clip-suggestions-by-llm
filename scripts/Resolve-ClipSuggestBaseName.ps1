# LLM切り抜き管理フローで使用するファイル名を決めるスクリプト
function Resolve-ClipSuggestBaseName {
  param(
    [Parameter(Mandatory = $true)][System.IO.FileInfo]$TargetFile,
    [Parameter(Mandatory = $true)][string]$SourceVideoDir
  )

  $streamDate = [datetime]::ParseExact(
    $TargetFile.BaseName,
    "yyyy-MM-dd HH-mm-ss",
    [System.Globalization.CultureInfo]::InvariantCulture
  )

  $streamTimeFrame = $streamDate.Hour -lt 12 ? "午前配信" : "午後配信"
  $baseName = "$($streamDate.ToString("yyyy-MM-dd"))_$streamTimeFrame"
  
  #重複したら(2)をつけるなどする
  $index = 2
  $fileNameIndex=""
  while(Test-Path -LiteralPath (Join-Path $SourceVideoDir "$($baseName)$($fileNameIndex)$($TargetFile.Extension)")){
    $fileNameIndex = "($($index))"
    $index++
  }

  return "$($baseName)$($fileNameIndex)"
}

