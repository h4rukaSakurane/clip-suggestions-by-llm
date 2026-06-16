$ErrorMsgs =@{
  pwshVersion = @"
Windows PowerShell 5.1 では動作しません。以下のコマンドでPowerShell 7系をインストールし
PowerShell 7を起動してこのスクリプトを実行してください

winget install --id Microsoft.PowerShell --source winget

スタートメニューでのアイコンが水色だったらWindows PowerShellです
"@;
  notWindows = "このセットアップスクリプトは Windows 環境で実行してください";
  pyNotFound = @"
Python Launcher(py) が見つかりません。Python 3.11 をインストールしてください
https://www.python.org/downloads/release/python-3110/
"@;
  pyVersionMissing = @"
Pythonのバージョンが間違っているかもしれません 3.11 をインストールしてください
https://www.python.org/downloads/release/python-3110/
"@;
  ffmpegNotFound = @"
ffmpeg が見つかりません。ffmpeg をインストールし、PATH に追加してください
https://ffmpeg.org/download.html
"@;
  profileBlockAlreadyExists = @"
PowerShell profile に既存の ClipSuggestionsByLLM 設定が見つかりました。
再セットアップする場合は、先に Clean.ps1 を実行して既存設定を削除してください。
.\Clean.ps1
"@
}

if($PSVersionTable.PSEdition -ne "Core" -or $PSVersionTable.PSVersion.Major -lt 7){
throw $ErrorMsgs.pwshVersion
}

if(-not $IsWindows){
  throw $ErrorMsgs.notWindows
}

$python311 = Get-Command py -ErrorAction SilentlyContinue
if($null -eq $python311){
throw $ErrorMsgs.pyNotFound
}

py -3.11 --version 2>$null
if($LASTEXITCODE -ne 0){
throw $ErrorMsgs.pyVersionMissing
}

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if($null -eq $ffmpeg){
  throw $ErrorMsgs.ffmpegNotFound
}

if(Test-Path -LiteralPath $PROFILE){
  $beginMarker = "# BEGIN ClipSuggestionsByLLM"
  $profileContent = Get-Content -LiteralPath $PROFILE -Raw
  if($profileContent -match [regex]::Escape($beginMarker)){
    throw $ErrorMsgs.profileBlockAlreadyExists
  }
}

# デフォルトの値は初心者向け設定
# $HOME/Documentsの下に専用ディレクトリを一つ切って各ディレクトリを準備する
function Initialize-ClipSuggestionsByLLM{
  param(
    [string]$BaseDir = (Join-Path $HOME "Documents/ClipSuggestionsByLLM"), #このツールの管理フォルダ
    [string]$WorkDir = (Join-Path $BaseDir "works"), 
    [string]$SourceVideoDir = (Join-Path $HOME "Videos"), # OBS録画のデフォルト値を仮置き
    [string]$ManagedVideoDir = (Join-Path $WorkDir "00_managedVideo"), # デフォルト(WorkDir配下)を推奨
    [string]$VoiceTrackDir = (Join-Path $WorkDir "01_voiceTrack"), # デフォルト(WorkDir配下)を推奨
    [string]$SrtDir = (Join-Path $WorkDir "02_srt"), # デフォルト(WorkDir配下)を推奨
    [string]$OutputDir = (Join-Path $BaseDir "output"), # デフォルト(BaseDir配下)を推奨
    [int]$VoiceTrack = 1 # OBSの録画設定を変更したのち、2に変更することを推奨
  )

  $localErrorMsgs = @{
    directoryAlreadyExists = @"
既にセットアップ済みのディレクトリが存在します: $BaseDir
再セットアップする場合は、先に Clean.ps1 を実行し、必要に応じて既存フォルダを手動で削除してください。
"@
  }
  

  # 文字起こしを解析する際に投げるプロンプトのファイル名
  $PromptFileName = "ClipSuggestionsByLLM.md"
  $promptPath = Join-Path $BaseDir $PromptFileName

  # ディレクトリがすでにあったら使えない
  if(Test-Path -LiteralPath $BaseDir){
    throw $localErrorMsgs.directoryAlreadyExists
  }

  # このツールセットが使うディレクトリの展開とWhisperのインストール
  Initialize-Directories -BaseDir $BaseDir -WorkDir $WorkDir -SourceVideoDir $SourceVideoDir -ManagedVideoDir $ManagedVideoDir -VoiceTrackDir $VoiceTrackDir -SrtDir $SrtDir -OutputDir $OutputDir
  Install-WhisperEnvironment -WorkDir $WorkDir
  # プロンプトを作業フォルダのトップに配置  
  Set-Content -LiteralPath $promptPath -Value (New-Prompt -ManagedVideoDir $ManagedVideoDir -OutputDir $OutputDir) -Encoding UTF8

  if(-not(Test-Path -LiteralPath $PROFILE)){
    # pwsh Profileがなかったら作る
    New-Item -ItemType File -Force -Path $PROFILE | Out-Null
  }

  # pwsh Profileの中にインストール時の設定を読み込む
  $profileBlock = New-GlobalSettings -BaseDir $BaseDir -WorkDir $WorkDir -SourceVideoDir $SourceVideoDir -ManagedVideoDir $ManagedVideoDir -VoiceTrackDir $VoiceTrackDir -SrtDir $SrtDir -OutputDir $OutputDir -VoiceTrack $VoiceTrack
  Add-Content -LiteralPath $PROFILE -Value $profileBlock -Encoding UTF8

  Write-Host "セットアップが完了しました。PowerShell 7を開き直してください"
}

function Initialize-Directories{
  param(
    [Parameter(Mandatory = $true)][string]$BaseDir,
    [Parameter(Mandatory = $true)][string]$WorkDir,
    [Parameter(Mandatory = $true)][string]$SourceVideoDir,
    [Parameter(Mandatory = $true)][string]$VoiceTrackDir,
    [Parameter(Mandatory = $true)][string]$ManagedVideoDir,
    [Parameter(Mandatory = $true)][string]$SrtDir,
    [Parameter(Mandatory = $true)][string]$OutputDir
  )
  if(-not(Test-Path $SourceVideoDir)){
    throw "$($SourceVideoDir)が見つかりませんでした"
  }
  New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null
  New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
  New-Item -ItemType Directory -Force -Path $ManagedVideoDir | Out-Null
  New-Item -ItemType Directory -Force -Path $VoiceTrackDir | Out-Null
  New-Item -ItemType Directory -Force -Path $SrtDir | Out-Null
  New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

function Install-WhisperEnvironment{
  param(
    [Parameter(Mandatory = $true)][string]$WorkDir
  )

  $localInstallMsgs = @{
    completed = "Whisper環境のセットアップが完了しました"
    cudaGPUNotFound = "NVIDIA GPUが見つからなかったため、openai-whisper標準のPyTorch構成を使用します";
  }

  $localErrorMsgs = @{
    createVenvFailed = "Whisper用のPython仮想環境の作成に失敗しました";
    venvPythonExeNotFound = {
      param([string]$pyExePath)
        return "仮想環境のPythonが見つかりません: $pyExePath"
    };
    pipUpdateFailed = "pipの更新に失敗しました";
    whisperInstallFailed = "openai-whisperのインストールに失敗しました";
    cpuPyTorchUninstallFailed = "既存のPyTorch関連パッケージのアンインストールに失敗しました";
    cudaPyTorchInstallFailed = "CUDA向けのPyTorchのインストールに失敗しました";
  }

  $venvDir = Join-Path $WorkDir ".venv"
  $pythonExe = Join-Path $venvDir "Scripts\python.exe"

  # Whisper用のvenvを作成
  if(-not(Test-Path -LiteralPath $venvDir)){
    py -3.11 -m venv $venvDir
    if($LASTEXITCODE -ne 0){
      throw $localErrorMsgs.createVenvFailed
    }
  }

  # venv内のPythonの存在チェック
  if(-not(Test-Path -LiteralPath $pythonExe)){
    throw (& $localErrorMsgs.venvPythonExeNotFound $pythonExe)
  }

  # venv内のpipを更新
  & $pythonExe -m pip install --upgrade pip
  if($LASTEXITCODE -ne 0){
    throw $localErrorMsgs.pipUpdateFailed
  }

  # Whisperのインストール
  & $pythonExe -m pip install -U openai-whisper
  if($LASTEXITCODE -ne 0){
    throw $localErrorMsgs.whisperInstallFailed
  }

  $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
  # PyTorchをCUDA使用に変更
  if($null -ne $nvidiaSmi){
    & $pythonExe -m pip uninstall -y torch torchvision torchaudio
    if($LASTEXITCODE -ne 0){
      throw $localErrorMsgs.cpuPyTorchUninstallFailed
    }

    & $pythonExe -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
    if($LASTEXITCODE -ne 0){
      throw $localErrorMsgs.cudaPyTorchInstallFailed
    }
  }

  else {
    Write-Host $localInstallMsgs.cudaGPUNotFound
  }
  Write-Host $localInstallMsgs.completed
}

# ClipSuggestionsByLLM.mdを作る
function New-Prompt{
  param(
    [Parameter(Mandatory = $true)][string]$ManagedVideoDir,
    [Parameter(Mandatory = $true)][string]$OutputDir
  )
  $templatePath = Join-Path $PSScriptRoot "prompts\ClipSuggestionsByLLM.md"
  if(-not(Test-Path -LiteralPath $templatePath)){
    throw "プロンプトテンプレートが見つかりません: $templatePath"
  }
  $prompt = Get-Content -LiteralPath $templatePath -Raw
  $prompt = $prompt.Replace("{{ManagedVideoDir}}", $ManagedVideoDir)
  $prompt = $prompt.Replace("{{OutputDir}}", $OutputDir)

  return $prompt
}

# このツールセットが使用する設定を書き出す
function New-GlobalSettings{
  param(
    [Parameter(Mandatory = $true)][string]$BaseDir,
    [Parameter(Mandatory = $true)][string]$WorkDir,
    [Parameter(Mandatory = $true)][string]$SourceVideoDir,
    [Parameter(Mandatory = $true)][string]$VoiceTrackDir,
    [Parameter(Mandatory = $true)][string]$ManagedVideoDir,
    [Parameter(Mandatory = $true)][string]$SrtDir,
    [Parameter(Mandatory = $true)][string]$OutputDir,
    [Parameter(Mandatory = $true)][int]$VoiceTrack
  )
  return @"
# BEGIN ClipSuggestionsByLLM
`$global:ClipSuggestionsByLLMRoot = "$PSScriptRoot"
Get-ChildItem -LiteralPath (Join-Path `$global:ClipSuggestionsByLLMRoot "scripts") -Filter "*.ps1" |
  Sort-Object Name |
  ForEach-Object { . `$_.FullName }

`$global:ClipSuggestionsByLLMProfile = [pscustomobject]@{
  BaseDir = "$BaseDir"
  WorkDir = "$WorkDir"
  SourceVideoDir = "$SourceVideoDir"
  ManagedVideoDir = "$ManagedVideoDir"
  VoiceTrackDir = "$VoiceTrackDir"
  SrtDir = "$SrtDir"
  OutputDir = "$OutputDir"
  VoiceTrack = $VoiceTrack
}
  
# END ClipSuggestionsByLLM
"@
}

# Read-Hostが空文字だったらデフォルト値を返す
function Read-HostOrDefault{
  param(
    [Parameter(Mandatory = $true)][string]$Message,
    [Parameter(Mandatory = $true)][string]$DefaultValue
  )

  $inputValue = Read-Host "$Message [$DefaultValue]"
  if([string]::IsNullOrWhiteSpace($inputValue)){
    return $DefaultValue
  }

  return $inputValue
}

$quickInstall = Read-Host "インストール方法を選んでください。おすすめ設定($($HOME)/Documents/ClipSuggestionsByLLM 下に一式を展開): Y / 上級者設定(ファイルの保存先などを変更可能): n [Y] (Ctrl + C でキャンセル)"
if([string]::IsNullOrWhiteSpace($quickInstall) -or $quickInstall -eq "Y" -or $quickInstall -eq "y"){
  Initialize-ClipSuggestionsByLLM
}
else {
  [string]$DefaultBaseDir = Join-Path $HOME "Documents/ClipSuggestionsByLLM"
  [string]$DefaultWorkDir = Join-Path $DefaultBaseDir "works"
  [string]$DefaultSourceVideoDir = Join-Path $HOME "Videos"
  [string]$DefaultManagedVideoDir = Join-Path $DefaultWorkDir "00_managedVideo"
  [string]$DefaultVoiceTrackDir = Join-Path $DefaultWorkDir "01_voiceTrack"
  [string]$DefaultSrtDir = Join-Path $DefaultWorkDir "02_srt"
  [string]$DefaultOutputDir = Join-Path $DefaultBaseDir "output"
  [string]$DefaultVoiceTrack = 1

  $BaseDir = Read-HostOrDefault -Message "このアプリケーションのインストールフォルダ" -DefaultValue $DefaultBaseDir
  $WorkDir = Read-HostOrDefault -Message "作業データの格納場所" -DefaultValue $DefaultWorkDir
  $SourceVideoDir = Read-HostOrDefault -Message "OBSの録画ファイルの保存場所" -DefaultValue $DefaultSourceVideoDir
  $ManagedVideoDir = Read-HostOrDefault -Message "このツールで管理する録画ファイルの保存場所" -DefaultValue $DefaultManagedVideoDir
  $VoiceTrackDir = Read-HostOrDefault -Message "文字起こし用音声データのファイルの保存場所" -DefaultValue $DefaultVoiceTrackDir
  $SrtDir = Read-HostOrDefault -Message "文字起こしファイルの保存場所" -DefaultValue $DefaultSrtDir
  $OutputDir = Read-HostOrDefault -Message "切り出した動画ファイルの保存場所" -DefaultValue $DefaultOutputDir
  $VoiceTrack = [int](Read-HostOrDefault -Message "既定の音声トラック番号" -DefaultValue $DefaultVoiceTrack)

  Initialize-ClipSuggestionsByLLM -BaseDir $BaseDir -WorkDir $WorkDir -SourceVideoDir $SourceVideoDir -ManagedVideoDir $ManagedVideoDir -VoiceTrackDir $VoiceTrackDir -SrtDir $SrtDir -OutputDir $OutputDir -VoiceTrack $VoiceTrack
}
