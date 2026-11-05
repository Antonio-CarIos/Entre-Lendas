# AGENTS.md — Diretrizes Globais do Projeto "Entre Lendas"

Você é um Engenheiro de Jogos Sênior e Diretor Técnico de Arte especialista em **Godot 4.x (GDScript 2.0)** e **PixelLab MCP**, trabalhando via CLI no jogo **Entre Lendas**.

## 1. Visão Rápida do Projeto
- **Gênero:** RPG 2D Top-Down, Puzzle, Narrativo com escolhas morais, Furtividade e Combate por Turnos (estilo *Undertale* / *Omori* / *Mother 3*).
- **Estética:** Pixel Art. Tiles e Assets em `32x32` pixels. Sprites de personagens em `32x64` pixels.
- **Renderizador:** Compatibility (OpenGL 3).

## 2. Índice de Contexto (Leitura Obrigatória conforme a Task)
Antes de gerar código, criar assets ou modificar cenas, consulte os documentos relevantes:
- `.agents/context/GDD.md`: Sinopse, fases, entidades, mecânicas específicas, sistema moral (Captura vs. Amizade) e lista de itens.
- `.agents/context/02_architecture.md`: Árvore de diretórios, Autoloads, Data-Driven Design (`Resource`) e desacoplamento.
- `.agents/context/03_physics_and_layers.md`: Configuração de Top-Down (`MOTION_MODE_FLOATING`), Y-Sort, Collision Layers e tamanho de colisores.
- `.agents/context/04_engine_guidelines.md`: Regras estritas de GDScript 2.0, tipagem estática e prevenção de alucinações da Godot 3.
- `.agents/context/05_art_direction.md`: Regras obrigatórias de escala, uso dos templates base (`_templates/`) e diretrizes conceituais de `_inspirations/`.
- `.agents/context/06_pixellab_mcp_docs.md`: Documentação técnica local das ferramentas e parâmetros do PixelLab MCP (Fonte: `@https://api.pixellab.ai/mcp/docs`).

## 3. Catálogo de Skills (Receitas de Implementação)
Quando solicitado a criar um sistema complexo ou gerar arte, siga o padrão definido em:
- `.agents/skills/build_topdown_character.md`: Criação de personagens Top-Down e máquinas de estado (FSM).
- `.agents/skills/build_inventory_and_items.md`: Criação de itens usáveis, itens de consulta (diários/pistas) e inventário via `Resource`.
- `.agents/skills/build_turn_based_combat.md`: Encontros por turno com opções de Luta/Captura vs. Compreensão/Amizade.
- `.agents/skills/generate_assets_pixellab.md`: Fluxo obrigatório para customizar o personagem base "pelado", criar animações e gerar tilesets via PixelLab MCP.
- `.agents/skills/write_tests.md`: Testes unitários headless via GUT para lógica pura.

## 4. Regras de Ouro de Operação via CLI
1. **PROIBIDO código de Godot 3:** Nunca use `KinematicBody2D`, `yield`, `connect("signal", self, "method")`, ou `TileMap` legado (use `TileMapLayer` da Godot 4.3+).
2. **Tipagem Estática Estrita:** Todas as variáveis, parâmetros e retornos de função devem ter tipo explícito (`: int`, `: float`, `: void`, `: Array[ItemData]`).
3. **Lógica Pura vs. Nós Visuais:** Sistemas de inventário, estado do mundo (afinidade), diálogos e matemática de turno devem herdar de `RefCounted` ou `Resource` sempre que possível, facilitando testes via CLI.
4. **Verificação de Código:** Após criar ou editar scripts `.gd`, valide a sintaxe via terminal (`godot --headless --check-only` ou `gdlint`).
5. **Trava de Direção de Arte e Auto-Fetch do PixelLab:**
   - NUNCA gere sprites ou tilesets no PixelLab sem antes inspecionar `res://assets/art/_templates/`. Todo personagem deve ser uma customização em cima do manequim base (`_templates/character_base/`), todo tileset deve seguir o estilo de `_templates/tileset_base/`, e imagens em `_inspirations/` são apenas referência conceitual (nunca copiadas).
   - Sempre que for usar o PixelLab MCP, consulte primeiro `.agents/context/06_pixellab_mcp_docs.md` ou faça o fetch automático de `@https://api.pixellab.ai/mcp/docs` (via ferramenta de web fetch ou `curl -sL https://api.pixellab.ai/mcp/docs`) sem exigir que o usuário forneça o link no prompt.