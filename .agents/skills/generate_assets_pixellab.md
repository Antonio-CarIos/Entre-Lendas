# Skill: Pipeline de Arte e Animação com PixelLab MCP

Use esta skill sempre que o usuário pedir para criar ou animar personagens, gerar tilesets, criar objetos de cenário (props) ou ícones de itens.

## Passo 0: Carregamento Automático da Documentação do PixelLab MCP
O usuário NÃO precisa colar o link da documentação no prompt. Antes de invocar qualquer tool do servidor `pixellab`, execute automaticamente esta verificação:
1. Leia o arquivo local `.agents/context/06_pixellab_mcp_docs.md`.
2. Caso o arquivo não exista, esteja desatualizado ou vazio, busque a documentação oficial em tempo real:
   - Se você suportar URL context fetching nativo, carregue: `@https://api.pixellab.ai/mcp/docs`
   - Se você tiver acesso ao bash/terminal, execute:
```bash
curl -sL [https://api.pixellab.ai/mcp/docs](https://api.pixellab.ai/mcp/docs) -o .agents/context/06_pixellab_mcp_docs.md
```
   e leia o arquivo gerado para conhecer todos os parâmetros exatos das tools (`create_character`, `animate_character`, `create_tileset`, `create_map_object`, etc.).

## Passo 1: Inspeção Obrigatória de Templates e Inspirações (Pré-Geração)
Antes de chamar qualquer ferramenta do MCP `pixellab`, você DEVE executar a leitura do diretório de arte:
1. **Verifique os Templates Base:**
   - Se a tarefa for de **Personagem/Animação**, inspecione os arquivos em `res://assets/art/_templates/character_base/` para confirmar dimensões exatas do canvas, layout da spritesheet, número de frames por direção e estilo de linha/sombra.
   - Se a tarefa for de **Cenário/Tileset/Prop**, inspecione os arquivos em `res://assets/art/_templates/tileset_base/` para confirmar a escala `32x32` e a paleta de cores.
2. **Consulte as Inspirações (Opcional / Conceitual):**
   - Verifique se há referências na pasta `res://assets/art/_inspirations/` relacionadas ao pedido.
   - Analise a imagem apenas para extrair descrições semânticas (cores temáticas, vestimentas folclóricas, atmosfera). **NUNCA** passe uma imagem de `_inspirations/` como template de cópia direta e **NUNCA** mova arquivos de `_inspirations/` para as pastas de produção.

## Passo 2: Execução no PixelLab MCP por Tipo de Asset

### Caso A: Criar Novo Personagem (Customização do Boneco Base `32x64`)
1. Carregue o sprite base "pelado" de `res://assets/art/_templates/character_base/` como referência estrutural/estilo (`init_image` ou referência de pose/proporção suportada pela ferramenta do PixelLab conforme `06_pixellab_mcp_docs.md`).
2. Descreva no prompt apenas a **customização sobre a base**: roupas, tom de pele, cabelo e acessórios folclóricos (ex: *"sobre a base 32x64, adicionar calça rasgada, gorro vermelho, cachimbo, mantendo a mesma postura e proporção de cabeça"*).
3. Gere as 4 direções (Sul, Norte, Leste, Oeste) e replique as animações base (Idle, Walk) mantendo exatamente o mesmo grid de frames do template original.
4. Salve em `res://assets/art/characters/<categoria>/<nome_entidade>/`.

### Caso B: Criar Nova Animação para Personagem Existente
1. Use o sprite já finalizado do personagem (ou a pose equivalente de `_templates/character_base/`) como frame base na ferramenta de animação do PixelLab.
2. Mantenha o tamanho do frame em `32x64` px e o pivô alinhado aos pés (`offset.y = -32`).
3. Exporte a spritesheet no mesmo padrão de colunas/linhas das animações nativas do template.

### Caso C: Criar Novo Tileset ou Expansão de Mapa (`32x32`)
1. Utilize o arquivo de `res://assets/art/_templates/tileset_base/` como referência de estilo (`style_image` / paleta) na ferramenta de tileset do PixelLab.
2. Especifique tamanho de tile estrito de `32x32` px e perspectiva Top-Down.
3. Garanta continuidade de bordas (Wang tiles / Autotile) compatível com o `TileMapLayer` da Godot 4.
4. Salve em `res://assets/art/tilesets/`.

### Caso D: Ícones de Inventário e Diário (`32x32`)
1. Gere ícones isolados em canvas `32x32` px com fundo transparente, seguindo a paleta e espessura de contorno de `_templates/`.
2. Salve em `res://assets/art/items/`.

## Passo 3: Pós-Processamento e Validação na Godot 4
1. Confirme se as dimensões em pixels do arquivo PNG gerado batem exatamente com os múltiplos de `32x32` ou `32x64` do template.
2. Ao vincular a textura em um `.tscn` ou `.tres` (`SpriteFrames` ou `TileSet`), garanta que os recortes (`AtlasTexture.region`) correspondam ao grid do `_templates/character_base/`.