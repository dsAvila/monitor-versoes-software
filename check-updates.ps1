<#
.SYNOPSIS
    Monitor de Atualizações de Software.
.DESCRIPTION
    Verifica versões locais contra APIs oficiais e notifica via BurntToast.
    Exibe status detalhado no console (Write-Host) e notificação resumida no Windows.
#>

# --- IMPORTANTE ---
# Para alterar o caminho dos executaveis vá para o arquivo config.json
# Caso queira remover o caminho do icone para a notificação, não esqueça de remover do código para não ter erros

# --- 1. Carregamento da Configuração ---
$ConfigFilePath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"

if (-not (Test-Path $ConfigFilePath)) {
    Write-Host "ERRO CRÍTICO: O arquivo 'config.json' não foi encontrado na pasta do script." -ForegroundColor Red
    Write-Host "Local esperado: $ConfigFilePath"
    exit
}

# Lê o arquivo JSON e converte para um objeto do PowerShell
try {
    $AppConfig = Get-Content -Path $ConfigFilePath -Raw | ConvertFrom-Json
} catch {
    Write-Host "ERRO: O arquivo 'config.json' está mal formatado." -ForegroundColor Red
    exit
}

# User-Agent para simular um navegador real e evitar bloqueios
# (Fixo, pois é configuração técnica do script, não do ambiente)
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# Lista para armazenar o resultado final
$global:outdatedPrograms = [System.Collections.ArrayList]::new()


# --- 2. Preparação do Ambiente ---
if (-not (Get-Module -Name BurntToast -ListAvailable)) {
    Write-Host "Instalando módulo BurntToast..." -ForegroundColor Yellow
    Install-Module -Name BurntToast -Force -Scope CurrentUser -ErrorAction SilentlyContinue
}


# --- 3. Funções Auxiliares ---
function Send-Notification {
    param (
        [string]$Title,
        [string]$Message,
        [string]$Icon
    )
    $params = @{ Text = $Title, $Message }
    # Verifica se o caminho do ícone existe antes de tentar usar
    if ($Icon -and (Test-Path $Icon)) { $params.Add('AppLogo', $Icon) }
    New-BurntToastNotification @params
}

function Test-Version {
    param (
        [string]$PathProgram,
        [string]$OnlineVersion
    )

    if (-not (Test-Path $PathProgram)) {
        return "NotFound"
    }
    
    try {
        $fileVersionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($PathProgram)
        $localVersion = $fileVersionInfo.FileVersion
        
        if ([string]::IsNullOrEmpty($localVersion)) { return "NoVersionInfo" }

        $onlineClean = $OnlineVersion -replace '[^\d.]', ''
        $localClean = $localVersion -replace '[^\d.]', ''

        if ([version]$localClean -ge [version]$onlineClean) {
            return "UpToDate"
        } else {
            return "Outdated"
        }
    }
    catch {
        return "Error"
    }
}


# --- 4. Verificações Específicas ---
function Verify-Chrome {
    Write-Host "Verificando Google Chrome..." -NoNewline
    try {
        $json = Invoke-RestMethod -Uri "https://versionhistory.googleapis.com/v1/chrome/platforms/win/channels/stable/versions" -UserAgent $UserAgent
        $ver = $json.versions[0].version
        
        if ($ver) {
            $status = Test-Version -PathProgram $AppConfig.Chrome -OnlineVersion $ver
            if ($status -eq "Outdated") { 
                $global:outdatedPrograms.Add("Google Chrome") | Out-Null
                Write-Host " [DESATUALIZADO] (Nova: $ver)" -ForegroundColor Red 
            }
            elseif ($status -eq "NotFound") { 
                $global:outdatedPrograms.Add("Chrome (Arquivo não encontrado)") | Out-Null
                Write-Host " [ERRO CAMINHO]" -ForegroundColor Magenta 
            }
            else { Write-Host " [OK]" -ForegroundColor Green }
        }
    } catch { 
        Write-Host " [ERRO API]" -ForegroundColor DarkRed
        $global:outdatedPrograms.Add("Google Chrome (Erro API)") | Out-Null 
    }
}

function Verify-Firefox {
    Write-Host "Verificando Firefox..." -NoNewline
    try {
        $json = Invoke-RestMethod -Uri "https://product-details.mozilla.org/1.0/firefox_versions.json" -UserAgent $UserAgent
        $ver = $json.LATEST_FIREFOX_VERSION
        
        if ($ver) {
            $status = Test-Version -PathProgram $AppConfig.Firefox -OnlineVersion $ver
            if ($status -eq "Outdated") { 
                $global:outdatedPrograms.Add("Mozilla Firefox") | Out-Null
                Write-Host " [DESATUALIZADO] (Nova: $ver)" -ForegroundColor Red 
            }
            elseif ($status -eq "NotFound") { 
                $global:outdatedPrograms.Add("Firefox (Arquivo não encontrado)") | Out-Null
                Write-Host " [ERRO CAMINHO]" -ForegroundColor Magenta 
            }
            else { Write-Host " [OK]" -ForegroundColor Green }
        }
    } catch { 
        Write-Host " [ERRO API]" -ForegroundColor DarkRed
        $global:outdatedPrograms.Add("Mozilla Firefox (Erro API)") | Out-Null 
    }
}

function Verify-Java {
    Write-Host "Verificando Java (JRE)..." -NoNewline
    try {
        $json = Invoke-RestMethod -Uri "https://api.adoptium.net/v3/assets/feature_releases/8/ga?jvm_impl=hotspot&heap_size=normal&os=windows&arch=x64&image_type=jre&page_size=1&vendor=eclipse" -UserAgent $UserAgent
        if ($json.Count -gt 0) {
            $rawVer = $json[0].release_name
            $regex = [regex]::Match($rawVer, '(\d+u\d+)')
            
            if ($regex.Success) {
                $ver = $regex.Groups[1].Value
                $status = Test-Version -PathProgram $AppConfig.Java -OnlineVersion $ver
                
                if ($status -eq "Outdated") { 
                    $global:outdatedPrograms.Add("Java (JRE)") | Out-Null
                    Write-Host " [DESATUALIZADO] (Nova: $ver)" -ForegroundColor Red 
                }
                elseif ($status -eq "NotFound") { 
                    $global:outdatedPrograms.Add("Java (Arquivo não encontrado)") | Out-Null
                    Write-Host " [ERRO CAMINHO]" -ForegroundColor Magenta 
                }
                else { Write-Host " [OK]" -ForegroundColor Green }
            } else {
                Write-Host " [ERRO REGEX]" -ForegroundColor DarkRed
                $global:outdatedPrograms.Add("Java (Erro Extração)") | Out-Null
            }
        }
    } catch { 
        Write-Host " [ERRO API]" -ForegroundColor DarkRed
        $global:outdatedPrograms.Add("Java (Erro API)") | Out-Null 
    }
}

function Verify-Klite {
    Write-Host "Verificando K-Lite Codec..." -NoNewline
    try {
        $html = Invoke-WebRequest -Uri "https://codecguide.com/changelogs_standard.htm" -UserAgent $UserAgent
        $regex = [regex]::Match($html.Content, 'Changelog (\d+\.\d+\.\d+) to (\d+\.\d+\.\d+)')
        
        if ($regex.Success) {
            $ver = $regex.Groups[2].Value
            $status = Test-Version -PathProgram $AppConfig.Klite -OnlineVersion $ver
            
            if ($status -eq "Outdated") { 
                $global:outdatedPrograms.Add("K-Lite Codec Pack") | Out-Null
                Write-Host " [DESATUALIZADO] (Nova: $ver)" -ForegroundColor Red 
            }
            elseif ($status -eq "NotFound") { 
                $global:outdatedPrograms.Add("K-Lite (Arquivo não encontrado)") | Out-Null
                Write-Host " [ERRO CAMINHO]" -ForegroundColor Magenta 
            }
            else { Write-Host " [OK]" -ForegroundColor Green }
        } else {
             Write-Host " [ERRO REGEX]" -ForegroundColor DarkRed
             $global:outdatedPrograms.Add("K-Lite (Erro Regex)") | Out-Null
        }
    } catch { 
        Write-Host " [ERRO NO SITE]" -ForegroundColor DarkRed
        $global:outdatedPrograms.Add("K-Lite (Erro Site)") | Out-Null 
    }
}


# --- 5. Execução Principal ---
Clear-Host
Write-Host "--- Iniciando Verificação ---" -ForegroundColor Cyan
Write-Host "Lendo configuração de: $ConfigFilePath`n" -ForegroundColor Gray

Verify-Chrome
Verify-Firefox
Verify-Java
Verify-Klite

Write-Host "`n--- Verificação Concluída ---" -ForegroundColor Cyan


# --- 6. Notificação Final ---
if ($outdatedPrograms.Count -gt 0) {
    $msg = "Desatualizados: " + ($outdatedPrograms -join ", ") + ". Verifique o laboratório."
    Send-Notification -Title "Atualizações Pendentes" -Message $msg -Icon $AppConfig.IconPath
} else {
    Send-Notification -Title "Tudo Atualizado" -Message "Todos os programas verificados estão na versão mais recente." -Icon $AppConfig.IconPath
}