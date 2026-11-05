# Entre Lendas

![Godot Engine](https://img.shields.io/badge/Godot_Engine-4.x-478cbf?logo=godot-engine&logoColor=white)
![GDScript](https://img.shields.io/badge/Language-GDScript_2.0_(Static_Typed)-blue)
![Renderer](https://img.shields.io/badge/Renderer-Compatibility_(OpenGL_3)-success)
![Testing](https://img.shields.io/badge/Tests-GUT_(Headless_CLI)-orange)
![AI Workflow](https://img.shields.io/badge/Workflow-Agentic_CLI_%2B_MCP-purple)

**Entre Lendas** é um jogo 2D Top-Down de aventura, *puzzle*, furtividade e RPG narrativo com combate por turnos que transporta o jogador para um universo onde as entidades do folclore brasileiro são forças vivas e físicas da natureza.

Além do produto cultural e lúdico, este repositório foi estruturado como um **estudo de caso aberto em Engenharia de Software para Jogos e Desenvolvimento Orientado por Agentes de IA via CLI**, combinando arquitetura desacoplada, *Test-Driven Development* (TDD) em modo *headless* e *Context Engineering* para automação de código e direção de arte.

---

## Sumário

1. [Visão Geral e Proposta Cultural](#1-visão-geral-e-proposta-cultural)
2. [Mecânicas Centrais e o Dilema Moral](#2-mecânicas-centrais-e-o-dilema-moral)
3. [Estrutura da Antologia (As 4 Fases)](#3-estrutura-da-antologia-as-4-fases)
4. [Inventário, Diário e Artefatos](#4-inventário-diário-e-artefatos)
5. [Engenharia de Software e Decisões Técnicas](#5-engenharia-de-software-e-decisões-técnicas)
6. [Metodologia de Desenvolvimento com Agentes de IA (Estudo de Caso)](#6-metodologia-de-desenvolvimento-com-agentes-de-ia-estudo-de-caso)
7. [Arquitetura de Diretórios e Responsabilidades](#7-arquitetura-de-diretórios-e-responsabilidades)
8. [Configuração do Ambiente de Desenvolvimento (Devs & Agentes IA)](#8-configuração-do-ambiente-de-desenvolvimento-devs--agentes-ia)
9. [Como Executar e Testar (Setup via CLI)](#9-como-executar-e-testar-setup-via-cli)
10. [Padrões de Código e Contribuição](#10-padrões-de-código-e-contribuição)

---

## 1. Visão Geral e Proposta Cultural

Inspirado em obras como *Undertale*, *EarthBound*, *Mother 3* e *Omori*, **Entre Lendas** propõe uma abordagem vivencial da cultura popular brasileira. Em vez de tratar o folclore como um catálogo estático de mitos escolares, o jogo posiciona figuras como o **Saci-Pererê**, a **Mula sem Cabeça**, o **Curupira**, a **Caipora**, o **Boitatá** e a **Cuca** como guardiões dotados de propósito, história e agência ecológica.

O jogador encontra-se preso nesse universo e precisa compreender a essência dessas entidades ao longo de uma antologia dividida em quatro fases até alcançar a Cuca — a única capaz de revelar como ele chegou ali e abrir o caminho de volta para casa.

---

## 2. Mecânicas Centrais e o Dilema Moral

O eixo sistêmico e narrativo do projeto gira em torno da escolha entre **Capturar (Subjugar)** ou **Fazer Amizade (Compreender)** as entidades folclóricas. Essa decisão não é meramente cosmética; ela altera variáveis globais de estado (`WorldState`) que modificam o mundo física, visual e mecanicamente.

| Dimensão | Caminho da Captura | Caminho da Amizade (Aliança) |
| :--- | :--- | :--- |
| **Motivação / Ação** | Uso de armadilhas, confronto direto e subjugação rápida. | Investigação de *lore*, empatia, resolução de *puzzles* culturais e cooperação. |
| **Recompensa Imediata** | Concede recursos e artefatos de utilidade imediata. | Exige compreensão prévia das pistas anotadas no Diário de Investigação. |
| **Impacto Ecológico (`nature_balance`)** | Degradação progressiva: árvores secas, rios poluídos, fumaça e ausência de fauna nos mapas. | Restauração progressiva: vegetação exuberante, águas limpas e retorno dos animais. |
| **Consequências Sistêmicas** | Perda de auxílio em fases futuras, bloqueio de rotas alternativas e maior hostilidade em desafios. | Desbloqueio de habilidades cooperativas, atalhos secretos e suporte direto das entidades. |

### Combate por Turnos com Resolução Moral
Quando um conflito se inicia, a transição para a tela de batalha oferece quatro vetores de ação:
* **Confrontar / Agir:** Avança o progresso de subjugação/captura.
* **Compreender:** Utiliza o conhecimento adquirido nos diálogos e no diário para demonstrar respeito e empatia pela entidade, elevando o índice de afinidade.
* **Item:** Permite o uso de ferramentas táticas ou artefatos folclóricos.
* **Aliança (Poupar):** Habilitado quando a compreensão atinge 100%, encerrando o conflito de forma colaborativa.

---

## 3. Estrutura da Antologia (As 4 Fases)

1. **Fase 1 — O Saci-Pererê (Cotidiano Brasileiro):**
   * *Ambientação:* Ruazinhas urbanas/rurais brasileiras e interiores domésticos repletos de identidade visual nacional (muros pichados, quintais com varais, móveis revirados).
   * *Gameplay:* Investigação da origem multicultural do Saci. O jogador decide entre capturar seus redemoinhos com uma peneira (seguido de desafios espaciais pelo gorro) ou provar que compreende sua história em um desafio de memória e travessia cooperativa.
2. **Fase 2 — A Mula sem Cabeça (Vilarejo e Transição Dia/Noite):**
   * *Ambientação:* Vilarejo do interior que transiciona gradualmente da luz do dia para a escuridão tensa da noite de quinta-feira.
   * *Gameplay:* Durante o dia, investigação social e coleta de pistas no Diário para descobrir quem é a mulher por trás da maldição. À noite, mecânica de furtividade (*stealth*) guiada pelo áudio posicional dos relinchos e uso de esconderijos.
3. **Fase 3 — Os Guardiões da Floresta (Floresta Amazônica):**
   * *Ambientação:* Contraste entre a floresta densa preservada, áreas devastadas por madeireiros/caçadores e a caverna ancestral de pinturas rupestres.
   * *Gameplay:* Aliança com o **Curupira** e a **Caipora** para libertar animais, plantar mudas e usar rastros invertidos para enganar o cone de visão dos caçadores. O clímax consiste em atrair os invasores até a caverna para despertar o **Boitatá**.
4. **Fase 4 — A Cuca (Floresta das Ilusões e Desfecho):**
   * *Ambientação:* Mata fechada noturna coberta por neblina densa e geometria espacial mutável.
   * *Gameplay:* A Cuca testa a coerência moral do jogador projetando ilusões baseadas nas escolhas das Fases 1 a 3. O jogador utiliza pistas acumuladas e o *Espelho da Cuca* para discernir a realidade da ilusão antes do diálogo final ramificado.

---

## 4. Inventário, Diário e Artefatos

O sistema de inventário é orientado a dados (`Resource`) e divide-se em três categorias: **Itens Usáveis**, **Artefatos de Lendas** e **Diário de Consulta (Pistas)**.

| Artefato / Item | Fase Associada | Aplicação Mecânica |
| :--- | :--- | :--- |
| **Gorro do Saci** | Fase 1 | Permite acessar passagens especiais e interagir com mecanismos de vento. |
| **Ferradura da Mula** | Fase 2 | Revela rastros ocultos da Mula sem Cabeça e pistas invisíveis no vilarejo. |
| **Assobio da Caipora** | Fase 3 | Aciona o suporte da Caipora e destaca a localização de animais enjaulados. |
| **Pegada Falsa** | Fase 3 | Gera rastros invertidos no mapa para manipular a rota de patrulha de caçadores. |
| **Brasa do Boitatá** | Fase 3 | Ilumina zonas de escuridão profunda, repele ameaças e abre barreiras ancestrais. |
| **Espelho da Cuca** | Fase 4 | Desfaz ilusões ópticas no mapa, revelando colisões e caminhos verdadeiros. |
| **Ervas da Cuca** | Fase 4 | Ingredientes coletáveis empregados na resolução de enigmas alquímicos. |
| **Amuleto de Proteção** | Global | Mitiga efeitos adversos e danos durante os turnos defensivos de batalha. |

---

## 5. Engenharia de Software e Decisões Técnicas

Para garantir manutenibilidade, desempenho em hardware modesto e testabilidade via linha de comando, o projeto adota decisões arquiteturais estritas:

### 5.1. Escolha do Renderizador (`Compatibility` / OpenGL 3)
Optou-se pelo renderizador **Compatibility** em vez do *Forward+ (Vulkan)* pelos seguintes motivos:
* **Tempo de Inicialização Instantâneo:** Essencial para execução contínua de testes automatizados e validação rápida de cenas via terminal.
* **Zero Micro-Stutters:** Evita engasgos de compilação de pipelines Vulkan em um projeto 2D que utiliza iluminação clássica (`CanvasModulate` + `PointLight2D`).
* **Portabilidade Máxima:** Permite exportação nativa e leve para Linux, Windows e Web (WebGL 2) sem alterações de código.

### 5.2. Separação entre Lógica Pura (`RefCounted`) e Nós Visuais (`Node`)
Um dos maiores problemas no desenvolvimento de jogos é acoplar regras de negócio diretamente aos scripts de interface ou física. Neste projeto:
* **Regras de Negócio (`RefCounted` / `Resource`):** Sistemas como `InventorySystem`, cálculos de afinidade do `WorldState` e transições lógicas de turno não dependem da árvore gráfica (`SceneTree`). Isso permite que sejam instanciados e validados em milissegundos via testes unitários *headless*.
* **Camada de Apresentação (`Node2D` / `Control`):** Os nós da Godot atuam apenas como sensores físicos e renderizadores visuais, comunicando-se pelo padrão **"Signals Up, Call Down"** (pais invocam métodos dos filhos; filhos emitem sinais para os pais ou para o `EventBus`).

### 5.3. Física Top-Down, Grid e Sistema "Paper Doll" Modular
* **Movimento:** Todas as entidades móveis utilizam `CharacterBody2D` com `motion_mode = MOTION_MODE_FLOATING` e gravidade zero, garantindo deslizamento preciso em colisões diagonais.
* **Proporção e Profundidade (Y-Sort):** O mundo utiliza tiles de `32x32` px (`TileMapLayer`), enquanto personagens possuem `32x64` px. O pivô dos sprites é ancorado na base dos pés (`offset.y = -32`) e o `CollisionShape2D` ocupa apenas a metade inferior do corpo, permitindo sobreposição natural atrás de paredes e árvores via `y_sort_enabled = true`.
* **Arquitetura Paper Doll (Manequim Modular):** O personagem base é dividido em 5 camadas sincronizadas (`head`, `chest`, `legs`, `arm_L`, `arm_R`), incluindo variações específicas de braços (`Holding_Idle`, `Holding_Run`) para segurar itens dinamicamente sem necessidade de redesenhar o corpo inteiro.

---

## 6. Metodologia de Desenvolvimento com Agentes de IA (Estudo de Caso)

Este repositório implementa uma arquitetura de **Engenharia de Contexto (`.agents/`)** desenhada para resolver os três principais desafios do uso de LLMs no desenvolvimento de jogos:
1. **Alucinação de APIs Legadas:** Modelos de IA frequentemente misturam código de *Godot 3* (`KinematicBody2D`, `yield`, `TileMap` antigo) com *Godot 4*.
2. **Perda de Coerência Visual:** Geração procedural de arte sem restrições costuma destruir a direção de arte de um jogo.
3. **Degradação Arquitetural:** Sem diretrizes explícitas, agentes tendem a criar scripts monolíticos e acoplados.

### Como o Diretório `.agents/` Resolve Esses Problemas

```text
Fluxo de Execução do Agente via CLI:
[Prompt no Terminal]
       │
       ▼
[1. Leitura de .agents/AGENTS.md] (Regras Globais e Travas de Segurança)
       │
       ├──► [2. Consulta a .agents/context/] (GDD, Arquitetura, Física e Direção de Arte)
       ├──► [3. Aplicação de .agents/skills/] (Receitas padronizadas de código e MCP PixelLab)
       └──► [4. Execução de .agents/tasks/] (Implementação incremental + Validação no GUT)
```

* **`AGENTS.md`:** Funciona como o contrato do sistema. Proíbe sintaxe da Godot 3, exige tipagem estática em 100% do código GDScript 2.0 e obriga a validação via CLI após cada edição.
* **Trava de Direção de Arte (`05_art_direction.md` + MCP PixelLab):** O agente está proibido de gerar sprites ou tilesets do zero absoluto. Antes de chamar o servidor MCP do PixelLab, ele é obrigado a ler os arquivos em `assets/art/_templates/` (o manequim modular `32x64` e o tileset base `32x32`) para preservar paleta, traço e proporção.
* **Isolamento Ético e Técnico de Referências (`_inspirations/`):** Artes conceituais e referências culturais ficam isoladas em `assets/art/_inspirations/` acompanhadas de um arquivo `.gdignore`. Isso permite que agentes de IA analisem conceitos visuais sem jamais importar arquivos de referência na compilação do jogo ou copiá-los diretamente.

---

## 7. Arquitetura de Diretórios e Responsabilidades

```text
entre-lendas/
├── .agents/                        # Engenharia de Contexto para Agentes de IA (CLI)
│   ├── AGENTS.md                   # Ponto de entrada, regras de ouro e índice de contexto
│   ├── context/                    # Documentação de domínio (GDD, Arquitetura, Física, Arte, MCP)
│   ├── skills/                     # Tutoriais técnicos passo a passo para geração de sistemas e assets
│   └── tasks/                      # Sprints acionáveis e backlog estruturado em checklists
│
├── addons/
│   └── gut/                        # Framework GUT (Godot Unit Test) para TDD via linha de comando
│
├── assets/
│   ├── art/
│   │   ├── _templates/             # [FONTE DA VERDADE] Manequim modular 32x64 e Tileset base 32x32
│   │   ├── _inspirations/          # [CONCEITO] Moodboards e referências (contém .gdignore)
│   │   ├── characters/             # Spritesheets de produção (player, folklore, npcs, enemies)
│   │   ├── tilesets/               # Tilesets 32x32 finais usados nos mapas
│   │   ├── props/                  # Objetos de cenário interagíveis e decorativos
│   │   ├── items/                  # Ícones 32x32 de itens e pistas do diário
│   │   └── ui/                     # Texturas de interface, caixas de diálogo e HUD
│   ├── audio/                      # Trilhas sonoras adaptativas (BGM) e efeitos posicionais (SFX)
│   └── fonts/                      # Fontes tipográficas pixel art
│
├── core/                           # Sistemas independentes de fase (Lógica Pura e Singletons)
│   ├── autoloads/                  # EventBus, WorldState, InventoryManager, AudioManager
│   ├── combat/                     # Motor de batalha por turnos e resolução moral
│   ├── dialogue/                   # Parser de diálogos ramificados e condições de estado
│   ├── inventory/                  # Classes ItemData (Resource) e InventorySystem (RefCounted)
│   └── state_machine/              # Classes base para Máquinas de Estado Finito (FSM)
│
├── components/                     # Componentes reutilizáveis (Interactable, Hitbox, StealthDetector)
├── entities/                       # Cenas (.tscn) e controladores de Player, Entidades e NPCs
├── stages/                         # Cenas e scripts específicos das 4 fases da antologia
├── ui/                             # Cenas de interface (Inventário, Diário, Caixa de Diálogo)
├── tests/                          # Suíte de testes unitários automatizados (GUT)
└── project.godot                   # Configuração central da engine, inputs e camadas de física
```

---

## 8. Configuração do Ambiente de Desenvolvimento (Devs & Agentes IA)

Para replicar o fluxo completo de desenvolvimento deste repositório (programação, testes automatizados e geração assistida de *pixel art*), configure as ferramentas abaixo no seu ambiente local:

### 8.1. Godot Engine & CLI no PATH
1. Instale a **Godot Engine 4.3+** (versão *Standard*, GDScript).
2. Certifique-se de que o binário da engine esteja acessível globalmente no terminal através do comando `godot`:
   ```bash
   godot --version
   ```
   *(Isso é indispensável para que os agentes de IA e scripts de CI possam validar sintaxe e rodar testes unitários em modo `--headless`).*

### 8.2. Configuração do MCP do PixelLab (Geração e Customização de Assets)
O projeto utiliza o **Model Context Protocol (MCP)** do PixelLab integrado diretamente às CLIs de agentes de IA (como Codex CLI, Claude Code, Gemini CLI, Cursor, Cline, etc.). Com o MCP ativo, o agente consegue ler os templates base em `assets/art/_templates/` e gerar/customizar personagens (`32x64`), animações e tilesets (`32x32`) diretamente pelo terminal.

* **Guia Oficial de Instalação para cada CLI/Editor:**  
  👉 **[https://www.pixellab.ai/mcp](https://www.pixellab.ai/mcp)**
* **Referência de Documentação das Tools para o Agente:**  
  A documentação técnica dos endpoints (`https://api.pixellab.ai/mcp/docs`) já é sincronizada localmente em `.agents/context/06_pixellab_mcp_docs.md`. Caso queira atualizá-la manualmente via terminal, execute:
  ```bash
  curl -sL [https://api.pixellab.ai/mcp/docs](https://api.pixellab.ai/mcp/docs) -o .agents/context/06_pixellab_mcp_docs.md
  ```

### 8.3. Linter, Formatter e LSP (Editor Externo)
Para manter a qualidade estática do código GDScript fora da IDE da Godot:
1. **GDScript Toolkit (`gdtoolkit`):** Instale via Python/pip para ter `gdlint` (análise estática) e `gdformat` (formatação automática) no terminal:
   ```bash
   pip install gdtoolkit
   ```
2. **Language Server Protocol (LSP):** Ao usar VS Code, Neovim ou outro editor externo, mantenha o editor da Godot aberto em segundo plano. A Godot expõe automaticamente o servidor LSP na porta local **`6005`**, fornecendo *autocomplete* e checagem de tipos em tempo real.
3. **Padronização de Arquivos (`.editorconfig`):** O repositório inclui um `.editorconfig` configurado na raiz. Certifique-se de que seu editor respeite indentação por *tabs* para `.gd` e *UTF-8* com quebra de linha `LF`.

### 8.4. Como Instruir seu Agente CLI ao Iniciar uma Sessão
Ao abrir sua ferramenta de IA no terminal na raiz do projeto, inicie sempre apontando para o contrato de engenharia do repositório:
```text
Leia o arquivo .agents/AGENTS.md para carregar as regras de arquitetura e direção de arte do projeto, e em seguida execute a <Task X> descrita em .agents/tasks/sprint_01_foundation.md.
```

---

## 9. Como Executar e Testar (Setup via CLI)

### 1. Clonar e Inicializar o Cache de Classes
Ao clonar o repositório pela primeira vez, indexe as classes globais (`class_name`) em modo *headless* antes de rodar os testes:

```bash
git clone <url-do-repositorio>
cd entre-lendas
godot --headless --editor --quit
```

### 2. Executar o Jogo
Para abrir o projeto no editor gráfico:
```bash
godot --editor project.godot
```
Para executar o jogo diretamente a partir do terminal:
```bash
godot --path .
```

### 3. Executar a Suíte de Testes Unitários (GUT Headless)
Todos os sistemas de lógica pura e estado de mundo podem ser validados sem abrir janelas gráficas:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

### 4. Validar Sintaxe de Scripts Rapidamente
```bash
godot --headless --path . --check-only
```

---

## 10. Padrões de Código e Contribuição

Qualquer desenvolvedor humano ou agente de IA atuando neste repositório deve respeitar as seguintes diretrizes:

1. **Tipagem Estática Obrigatória:** Toda variável, parâmetro e retorno de função em GDScript deve possuir tipo explícito (`var speed: float = 120.0`, `func apply_choice(id: StringName) -> void:`).
2. **Uso de `StringName`:** Referências a ações de input, animações e identificadores devem utilizar literais `StringName` (ex: `&"move_up"`, `&"saci"`).
3. **Camadas de Física Documentadas:** Antes de configurar colisões em cenas `.tscn`, consulte a matriz oficial em `.agents/context/03_physics_and_layers.md`.
4. **Respeito Estrito aos Templates de Arte:** Novos sprites e tilesets jamais devem ser gerados fora da escala ou sem derivar dos arquivos contidos em `res://assets/art/_templates/`.
5. **Testes Antes de Merge:** Novas regras de negócio no `WorldState`, inventário ou combate devem vir acompanhadas de seu respectivo teste em `res://tests/` com aprovação integral no executor CLI do GUT.