# 04_engine_guidelines.md — Padrões de Código GDScript 2.0 (Godot 4.x)

## 1. Regras Sintáticas Estritas (Anti-Alucinação Godot 3)
| Proibido (Godot 3) | Obrigatório (Godot 4) |
| :--- | :--- |
| `KinematicBody2D` | `CharacterBody2D` |
| `move_and_slide(velocity)` | `velocity = ...` seguido de `move_and_slide()` (sem argumentos) |
| `export var speed = 100` | `@export var speed: float = 100.0` |
| `onready var sprite = $Sprite` | `@onready var sprite: Sprite2D = $Sprite2D` |
| `yield(get_tree().create_timer(1.0), "timeout")` | `await get_tree().create_timer(1.0).timeout` |
| `obj.connect("sig", self, "_on_sig")` | `obj.sig.connect(_on_sig)` |
| `TileMap` (nó único legado) | `TileMapLayer` (um nó por camada de tile) |
| `AnimatedSprite` | `AnimatedSprite2D` |

## 2. Tipagem e Performance
- **Tipagem Estática Total:** Nunca omita tipos. Use arrays tipados: `var items: Array[ItemData] = []`.
- **Uso de `StringName`:** Para inputs, nomes de animações e grupos, use literais `StringName` prefixados com `&`:
  ```gdscript
  if Input.is_action_just_pressed(&"interact"):
      animated_sprite.play(&"idle_down")
  ```
- **Ordem do Script (Style Guide Oficial):**
  1. `@tool` / `@icon`
  2. `class_name`
  3. `extends`
  4. Documentação (`## Comentário`)
  5. `signal`
  6. `enum`
  7. `const`
  8. `@export` variables
  9. Variáveis públicas e privadas (`_nome`)
  10. `@onready` variables
  11. `_init()`, `_ready()`, `_process()`, `_physics_process()`, `_unhandled_input()`
  12. Métodos públicos e privados

## 3. Configuração de Pixel Art Perfeita
Ao criar cenas via script ou `.tscn`:
- Certifique-se de que `texture_filter` nos nós raiz ou em `project.godot` esteja configurado como `CanvasItem.TEXTURE_FILTER_NEAREST` (sem borrão bilinear).