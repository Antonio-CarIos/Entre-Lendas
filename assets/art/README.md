# Organização dos assets de arte

Os PNGs de produção ficam separados pelo tipo de recurso, fase e ambiente. Os originais de referência continuam em `_templates/tileset_base/`.

```text
props/stage_01/
  house/       # Atlas de móveis e decoração da casa
  street/      # Banco, bonde, quitanda, frutas, bambus, muro e decoração colonial
  forest/      # Vegetação, cultivos, árvores e pedras
tilesets/stage_01/
  house/       # Estrutura da casa e escada
  street/      # Pavimento, trilhos, fachadas e telhados coloniais
  forest/      # Grama, terra, pedras de piso e pegadas
```

## Arquivos organizados

| Arquivo anteriormente solto em `tilesets/stage_01/` | Caminho atual relativo a `assets/art/` |
| --- | --- |
| `house_interior_struture.png` | `tilesets/stage_01/house/house_interior_structure.png` |
| `Stairs.png` | `tilesets/stage_01/house/stairs.png` |
| `santa_teresa_street.png` | `tilesets/stage_01/street/santa_teresa_street.png` |
| `tram_tracks.png` | `tilesets/stage_01/street/tram_tracks.png` |
| `Tiles.png` | `tilesets/stage_01/forest/forest_terrain.png` |
| `saci_footprints.png` | `tilesets/stage_01/forest/saci_footprints.png` |
| `Crops.png` | `props/stage_01/forest/crops_atlas.png` |
| `Props_Forest.png` | `props/stage_01/forest/forest_props_atlas.png` |
| `Tree_01.png` | `props/stage_01/forest/tree_01.png` |
| `Tree_02.png` | `props/stage_01/forest/tree_02.png` |

Os PNGs foram movidos sem alterar seus pixels. Os arquivos `.import` existentes acompanharam as imagens, preservando os UIDs e as configurações de importação; as referências das cenas foram atualizadas.

Os cinco arquivos de floresta copiados têm o mesmo conteúdo dos respectivos originais em `_templates/tileset_base/Environment/`. As cenas usam as cópias de produção organizadas acima. O quintal também reutiliza o atlas de móveis da casa e o banco de `street/` por referência.

O pacote base é de **Anokolisa**. Os termos de uso originais estão em `_templates/tileset_base/_source/world_build/Terms.txt`.

Para o mapa de Santa Teresa, `Buildings/White/Structure.png`, `Roof.png` e `Props.png` foram copiados, sem alteração dos pixels, para `tilesets/stage_01/street/colonial_structure.png`, `colonial_roofs.png` e `props/stage_01/street/colonial_props_atlas.png`. Os templates permanecem intactos. As cópias têm seus próprios metadados de importação; as fachadas recebem variações de cor nas cenas. Os recortes não geram novos PNGs.

O redesenho baseado no concept também utiliza `tilesets/stage_01/street/colonial_roofs_brown.png`, cópia intacta de `Buildings/Light_Woody/Roof.png`. Essa variante marrom já estava disponível no pacote base; não é uma recoloração ou arte gerada. A variante verde continua disponível na pasta de produção.

O mapa baseado em `concept_street.jpg` também usa os PNGs de balcão, frutas, bambuzal e muro enviados, além de `characters/npcs/quitandeira/idle/down.png`. Os SVGs `concept_sidewalk.svg`, `concept_curbs.svg` e `street_lamp.svg` são peças modulares com formas alinhadas a pixels e paleta compatível com os templates. Nenhum PNG original foi alterado.

As artes específicas ainda necessárias para os pontos narrativos da cidade estão em [ASSETS_PENDENTES.md](props/stage_01/street/ASSETS_PENDENTES.md).

Para mover recursos em próximas edições, prefira o painel **Sistema de Arquivos** do Godot, que acompanha as referências e os metadados. Os nomes dos arquivos de produção seguem `snake_case`.
