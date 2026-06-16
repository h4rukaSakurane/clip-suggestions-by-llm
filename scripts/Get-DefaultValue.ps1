### 指定されたプロファイルの特定の値を取り出す
function Get-DefaultValue{
  param(
    [Parameter(Mandatory = $true)][string]$PropertyName
  )

  if($null -eq $global:ClipSuggestionsByLLMProfile){
    throw "インストールスクリプトの実行に失敗している可能性があります"
  }
  $property = $global:ClipSuggestionsByLLMProfile.PSObject.Properties[$PropertyName]
  if($null -eq $property -or [string]::IsNullOrWhiteSpace($property.Value)){
    throw "設定値が見つかりません: $PropertyName"
  }

  return $property.Value
}