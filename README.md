# 🖥️ Monitor de Atualizações de Software

Script em PowerShell desenvolvido para automatizar a verificação de versões de softwares. Ele compara a versão dos instaladores locais (`.exe`) contra as versões mais recentes disponíveis nas APIs oficiais e notifica o administrador caso haja atualizações pendentes.

## 🚀 Funcionalidades

- **Verificação Automatizada:** Checa Google Chrome, Mozilla Firefox, Java (JRE) e K-Lite Codec Pack.
- **Configuração Externa:** Caminhos de rede e ícones são configurados em um arquivo `config.json` separado, facilitando a manutenção.
- **Notificações Nativas:** Utiliza o módulo `BurntToast` para exibir notificações elegantes no Windows 10/11.
- **APIs Oficiais:** Utiliza APIs diretas do Google, Mozilla e Adoptium para garantir precisão nas versões.
- **Web Scraping Inteligente:** Monitora o changelog do K-Lite para detectar novas versões.
- **Log Visual:** Exibe status colorido no terminal para depuração manual.

---

## 📋 Pré-requisitos

Para executar este script, você precisa de:

1. **Sistema Operacional:** Windows 10 ou Windows 11.
2. **PowerShell:** Versão 5.1 ou superior.
3. **Internet:** Acesso liberado para consultar as APIs dos fabricantes.
4. **Permissões:** Acesso de leitura aos caminhos de rede onde os instaladores estão salvos.

---

## ⚙️ Instalação e Configuração

### 1. Clone ou Baixe o Repositório

Baixe os arquivos para uma pasta local (ex: `C:\Scripts\MonitorAtualizacoes`).

### 2. Configure o `config.json`

O script depende deste arquivo para saber onde estão seus instaladores.

> **⚠️ Importante:** Como é um arquivo JSON, você deve usar **barras duplas** (`\\`) para separar as pastas nos caminhos.

Abra o arquivo `config.json` e edite os caminhos conforme o seu ambiente:

```json
{
  "Chrome": "\\\\servidor\\Programas\\ChromeStandaloneSetup64.exe",
  "Firefox": "\\\\servidor\\Programas\\Firefox Setup.exe",
  "Java": "\\\\servidor\\Programas\\jre-windows-i586.exe",
  "Klite": "\\\\servidor\\Programas\\K-Lite_Codec_Pack_Standard.exe",
  "IconPath": "C:\\Scripts\\img\\alert-icon.png"
}
```
