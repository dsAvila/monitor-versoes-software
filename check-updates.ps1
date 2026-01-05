 # Verificando se os instaladores estão atualizados ou não
# E envia uma única notificação consolidada no final


# --- Caminho dos arquivos ---
$pathChrome = "\\laboratorio\Programas LAB\PROGRAMAS ATUALIZADOS\aBasicos\Todos Os Programas\ChromeStandaloneSetup64.exe"

$pathFirefox = "\\laboratorio\Programas LAB\PROGRAMAS ATUALIZADOS\aBasicos\Todos Os Programas\Firefox Setup 134.0.2.exe"

$pathJava = "\\laboratorio\Programas LAB\PROGRAMAS ATUALIZADOS\aBasicos\Todos Os Programas\jre-8u441-windows-i586.exe"

$pathKlite = "\\laboratorio\Programas LAB\PROGRAMAS ATUALIZADOS\aBasicos\Todos Os Programas\K-Lite_Codec_Pack_1915_Standard.exe"


# --- Lista para armazenar programas desatualizados ---
$outdatedPrograms = [System.Collections.ArrayList]::new()


# --- Verificação de módulo BurntToast ---
if (-not (Get-Module -Name BurntToast -ListAvailable)) {

    Write-Host "O modulo BurntToast nao foi encontrado. Instalando..."

    Install-Module -Name BurntToast -Force -Scope CurrentUser

}


# --- Enviando notificação do Windows ---
function NotificationPush {

    param (

        [string]$Title,

        [string]$Message,

        [string]$IconPath = ""

    )

    if ($IconPath) {

        New-BurntToastNotification -Text $Title, $Message -AppLogo $IconPath

    } else {

        New-BurntToastNotification -Text $Title, $Message

    }

}


# --- Comparando versões ---
function CompareVersion {

    param (

        [string]$PathProgram,

        [string]$mostCurrentVersion

    )


    if (-not (Test-Path $PathProgram)) {

        return $true

    }

   

    try {

        $fileVersionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($PathProgram)

        $installerVersion = $fileVersionInfo.FileVersion

       

        if ([string]::IsNullOrEmpty($installerVersion)) {

            return $true

        }


        $mostCurrentVersion_clean = $mostCurrentVersion -replace '[a-zA-Z]', ''

        $installerVersion_clean = $installerVersion -replace '[a-zA-Z]', ''


        if ([version]$installerVersion_clean -ge [version]$mostCurrentVersion_clean) {

            return $false

        } else {

            return $true

        }

    }

    catch {

        return $true

    }

}


# --- Verificação Google Chrome ---
function VerifyChrome {

    try {

        $json = Invoke-RestMethod -Uri "https://versionhistory.googleapis.com/v1/chrome/platforms/win/channels/stable/versions"

        $mostCurrentVersion = $json.versions[0].version

       

        if ($null -ne $mostCurrentVersion) {

            if (CompareVersion -PathProgram $pathChrome -mostCurrentVersion $mostCurrentVersion) {

                $outdatedPrograms.Add("Google Chrome") | Out-Null

            }

        } else {

            $outdatedPrograms.Add("Google Chrome (Erro na API)") | Out-Null

        }

    }

    catch {

        $outdatedPrograms.Add("Google Chrome (Erro de Verificacao)") | Out-Null

    }

}


# --- Verificação Mozilla Firefox ---
function VerifyFirefox {

    try {

        $json = Invoke-RestMethod -Uri "https://product-details.mozilla.org/1.0/firefox_versions.json"

        $mostCurrentVersion = $json.LATEST_FIREFOX_VERSION

       

        if ($null -ne $mostCurrentVersion) {

            if (CompareVersion -PathProgram $pathFirefox -mostCurrentVersion $mostCurrentVersion) {

                $outdatedPrograms.Add("Mozilla Firefox") | Out-Null

            }

        } else {

            $outdatedPrograms.Add("Mozilla Firefox (Erro na API)") | Out-Null

        }

    }

    catch {

        $outdatedPrograms.Add("Mozilla Firefox (Erro de Verificacao)") | Out-Null

    }

}


# --- Verificação Java (JRE) ---
function VerifyJava {

    try {

        # API do Adoptium para a versão LTS do Java 8

        $json = Invoke-RestMethod -Uri "https://api.adoptium.net/v3/assets/feature_releases/8/ga?jvm_impl=hotspot&heap_size=normal&os=windows&arch=x64&image_type=jre&page_size=1&vendor=eclipse"

       

        if ($json.Count -gt 0) {

            $mostCurrentVersion = $json[0].release_name

            # Formata a versão da API para comparar com a do instalador
            # Ex: jdk8u441-b01 -> 8u441

            $regex = [regex]::Match($mostCurrentVersion, '(\d+u\d+)')

            if ($regex.Success) {

                $mostCurrentVersion_clean = $regex.Groups[1].Value

                if (CompareVersion -PathProgram $pathJava -mostCurrentVersion $mostCurrentVersion_clean) {

                    $outdatedPrograms.Add("Java (JRE)") | Out-Null

                }

            } else {

                $outdatedPrograms.Add("Java (Erro na extração da versão)") | Out-Null

            }

        } else {

            $outdatedPrograms.Add("Java (Erro: Nao foi possivel encontrar a versao)") | Out-Null

        }

    }

    catch {

        $outdatedPrograms.Add("Java (Erro de Verificacao)") | Out-Null

    }

}


# --- Verificação K-Lite Codec Pack ---
function VerifyKlite {

    try {

        # Acessa a página de changelog mais confiável
        $html = Invoke-WebRequest -Uri "https://codecguide.com/changelogs_standard.htm"

       

        # Procura pela versão no título do changelog. Ex: "Changelog 19.1.0 to 19.1.5"
        $regex = [regex]::Match($html.Content, 'Changelog (\d+\.\d+\.\d+) to (\d+\.\d+\.\d+)')

       

        if ($regex.Success) {

            # Pega a versão final no título (Ex: 19.1.5)
            $mostCurrentVersion = $regex.Groups[2].Value

            if (CompareVersion -PathProgram $pathKlite -mostCurrentVersion $mostCurrentVersion) {

                $outdatedPrograms.Add("K-Lite Codec Pack") | Out-Null

            }

        } else {

            $outdatedPrograms.Add("K-Lite Codec Pack (Erro na extração da versão)") | Out-Null

        }

    }

    catch {

        $outdatedPrograms.Add("K-Lite Codec Pack (Erro de Verificacao)") | Out-Null

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