# 03_physics_and_layers.md — Física Top-Down, Grid e Camadas

## 1. Configuração de Movimento Top-Down
Diferente de jogos de plataforma, este é um jogo **2D Top-Down**:
- **Gravidade:** `0.0` (desativada em todas as entidades).
- **`CharacterBody2D.motion_mode`:** Sempre definido como `CharacterBody2D.MOTION_MODE_FLOATING`. Isso evita cálculos de chão/parede/rampa de side-scrollers e garante deslizamento suave em colisão diagonal.

## 2. Proporções Pixel Art e Y-Sorting (Profundidade)
- **Tileset / Cenário:** Grid de `32x32` px (usando nós `TileMapLayer` da Godot 4.3+).
- **Personagens:** Sprites de `32x64` px (1 tile de largura por 2 tiles de altura).
- **Regra de Pivô e Colisão (CRÍTICO para Y-Sort):**
  - Todo nó de cenário e personagem deve estar dentro de um container com `y_sort_enabled = true`.
  - No `Sprite2D` ou `AnimatedSprite2D` do personagem (`32x64`), o `offset.y` deve ser `-32` (ou o pivô posicionado na base dos pés do personagem).
  - O `CollisionShape2D` físico do personagem deve cobrir **apenas a metade inferior (os pés)**, com tamanho aproximado de `24x16` px ou `28x20` px. Isso permite que a cabeça do personagem sobreponha paredes norte e árvores naturalmente.

## 3. Matriz de Camadas de Física (Collision Layers & Masks)

| Layer # | Nome da Camada | Uso Principal |
| :--- | :--- | :--- |
| **1** | `World_Environment` | Paredes, árvores, rios, obstáculos físicos do `TileMapLayer`. |
| **2** | `Player` | Corpo físico do Jogador (`CharacterBody2D`). |
| **3** | `NPCs_Entities` | Corpos físicos de NPCs, Entidades Folclóricas e Caçadores. |
| **4** | `Interactables` | Áreas de interação (`Area2D`): pistas, itens no chão, portas, esconderijos. |
| **5** | `Stealth_LineOfSight` | Cones de visão de Caçadores/Mula e áreas de detecção sonora (pegadas falsas). |
| **6** | `Combat_Box` | Projetéis e esquivas no minigame de defesa do combate por turnos (estilo *Undertale*). |

### Regras de Masking Comuns:
- **Player (`CharacterBody2D`):** `collision_layer = 2`, `collision_mask = 1 | 3` (colide com mundo e NPCs).
- **Detector de Interação do Player (`Area2D`):** `collision_layer = 0`, `collision_mask = 4` (detecta apenas objetos interagíveis na direção em que o player olha).
- **RayCast2D de Visão do Caçador/Mula:** `collision_mask = 1 | 2` (enxerga o player, mas a visão é bloqueada por paredes/árvores na Layer 1).