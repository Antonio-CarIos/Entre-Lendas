# 02_architecture.md — Arquitetura de Software (Godot 4 Top-Down RPG)

## 1. Estrutura de Diretórios (`res://`)
Mantenha a organização modular por domínio e separe claramente templates/inspirações de assets de produção:
```text
res://
├── addons/
│   └── gut/                        # Framework de testes unitários via CLI
├── assets/
│   ├── art/
│   │   ├── _templates/             # [FONTE DA VERDADE] Templates base imutáveis
│   │   │   ├── character_base/     # Manequim "pelado" 32x64 e animações base
│   │   │   └── tileset_base/       # Tileset padrão 32x32 de referência de estilo
│   │   ├── _inspirations/          # [CONCEITO] Moodboards (contém .gdignore)
│   │   │   ├── .gdignore
│   │   │   ├── concepts_folklore/
│   │   │   └── moodboards_scenarios/
│   │   ├── characters/             # Spritesheets 32x64 customizadas prontas para uso
│   │   ├── tilesets/               # Tilesets 32x32 de produção
│   │   ├── props/                  # Objetos interagíveis e decoração de cenário
│   │   ├── items/                  # Ícones 32x32 para inventário e diário
│   │   └── ui/                     # Elementos de interface
│   ├── audio/                      # BGM e SFX separados por fase
│   └── fonts/                      # Fontes pixel art
├── core/
│   ├── autoloads/                  # Singletons globais (EventBus, WorldState, etc.)
│   ├── combat/                     # Sistema de batalha por turnos (Undertale/Omori style)
│   ├── dialogue/                   # Parser de diálogos ramificados e escolhas
│   ├── inventory/                  # Lógica de inventário e classes Resource de Itens
│   └── state_machine/              # Classes base de FSM (StateMachine, State)
├── entities/
│   ├── player/                     # Cena e scripts do Jogador (32x64)
│   ├── folklore/                   # Saci, Mula, Curupira, Caipora, Boitatá, Cuca
│   └── npcs/                       # Moradores, Caçadores, Animais
├── components/                     # Hitbox, Hurtbox, InteractionArea, StealthDetector
├── stages/                         # As 4 fases da antologia
│   ├── stage_01_saci/
│   ├── stage_02_mula/
│   ├── stage_03_guardians/
│   └── stage_04_cuca/
├── ui/                             # HUD, Menu de Inventário, Diário (Journal), Caixa de Diálogo
└── tests/                          # Testes GUT (unitários de lógica pura)
```

## 2. Autoloads (Singletons Globais)
Minimize o estado global, restringindo-o a 4 Autoloads essenciais:
1. **`EventBus` (`event_bus.gd`):** Barramento de sinais globais para desacoplar UI, Diálogo e Mundo (ex: `signal item_collected(item: ItemData)`, `signal affinity_changed(new_score: int)`).
2. **`WorldState` (`world_state.gd`):** Armazena a matriz de escolhas morais (`CAPTURE` vs `FRIENDSHIP` para cada lenda), o índice de equilíbrio da natureza (`nature_balance: int`) e flags de investigação do diário.
3. **`InventoryManager` (`inventory_manager.gd`):** Instancia e gerencia os itens usáveis e os registros do Diário de Consulta.
4. **`AudioManager` (`audio_manager.gd`):** Gerencia crossfades de BGM (ex: transição Dia -> Noite na Fase 2) e canais de SFX.

## 3. Padrões de Projeto Obrigatórios
- **"Signals Up, Call Down":** Nós pais chamam métodos dos filhos diretamente. Nós filhos NUNCA usam `get_parent().metodo()`; eles emitem sinais (`signal`) que o pai escuta.
- **Data-Driven com `Resource`:** Itens (`ItemData`), entradas de diário (`JournalEntry`), árvores de diálogo (`DialogueNode`) e status de combate (`CombatStats`) devem herdar de `Resource` (`class_name ... extends Resource`) e ser salvos como arquivos `.tres`.
- **Composição de Nós:** Para adicionar interatividade a qualquer objeto do mapa (uma pista no chão, um NPC, uma gaiola de animal), adicione um componente filho `InteractableComponent` (`Area2D`) em vez de duplicar código de detecção.
- **Reuso de `SpriteFrames` / Layout de Animação:** Como todos os personagens humanoides derivam de `res://assets/art/_templates/character_base/`, suas spritesheets finais em `res://assets/art/characters/` mantêm a mesma grade de colunas/linhas, permitindo duplicar ou instanciar o `SpriteFrames` base trocando apenas a textura atlas.