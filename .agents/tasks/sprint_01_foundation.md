# Sprint 01 — Fundação Top-Down, Mundo Reativo e Inventário

- [x] **Task 1.1: Configuração do Projeto (`project.godot`)**
- Configurar janela base (ex: `640x360` com stretch mode `canvas_items` e aspect `keep` para pixel art 32x32).
- Definir `default_texture_filter` para `Nearest` (0).
- Configurar Input Map: `move_up`, `move_down`, `move_left`, `move_right`, `interact`, `stealth`, `open_inventory`.
- Nomear as 6 Collision Layers de 2D Physics conforme `03_physics_and_layers.md`.

- [x] **Task 1.2: Autoloads Core (`WorldState` e `EventBus`)**
- Criar `res://core/autoloads/event_bus.gd`.
- Criar `res://core/autoloads/world_state.gd` contendo o registro de decisões (`CAPTURE` vs `FRIENDSHIP`), o contador `nature_balance` e sinais de mudança de estado do mundo.
- Escrever teste unitário para `WorldState` em `res://tests/test_world_state.gd`.

- [ ] **Task 1.3: Player Top-Down (`32x64`), Animações, Interação e Teste em `house_interior.tscn`**
- Criar cena `res://entities/player/player.tscn` com `CharacterBody2D` (`MOTION_MODE_FLOATING`) e script `res://entities/player/player.gd` com tipagem estática.
- Configurar `AnimatedSprite2D` (`SpriteFrames`) carregando os frames PNG individuais das subpastas de `res://assets/art/characters/player/` para as 4 direções (`idle_down`, `idle_up`, `idle_left`, `idle_right`, `walk_down`, `walk_up`, `walk_left`, `walk_right` a 8 FPS), ajustando o `offset` para que o pivô `(0, 0)` do `Player` fique alinhado aos pés (garantindo Y-Sort correto) e `CollisionShape2D` na base inferior (Layer 2: Player, Mask 1: World).
- Adicionar `Camera2D` habilitada como filha do `Player` e `InteractionArea` (`Area2D` na Mask 3: Interactables) que atualiza sua posição conforme `facing_direction`.
- Instanciar `player.tscn` dentro do nó `YSortRoot` da cena `res://stages/stage_01_saci/house_interior.tscn` sem sobrescrever os tiles e móveis já posicionados no editor, permitindo testar imediatamente a movimentação e as colisões no térreo da casa.
- Escrever teste unitário GUT em `res://tests/test_player.gd` validando movimentação, atualização de `facing_direction`, troca entre animações `idle`/`walk` e posicionamento da `InteractionArea`.

- [ ] **Task 1.4: Sistema de Inventário e Diário (`Resource`)**
- Implementar `ItemData` (`Resource` em `res://core/inventory/item_data.gd`) e `InventorySystem` (`RefCounted` em `res://core/inventory/inventory_system.gd`).
- Criar os arquivos `.tres` dos 8 itens especiais do GDD em `res://core/inventory/items/` (Gorro do Saci, Ferradura da Mula, Assobio da Caipora, Pegada Falsa, Brasa do Boitatá, Espelho da Cuca, Ervas da Cuca, Amuleto de Proteção).
- Escrever teste unitário GUT em `res://tests/test_inventory_system.gd` validando adição, remoção, consulta de itens e emissão de sinais.