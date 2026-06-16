$beginMarker = "# BEGIN ClipSuggestionsByLLM"
$endMarker = "# END ClipSuggestionsByLLM"

if(-not(Test-Path -LiteralPath $PROFILE)){
  Write-Host "PowerShell profile が見つかりませんでした。"
  return
}

$content = Get-Content -LiteralPath $PROFILE -Raw

$escapedBeginMarker = [regex]::Escape($beginMarker)
$escapedEndMarker = [regex]::Escape($endMarker)
$pattern = "(?s)\r?\n?$escapedBeginMarker.*?$escapedEndMarker\r?\n?"

if($content -notmatch $escapedBeginMarker){
  Write-Host "ClipSuggestionsByLLM の設定ブロックは見つかりませんでした。"
  return
}

$newContent = [regex]::Replace($content, $pattern, "")

Set-Content -LiteralPath $PROFILE -Value $newContent -Encoding UTF8

Write-Host "PowerShell profile から ClipSuggestionsByLLM の設定を削除しました。"
Write-Host "PowerShell を開き直すと反映されます。"