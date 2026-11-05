# Skill: Criar Personagem 2D Top-Down (32x64) — Modular ou Unificado

Use este guia sempre que precisar criar ou refatorar o Jogador, NPCs ou Entidades Folclóricas.

## 1. Direções e Espelhamento Horizontal (`flip_h`)
Os templates em `res://assets/art/_templates/character_base/body/` possuem 3 arquivos por animação: `Down`, `Top` e `Side`.
- **Sul (`Vector2.DOWN`):** Toca animação `*_down`, `flip_h = false`.
- **Norte (`Vector2.UP`):** Toca animação `*_top`, `flip_h = false`.
- **Direita/Leste (`Vector2.RIGHT`):** Toca animação `*_side`, `flip_h = false` (ou `true` dependendo da direção padrão do sprite Side).
- **Esquerda/Oeste (`Vector2.LEFT`):** Toca animação `*_side`, invertendo o `flip_h`.

## 2. Hierarquia de Nós para o Player Modular (Paper Doll)
Para aproveitar as animações `Holding_Idle` e `Holding_Run` dos braços:
```text
Player (CharacterBody2D) [motion_mode = FLOATING, y_sort_enabled = true]
├── BodyParts (Node2D) [position = Vector2(0, -32)]
│   ├── LegsSprite (AnimatedSprite2D)
│   ├── ChestSprite (AnimatedSprite2D)
│   ├── HeadSprite (AnimatedSprite2D)
│   ├── ArmLSprite (AnimatedSprite2D)
│   └── ArmRSprite (AnimatedSprite2D)
├── FootCollision (CollisionShape2D) [RectangleShape2D: size = Vector2(20, 12), position = Vector2(0, -6)]
├── InteractionPivot (Node2D)
│   └── InteractionArea (Area2D)
└── StateMachine (Node)
```
*(Para entidades folclóricas ou NPCs com spritesheet unificada, substitua `BodyParts` por um único `AnimatedSprite2D` com `offset = Vector2(0, -32)`).*