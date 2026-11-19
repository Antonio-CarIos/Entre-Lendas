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

- [x] **Task 1.3: Player Top-Down (`32x64`), Animações, Interação e Teste em `house_interior.tscn`**
- Criar cena `res://entities/player/player.tscn` com `CharacterBody2D` (`MOTION_MODE_FLOATING`) e script `res://entities/player/player.gd` com tipagem estática.
- Configurar `AnimatedSprite2D` (`SpriteFrames`) carregando os frames PNG individuais das subpastas de `res://assets/art/characters/player/` para as 4 direções (`idle_down`, `idle_up`, `idle_left`, `idle_right`, `walk_down`, `walk_up`, `walk_left`, `walk_right` a 8 FPS), ajustando o `offset` para que o pivô `(0, 0)` do `Player` fique alinhado aos pés (garantindo Y-Sort correto) e `CollisionShape2D` na base inferior (Layer 2: Player, Mask 1: World).
- Adicionar `Camera2D` habilitada como filha do `Player` e `InteractionArea` (`Area2D` na Mask 3: Interactables) que atualiza sua posição conforme `facing_direction`.
- Instanciar `player.tscn` dentro do nó `YSortRoot` da cena `res://stages/stage_01_saci/house_interior.tscn` sem sobrescrever os tiles e móveis já posicionados no editor, permitindo testar imediatamente a movimentação e as colisões no térreo da casa.
- Escrever teste unitário GUT em `res://tests/test_player.gd` validando movimentação, atualização de `facing_direction`, troca entre animações `idle`/`walk` e posicionamento da `InteractionArea`.

- [x] **Task 1.4: Sistema de Inventário (`Resource`), Coletáveis com Brilho no Mapa e Protótipo de UI/Coleta**
- Garantir no `project.godot` que a ação `interact` está mapeada para a tecla `E` (`KEY_E`) e `open_inventory` para a tecla `Tab` (`KEY_TAB`).
- Implementar `ItemData` (`Resource` em `res://core/inventory/item_data.gd`) e `InventorySystem` (`RefCounted` em `res://core/inventory/inventory_system.gd`, com instância acessível via `WorldState` ou Autoload iniciando vazia).
- Inspecionar os sprites estáticos em `res://assets/art/items/stage_01/` e criar os arquivos `.tres` correspondentes em `res://core/inventory/items/stage_01/`, vinculando a textura PNG limpa na propriedade `icon` para exibição estática sem brilho no Inventário.
- Criar o shader `res://assets/shaders/collectible_shine.gdshader` (`canvas_item`) e a cena `res://components/interactables/collectible_item.tscn` (`Area2D` na Layer 3: Interactables) que exibe `item_data.icon` no mapa com reflexo de brilho periódico para indicar que é interagível, mantendo o recurso `item_data.icon` puro para os slots da UI.
- Criar a cena de interface `res://ui/gameplay_hud.tscn` (`CanvasLayer`) utilizando as folhas de UI em `res://assets/art/ui/` (`ui_sheet_dialog_and_buttons.png` e `ui_sheet_inventory_diary.png`):
  - **Caixa de Confirmação (`E`):** Ao interagir com um `CollectibleItem` no mapa usando `E` (`interact`), abre a caixa perguntando *"Deseja pegar o item [Nome do Item]?"* com escolhas `[Sim]` e `[Não]`.
  - **Caixa de Aviso Pós-Coleta:** Ao confirmar `[Sim]`, adiciona o item ao inventário, remove o item do mapa (`queue_free()`) e exibe a mensagem *"Você coletou o item [Nome do Item]! Clique no botão TAB para abrir o invent