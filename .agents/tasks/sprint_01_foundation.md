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

- [ ] **Task 1.3: Player Top-Down (`32x64`) e Interação**
  - Criar cena `res://entities/player/player.tscn` com `CharacterBody2D` (`MOTION_MODE_FLOATING`).
  - Configurar `AnimatedSprite2D` (`32x64`) usando o manequim base de `res://assets/art/_templates/character_base/` com pivô nos pés (`offset.y = -32`) e `CollisionShape2D` na metade inferior.
  - Implementar `InteractionArea` (`Area2D`) que rotaciona ou se desloca conforme a direção (`facing_direction`) do jogador.

- [ ] **Task 1.4: Sistema de Inventário e Diário (`Resource`)**
  - Implementar `ItemData` (`Resource`) e `InventorySystem` (`RefCounted`).
  - Criar os arquivos `.tres` dos 8 itens especiais do GDD em `res://core/inventory/items/` (Gorro do Saci, Ferradura da Mula, Assobio da Caipora, Pegada Falsa, Brasa do Boitatá, Espelho da Cuca, Ervas da Cuca, Amuleto de Proteção).