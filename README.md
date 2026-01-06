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

Baixe os arquivos para uma pasta local (ex: `C:\Scripts\MonitorAtualizacoes`). Certifique-se de que os arquivos `check-updates.ps1` e `config.json` estejam na mesma pasta.

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

---

## ▶️ Como Executar

### Opção A: Execução Manual
Abra o PowerShell na pasta do script e execute:

```powershell
.\check-updates.ps1
```

### Opção B: Automação (Agendador de Tarefas)
Para configurar o script para rodar sozinho (ex: todo dia às 09:00), siga este tutorial:

1. Pressione `Win + R`, digite `taskschd.msc` e dê Enter.
2. No menu lateral direito, clique em **Criar Tarefa Básica**.
3. **Nome:** Digite "Monitor de Atualizações" e avance.
4. **Disparador:** Escolha a frequência desejada (ex: **Diariamente** ou **Semanalmente**) e defina o horário.
5. **Ação:** Escolha **Iniciar um programa**.
6. Preencha os campos da seguinte forma:
   - **Programa/Script:** `powershell.exe`
   - **Adicione argumentos (opcional):**
     ```text
     -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Caminho\Para\Seu\Script\check-updates.ps1"
     ```
     *(Substitua `C:\Caminho...` pelo local real onde você salvou o script)*.
   
   > **Dica:** O argumento `-WindowStyle Hidden` faz o script rodar em segundo plano, sem abrir janelas na sua tela.

7. Clique em **Concluir**. Pronto!

---

## 🧠 Detalhes Técnicos

O script utiliza métodos distintos para garantir a confiabilidade:

| Software | Método de Verificação | Fonte de Dados |
| :--- | :--- | :--- |
| **Google Chrome** | API JSON | `versionhistory.googleapis.com` |
| **Firefox** | API JSON | `product-details.mozilla.org` |
| **Java (JRE)** | API JSON | `api.adoptium.net` (Eclipse Adoptium) |
| **K-Lite Codec** | Web Scraping (Regex) | `codecguide.com/changelogs_standard.htm` |

---

## 🛠️ Solução de Problemas

| Erro | Causa Provável | Solução |
| :--- | :--- | :--- |
| **ERRO CRÍTICO: config.json não encontrado** | O arquivo JSON não está na mesma pasta do `.ps1`. | Mova ambos para a mesma pasta. |
| **Mal formatado / Erro ao ler JSON** | Erro de sintaxe no arquivo de configuração. | Verifique se usou barras duplas (`\\`) nos caminhos e se não esqueceu vírgulas ou aspas. |
| **[ERRO CAMINHO]** | O script não achou o `.exe` na rede. | Verifique se o servidor está ligado ou se o nome do arquivo mudou. |
| **Notificação não aparece** | O "Assistente de Foco" do Windows está ligado. | Desative o "Não Perturbe" ou verifique as configurações de notificação do Windows. |