# 05_art_direction.md — Direção de Arte, Templates Base Modulares e Referências

## 1. Princípio Central: Coerência Visual Estrita
Nenhum asset visual pode ser gerado do zero sem referência. Todo novo asset DEVE derivar das métricas, paleta, traço e proporções contidas em `res://assets/art/_templates/`.

## 2. Anatomia do Template Modular (`res://assets/art/_templates/character_base/body/`)
O manequim base (`32x64`) é **modular (Paper Doll)**, dividido em 5 partes anatômicas:
- `head/`, `chest/`, `legs/` (Animações: `Idle`, `Walk`, `Run`)
- `arm_L/`, `arm_R/` (Animações: `Idle`, `Walk`, `Run`, `Holding_Idle`, `Holding_Run`)
- **Direções nos arquivos:** `_Down.png` (Sul), `_Top.png` (Norte) e `_Side.png` (Leste/Oeste — espelhado via `flip_h` no código).

### Como o Agente deve criar Personagens:
1. **Para o Player e NPCs Humanos (Sistema Paper Doll):**
   - Preserve a divisão ou gere spritesheets sobrepostas às partes (`head`, `chest`, `legs`, `arm_L`, `arm_R`).
   - Aproveite os estados `Holding_Idle` e `Holding_Run` dos braços quando o Player estiver segurando itens (ex: *Peneira*, *Brasa do Boitatá*, *Espelho da Cuca*).
2. **Para Entidades Folclóricas (Saci, Curupira, Caipora, Cuca):**
   - O agente deve combinar visualmente as camadas (`legs + chest + head + arms`) de uma direção (ex: `Idle_Down.png`) em um único sprite composto temporário para servir de `init_image`/referência de escala no PixelLab, gerando a entidade já unificada em `res://assets/art/characters/folklore/`.

## 3. Anatomia do Tileset Base (`res://assets/art/_templates/tileset_base/`)
A referência de mundo (`32x32`) está organizada em:
- `Buildings/Light_Woody/` e `Buildings/White/` (`Props.png`, `Roof.png`, `Structure.png`)
- `Environment/Props/` (`Crops.png`, `Props_Forest.png`)
- `Environment/Tiles/Tiles.png`
- `Environment/Trees/` (`Tree_01.png`, `Tree_02.png`, `Tree_03.png`)
Qualquer novo tile ou prop gerado pelo PixelLab deve inspecionar esses arquivos antes para manter exatamente o mesmo estilo de vegetação, telhados, estruturas e terreno.

## 4. Política Estrita de Inspirações (`res://assets/art/_inspirations/`)
- Contém `.gdignore` para não ser importada pela Godot.
- **PROIBIÇÃO DE CÓPIA:** Jamais copiar ou usar imagens de `_inspirations/` diretamente no jogo. Usar apenas para extração conceitual e tradução para o estilo de `_templates/`.