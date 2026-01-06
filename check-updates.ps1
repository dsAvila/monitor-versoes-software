<#
.SYNOPSIS
    Monitor de Atualizações de Software.
.DESCRIPTION
    Verifica versões locais contra APIs oficiais e notifica via BurntToast.
    Exibe status detalhado no console (Write-Host) e notificação resumida no Windows.
#>


 # Verificando se os instaladores estão atualizados ou não
# E envia uma única notificação consolidada no final


# --- 1. Configurações e Caminhos ---
# Edite os caminhos aqui.
$AppConfig = @{
  Chrome = "\\laboratorio\Programas LAB\PROGRAMAS ATUALIZADOS\aBasicos\Todos Os Programas\ChromeStandaloneSetup64.exe"
  Firefox = "\\laboratorio\Programas LAB\PROGRAMAS ATUALIZADOS\aBasicos\Todos Os Programas\Firefox Setup 134.0.2.exe"
  Java = "\\laboratorio\Programas LAB\PROGRAMAS ATUALIZADOS\aBasicos\Todos Os Programas\jre-8u441-windows-i586.exe"
  Klite = "\\laboratorio\Programas LAB\PROGRAMAS ATUALIZADOS\aBasicos\Todos Os Programas\K-Lite_Codec_Pack_1915_Standard.exe"
}

# --- Não obrigatório ---
$IconPath = "C:\Users\Usuario\Pictures\Scripts\alert-icon.png" # Icone para quando a notificação aparecer no Windows

# User-Agent para simular um navegador real e evitar bloqueios
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# Lista para armazenar o resultado final
$global:outdatedPrograms = [System.Collections.ArrayList]::new()


# --- 2. Preparação do Ambiente ---
if (-not (Get-Module -Name BurntToast -ListAvailable)) {
    Write-Host "Instalando módulo BurntToast..." -ForegroundColor Yellow
    Install-Module -Name BurntToast -Force -Scope CurrentUser -ErrorAction SilentlyContinue
}


# --- 3. Funções Auxiliares ---
# Função para enviar a notificação do Windows
function Send-Notification {
    param (
        [string]$Title,
        [string]$Message,
        [string]$Icon
    )
    $params = @{ Text = $Title, $Message }
    if ($Icon -and (Test-Path $Icon)) { $params.Add('AppLogo', $Icon) }
    New-BurntToastNotification @params
}


# Função genérica que compara as versões e escreve na tela
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

        # Limpa textos extras para comparar apenas números (Ex: "19.1.5.0" vs "19.1.5")
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
                Write-Host " [DESATUALIZADO] (Nova versão: $ver)" -ForegroundColor Red 
            }
            elseif ($status -eq "NotFound") { 
                $global:outdatedPrograms.Add("Chrome (Arquivo não encontrado)") | Out-Null
                Write-Host " [ERRO: ARQUIVO NÃO ENCONTRADO]" -ForegroundColor Magenta 
            }
            else { 
                Write-Host " [OK]" -ForegroundColor Green 
            }
        }
    } catch { 
        Write-Host " [ERRO NA API]" -ForegroundColor DarkRed
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
                Write-Host " [DESATUALIZADO] (Nova versão: $ver)" -ForegroundColor Red 
            }
            elseif ($status -eq "NotFound") { 
                $global:outdatedPrograms.Add("Firefox (Arquivo não encontrado)") | Out-Null
                Write-Host " [ERRO: ARQUIVO NÃO ENCONTRADO]" -ForegroundColor Magenta 
            }
            else { 
                Write-Host " [OK]" -ForegroundColor Green 
            }
        }
    } catch { 
        Write-Host " [ERRO NA API]" -ForegroundColor DarkRed
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
                    Write-Host " [DESATUALIZADO] (Nova versão: $ver)" -ForegroundColor Red 
                }
                elseif ($status -eq "NotFound") { 
                    $global:outdatedPrograms.Add("Java (Arquivo não encontrado)") | Out-Null
                    Write-Host " [ERRO: ARQUIVO NÃO ENCONTRADO]" -ForegroundColor Magenta 
                }
                else { 
                    Write-Host " [OK]" -ForegroundColor Green 
                }
            } else {
                Write-Host " [ERRO REGEX]" -ForegroundColor DarkRed
                $global:outdatedPrograms.Add("Java (Erro Extração)") | Out-Null
            }
        }
    } catch { 
        Write-Host " [ERRO NA API]" -ForegroundColor DarkRed
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
                Write-Host " [DESATUALIZADO] (Nova versão: $ver)" -ForegroundColor Red 
            }
            elseif ($status -eq "NotFound") { 
                $global:outdatedPrograms.Add("K-Lite (Arquivo não encontrado)") | Out-Null
                Write-Host " [ERRO: ARQUIVO NÃO ENCONTRADO]" -ForegroundColor Magenta 
            }
            else { 
                Write-Host " [OK]" -ForegroundColor Green 
            }
        } else {
             Write-Host " [ERRO REGEX]" -ForegroundColor DarkRed
             $global:outdatedPrograms.Add("K-Lite (Erro Regex)") | Out-Null
        }
    } catch { 
        Write-Host " [ERRO NO SITE]" -ForegroundColor DarkRed
        $global:outdatedPrograms.Add("K-Lite (Erro Site)") | Out-Null 
    }
}


# --- Executando as verificações ---
VerifyChrome

VerifyFirefox

VerifyJava

VerifyKlite


# --- Notificação Final ---
$iconAlert = "C:\Users\Usuario\Pictures\Scripts\alert-icon.png"


if ($outdatedPrograms.Count -gt 0) {

    # Para a exibição, convertemos a lista para um array e juntamos os itens.
    $message = "Os seguintes programas estao desatualizados: " + ($outdatedPrograms -join ", ") + ". Procure atualiza-los."

    NotificationPush -Title "Atualizacoes de Programas" -Message $message -IconPath $iconAlert

} else {

    NotificationPush -Title "Atualizacoes de Programas" -Message "Todos os seus programas estao atualizados." -IconPath $iconAlert

} 