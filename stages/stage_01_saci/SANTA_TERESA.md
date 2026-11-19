# Santa Teresa — composição do concept_street

**Task 2.7:** a primeira chegada narrativa está ligada ao mapa: narração/tutorial únicos, objetivo, bonde, placa, janela e porta Sim/Ainda não com entrada na casa organizada. Controles, posições, retorno, preservação do mapa e pendência da gravação da risadinha: [CITY_ARRIVAL.md](CITY_ARRIVAL.md). F6 conserva a edição sem iniciar o roteiro; F5 percorre o fluxo do menu.

Abra `santa_teresa_map.tscn` e pressione **F6**. A cena principal de `project.godot`, o térreo, o quarto e o quintal permanecem intactos.

## Composição e escala

A referência ativa é [concept_street.jpg](../../assets/art/_inspirations/concepts_folklore/concept_street.jpg). A cidade foi reconstruída em **1024 × 576 px**, uma área de **32 × 18 tiles de 32 px**, acompanhando a proporção horizontal e a distribuição desse novo concept. Essa composição substitui a montagem anterior de 1920 × 2240; as coordenadas antigas do roteiro da Sprint 02 precisam ser adaptadas aos marcadores atuais.

A praça ocupa o centro, com duas árvores e banco; o bonde fica à esquerda; o muro fica acima da casa principal, à direita; a quitanda ocupa o canto inferior esquerdo e o bambuzal, o inferior direito. Casas nas bordas superior e inferior completam o enquadramento. Os telhados marrons existentes recebem modulação quente na cena, sem modificar os PNGs. As ruas, calçadas, meio-fio, fachadas e telhados são editáveis; não há geração do mapa em runtime.

- `FloorLayer`: calçada contínua, também responsável pelos limites da câmera.
- `FloorDetailsLayer`: ruas pavimentadas em pedra e ramais ao norte e ao sul.
- `SidewalkLayer`: disponível para acrescentar detalhes às calçadas.
- `StreetEdgesLayer`: meio-fio nas bordas do pavimento.
- `GardenDetailsLayer` e `GardenEdgesLayer`: praça, jardins e terreno do bambuzal.
- `TramTracksLayer` e `SteelRails`: trilhos sob o bonde, com linhas de aço contínuas.
- `YSortRoot/SharedProps`: casas, árvores, banco, bonde, muro, postes, quitanda e bambuzal. Os corpos físicos ficam na Layer World, com colisores alinhados às bases.
- `SpawnPoints`: chegada inicial e retorno da casa.
- `PointsOfInterest`: posições atuais das futuras interações narrativas.
- `Transitions/EnterHouse`: confirmação de entrada na casa.
- `GameplayHUD`: inventário e diálogos existentes, operados pelo teclado.

As fachadas usam grade 32 × 32; os telhados modulares preservam os recortes nativos de 16 × 16. A câmera acompanha o Player, com limites de 1024 × 576, escala uniforme e filtro Nearest. A colisão de perímetro impede sair da área desenhada. O portão que lembrava degraus e as muretas diante da casa foram removidos, incluindo suas colisões: a calçada diante da entrada agora fica livre. A fachada continua sólida; os canteiros e a praça continuam transitáveis, bloqueando apenas troncos, banco e demais obstáculos.

Cada casa tem acabamento em `FacadeDetails`: pilastras, cornija, sombra sob o beiral, rodapé e molduras das portas e janelas. As cores variam entre tons de ocre, creme e verde suave. A porta principal fica visualmente entreaberta; a soleira fica dentro da fachada e não acrescenta obstáculos à calçada. Esses detalhes são nós editáveis, sem scripts de geração em runtime.

## Entrar e sair de casa

A saída inferior do térreo continua perguntando **“Deseja sair e ir para a cidade?”**. Confirmar usa o fade e leva a `SpawnPoints/FromHouseInterior`, em **(856, 368)**, diante da porta da casa principal, olhando para baixo. A chegada fica fora do gatilho.

Na primeira chegada narrativa, aproximar-se da porta apresenta a descrição da porta entreaberta e **Sim/Ainda não**; o diálogo tem prioridade sobre Tab. Sim apresenta cheiro de fumo/madeira e entra na casa organizada, avançando a fase sob fade. Em F6 e visitas posteriores, a porta usa **“Deseja entrar na casa?”**: E/Enter confirma, Esc cancela e Tab cancela para abrir o inventário. A confirmação retorna ao marcador `FromCity` do térreo, em **(320, 624)**, olhando para cima. Inventário, decisões e coletáveis persistem durante a viagem.

Iniciar com F6 usa `PlayerEntrySpawn`, em **(512, 448)**, olhando para cima. Ao editar a localização da casa, ajuste o gatilho, o marcador de retorno e o ponto de interesse correspondente.

## Quitandeira e interação por E

`YSortRoot/SharedProps/Quitanda/Quitandeira` instancia [quitandeira.tscn](../../entities/npcs/quitandeira/quitandeira.tscn). A NPC permanece parada em **(144, 528)**, com `idle_down`, atrás do balcão em **(144, 536)**. O recorte do PNG original mantém proporção de 32 × 64 e pivô nos pés. O balcão encobre a parte inferior da NPC, mantendo o rosto visível abaixo do toldo.

Caminhe pela rua ao lado da loja e aproxime-se pela frente, na calçada em **(144, 560)**. Olhe para cima e pressione **E** para conversar. O HUD mostra a fala, pausa o movimento e o restaura ao fechar por **E/Enter/Esc**. A conversa pode ser repetida. As caixas de frutas e o balcão usam os PNGs fornecidos.

O toldo tem cobertura, costuras e babado sombreado separados, além de placa com a fonte pixel do projeto. Os pilares de madeira possuem colisão apenas na base, nas extremidades da loja. O fundo tem prateleira e sombra; as frutas decoram o balcão e as caixas laterais ficam em (79, 542) e (211, 542), preservando o acesso central à quitandeira.

`components/interactables/dialogue_interactable.gd` conserva `speaker/message`, aceita catálogo/entrada narrativos e emite `interacted` para apresentação cosmética. O Player emite o pedido e o HUD apresenta a conversa; a NPC não depende diretamente da UI. Na Cena 2, orienta para a porta entreaberta. A entrega condicional da peneira e as flags de investigação continuam pertencendo às tasks narrativas da Sprint 02.

## Pontos atuais

| Local | Coordenada |
| --- | --- |
| Início / F6 | (512, 448) |
| Porta da casa | (856, 336) |
| Chegada da casa | (856, 368) |
| Banco da praça | (512, 384) |
| Muro | (800, 160) |
| Bonde | (176, 304) |
| Balcão da quitanda | (144, 536) |
| Quitandeira | (144, 528) |
| Passagem no bambuzal | (880, 544) |
| Saída norte reservada à continuação | (512, 32) |

O marcador `WhirlwindBossSpawn` fica fora deste enquadramento, em (512, -96), como referência para uma futura continuação pela rua norte. Não há ladeira, terraço ou batalha implementados nesta composição. Varal, cavalo e porteira continuam no quintal.

## Assets e diferenças restantes da referência

Os PNGs de produção e os templates não foram alterados. Calçada, meio-fio e postes usam SVGs modulares com formas alinhadas a pixels e paleta dos assets. O toldo listrado usa polígonos de pixel art editáveis na cena.

Não foram localizados os seis grafites do concept: `MuralWall/Panel01` a `Panel06` são marcadores de encaixe, e o muro usa o PNG de reboco enviado. Também há diferenças entre os PNGs disponíveis e a referência nas telhas, nas copas das árvores e no bonde. A composição foi reproduzida com os recursos existentes; não é uma cópia pixel a pixel da ilustração. Os refinamentos necessários estão em [ASSETS_PENDENTES.md](../../assets/art/props/stage_01/street/ASSETS_PENDENTES.md).

## Validação

`tests/test_city_navigation.gd` verifica recortes e camadas, o layout atual, iluminação, câmera, caminhos reais até todos os pontos com a colisão do Player, ausência de bloqueios invisíveis na antiga mureta e no portão, conversa com a quitandeira por input, oclusão pelo balcão, confirmação de saída da casa e ida/volta preservando o estado.

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```
