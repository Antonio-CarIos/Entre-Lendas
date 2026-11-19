# Casa e cidade: térreo, quarto, quintal e Santa Teresa

A saída central inferior do térreo agora leva à cidade, com confirmação ao caminhar e retorno pela fachada da casa. A montagem de `santa_teresa_map.tscn`, os controles, os pontos narrativos e os assets ainda necessários estão documentados em [SANTA_TERESA.md](SANTA_TERESA.md).

**Entrada por Novo Jogo:** a Task 2.4 liga o menu à introdução da colega e depois à cidade. Leitura por E/Enter, Esc para pular, spawn/estado sob fade e arte pendente estão em [BOOK_INTRO.md](BOOK_INTRO.md). A introdução também pode ser executada isoladamente com F6.

`house_interior.tscn` mantém o mapa, os TileMapLayers, os móveis e as colisões desenhados no editor. O script coordenador conecta as escadas e as portas. A porta existente da cozinha tem uma área de interação filha; os coletáveis mantêm seus identificadores persistentes.

## Câmera do térreo

A câmera ativa é `YSortRoot/Player/Camera2D`; a câmera antiga na raiz está desativada. Ela acompanha o Player e para nas bordas do piso: atualmente, de **(-32, 224) a (672, 672)**. O componente `components/camera/room_camera.gd` recalcula esses limites a partir do `FloorLayer` ao iniciar a cena, acompanhando futuras alterações do tamanho do mapa.

Na resolução base de 640 × 360, o zoom é 1:1, com enquadramento 16 px acima dos pés e sem atraso de suavização. Se a área visível da janela superar o tamanho do cômodo, o zoom aumenta uniformemente em passos inteiros para manter a tela dentro dos limites, preservando as proporções da pixel art. Ao voltar à resolução base, a escala 1:1 é restaurada. O inventário e os diálogos continuam independentes da câmera.

`OutsideDarkness`, atrás dos tiles, cobre os espaços transparentes do contorno irregular com o mesmo tom escuro do quarto, evitando o fundo cinza do renderizador. Nenhum tile, móvel, colisão ou ponto de chegada foi reposicionado para ajustar o enquadramento. Os limites e o zoom são atualizados antes de revelar a chegada após o fade.

`house_bedroom.tscn` é um mapa editável de **20 × 15 tiles de 32 px (640 × 480 px)**. Usa o mesmo piso e as mesmas paredes de `assets/art/tilesets/stage_01/house/house_interior_structure.png`, com móveis recortados de `house_furniture_atlas.png`:

- `FloorLayer`: piso de madeira.
- `FloorDetailsLayer`: tapete, sem colisão.
- `WallsAndStairsLayer`: paredes, limites do cômodo e escada. O centro da escada é transitável; as laterais têm colisão.
- `YSortRoot/State_Organized`: cama, criado-mudo, armário, espelho, escrivaninha, cadeira, estante, plantas, janela e decoração. Os móveis físicos têm `Sprite2D` e `CollisionShape2D`, Layer 1 e Mask 2. A base dos sprites coincide com a origem dos móveis para Y-Sort.
- `SpawnPoints`, `Transitions` e `GameplayHUD`: chegada, saída e inventário.

## Escadas e fade

| Origem | Gatilho | Direção | Destino / chegada |
| --- | --- | --- | --- |
| Térreo | `Transitions/StairsToBedroom` em `(496, 532)` | Subir | Quarto / `SpawnPoints/FromHouseInterior` em `(496, 328)`, olhando para cima |
| Quarto | `Transitions/StairsToHouseInterior` em `(496, 409)` | Descer | Térreo / `SpawnPoints/FromBedroom` em `(496, 608)`, olhando para baixo |

Não é necessário pressionar E. O Player precisa caminhar na direção da escada e entrar no gatilho. O gatilho do térreo fica antes da colisão existente no topo. Ambos os pontos de chegada ficam fora dos gatilhos, permitindo explorar antes de voltar.

`components/transitions/stair_transition.tscn` detecta apenas o corpo do Player (Mask 2) e emite um sinal para `house_level.gd`. O serviço `core/navigation/scene_transition.gd`, filho persistente de `WorldState`, escurece a tela por 0,28 s, troca a cena sob a tela preta e revela o destino por 0,28 s. A movimentação e a UI ficam bloqueadas durante a travessia; a câmera acompanha o ponto de chegada. Não foi necessário modificar os Autoloads ou as configurações de `project.godot`.

O inventário e o estado moral permanecem em `WorldState`. Cada coletável do térreo tem um `persistent_id`, para continuar removido do mapa ao retornar, inclusive quando foi consumido em uma combinação. Essa persistência é da sessão atual; `WorldState.reset()` inicia um novo jogo e limpa esses registros.

As narrativas da cama, a versão caótica do quarto e o bloqueio por crina descritos no design da fase continuam reservados para as próximas tasks; a ligação atual entre os andares fica disponível para construir e testar os mapas.

## Quintal e porta da cozinha

`house_backyard.tscn` tem uma área jogável de **26 × 21 tiles (832 × 672 px)**, com grama, caminhos de terra, fachada e telhado da casa, barris, árvore, varal, animais, cerca e porteira. A pintura manual dos cinco TileMapLayers permanece intacta.

Todos os recortes de 32 × 32 px dos atlas já usados pelas quatro camadas do quintal estão cadastrados e selecionáveis no editor, inclusive os recortes transparentes. `FloorLayer`, `FloorDetailsLayer` e `GroundEdgesLayer` disponibilizam os 462 recortes do terreno; `WallsAndFenceLayer`, os 620 recortes da estrutura. Essa liberação preserva o desenho do mapa e os polígonos de colisão existentes; novos tiles não recebem colisões automaticamente.

- `FloorLayer`: grama contínua.
- `FloorDetailsLayer`: terra dos caminhos/canteiro e pedras da varanda.
- `GroundEdgesLayer`: recortes nativos de grama que suavizam as bordas da terra.
- `WallsAndFenceLayer`: fachada física da casa.
- `RoofLayer`: telhado e detalhes visuais. Os beirais são elementos acima dos personagens: `z_index = 1`, sem polígonos de colisão nas telhas. O Player pode passar sob as bordas, sendo encoberto por elas. Seu TileSet mantém `Physics Layer 0` habilitada na camada World (Layer 1, Mask Player) para edição, mas as bordas devem permanecer sem colisão; o bloqueio físico corresponde às paredes e à estrutura da casa. `State_Organized/HouseStructure` bloqueia a parte da construção acima da fachada, impedindo atravessar a casa por baixo do telhado.
- `YSortRoot/State_Organized`: props editáveis com nomes próprios, sprites e colisões dos obstáculos. Os postes do varal têm colisão; o espaço entre eles fica livre. A cerca permanece fechada.
- `YSortRoot/SharedProps/WorldBounds`: limites físicos do mapa.

Na cozinha, aproxime-se da porta e pressione **E**, olhando para ela. Aparece **“Deseja sair e ir para o quintal?”**, com **Sim** e **Não**, selecionáveis por teclado. **Sim** realiza o fade e a troca de cena; **Não** ou **Esc** cancelam e restauram a movimentação. **Tab** cancela a pergunta e abre o inventário. No quintal, a porta da fachada pergunta **“Deseja entrar na casa?”** e permite voltar pelo mesmo fluxo.

| Origem | Área de interação | Destino / chegada |
| --- | --- | --- |
| Cozinha | `YSortRoot/State_Organized/Door/BackyardDoor`, centro em `(36, 344)` | Quintal / `SpawnPoints/FromHouseInterior`, `(140, 320)`, olhando para cima, diante da porta |
| Quintal | `YSortRoot/State_Organized/KitchenDoor/ReturnToHouse`, centro em `(140, 284)` | Térreo / `SpawnPoints/FromBackyard`, `(36, 392)`, olhando para baixo |

Ao iniciar o quintal com **F6**, `house_level.gd` usa o marcador indicado em `initial_spawn_path`: `SpawnPoints/PlayerEntrySpawn`, também em `(140, 320)`, olhando para cima. A chegada fica livre de colisões e já ao alcance da porta com **E**; não ocorre troca automática de cena. O spawn de entrada pela casa é `FromHouseInterior`. Ao mover a porta, ajuste os dois marcadores e seu metadado `facing_direction`; a posição inicial usada em F6 vem do marcador, mesmo se o nó Player não tiver sido reposicionado no editor.

A origem de `State_Organized/KitchenDoor` está na soleira, em `(140, 288)`, e seu sprite, colisor e área de interação ficam alinhados. Os postes do varal estão em `(84, 542)` e `(340, 542)`, com colisores na base; a área sob a corda permanece transitável. `Tree` tem colisão somente no tronco, permitindo passar sob a copa. `WoodenBarrel` e `WoodenBarrelV2` ficam em `State_Organized`, com pivôs e colisores na base. Esses ajustes mantêm as posições visuais dos sprites e retiram os bloqueios que antes ficaram em áreas vazias.

`components/interactables/scene_door.tscn` usa a mesma camada dos coletáveis (valor de bits **4**, detectado pela Mask 4 do Player). É uma área sem colisão física. `GameplayHUD` emite o pedido de viagem após a confirmação, e `house_level.gd` aciona o serviço de fade existente. O inventário e os registros de coleta permanecem durante a ida e a volta.

Os puzzles do varal e da porteira, suas falas e a coleta narrativa pertencem às próximas tasks da Sprint 02.

### Animais e profundidade do quintal

`YSortRoot/Horse` instancia `entities/npcs/animals/horse.tscn` em `(744, 600)`, no canto inferior direito, com cinco frames de alimentação em loop a 8 FPS. O cavalo permanece parado; `SpawnPoints/HorseSpawn` marca sua posição, já ocupada pelo animal.

`YSortRoot/Chicken` e `Chicken2` instanciam `entities/npcs/animals/chicken.tscn` em `(408, 492)` e `(480, 552)`. Cada galinha caminha de 8 a 16 px por vez a 9 px/s, sempre a até 24 px da posição inicial, e para para comer antes de voltar a caminhar. Os ritmos são diferentes. Os parâmetros ficam expostos no Inspector de cada instância; mover uma galinha no editor muda o centro do seu passeio. A caminhada usa as animações `walk_down`, `walk_up`, `walk_left` e `walk_right`, com oito frames por direção em loop a 8 FPS. Os frames de 36 × 36 e 40 × 40 são recortados por `AtlasTexture` para 32 × 32, alinhados aos pés, sem alterar os PNGs; o balanço provisório foi removido. Os sete frames de alimentação norte/sul usam recortes de 32 × 32, alinhados às poses paradas sem modificar os PNGs.

Os animais têm colisores somente nos pés e usam as camadas World e NPCs (bits `5`), permitindo colisão com a máscara World já usada pelo Player. As galinhas também detectam o Player e os obstáculos e param para comer quando encontram uma colisão.

As camadas de chão têm `z_index = -2`; as cercas e a porteira, `-1`; a fachada, a árvore e os personagens permanecem em `0`; o telhado usa `1`, acima dos personagens. Os tiles de sombra do atlas (`4:7` e `5:7`) têm `z_index = 1` adicional, resultando em profundidade `2`: a sombra é desenhada sobre o Player e conserva a transparência original do PNG, sem colisão. Assim, casa e árvore cobrem as cercas, e os objetos em `YSortRoot` continuam ordenados pelos pés. A origem de `State_Organized/Tree` fica na base do tronco; seus sprites mantêm exatamente as posições visuais anteriores. A pintura dos cinco TileMapLayers e seus atlas foram preservados; os colisores foram alinhados à montagem atual.

Os tiles e props usados estão nas pastas de produção `house/`, `street/` e `forest/`, conforme `assets/art/README.md`. Para editar ou testar o quintal diretamente, abra sua cena no Godot e pressione **F6**. Ao reposicionar uma porta, ajuste também seu ponto de chegada no mapa correspondente.

## Validação

A auditoria parcial da Task 2.9, com entidade reutilizável e catálogo de arte por Task, está em [ART_REQUIREMENTS.md](ART_REQUIREMENTS.md). Abra `saci_visual_preview.tscn` com F6 para conferir os frames reais de redemoinho; a forma de uma perna continua ausente. A prévia não altera os mapas nem o progresso narrativo.

A preparação isolada da conversa da Cena 4 e seu contrato de entrega à Cena 5 estão em [SACI_CONVERSATION.md](SACI_CONVERSATION.md). Ainda não está conectada à garrafa nem ao mapa: falta identificar os novos assets de uma perna, validar o marcador e integrar os efeitos de abertura/saída. As Tasks 2.9 e 2.10 continuam abertas.

A Cena 3 agora usa `HouseInvestigation` no térreo/quarto. Inspeções, memória do cachimbo e escolhas da garrafa estão descritas em [HOUSE_INVESTIGATION.md](HOUSE_INVESTIGATION.md). Os pickups mecânicos antigos ficam exclusivamente em `tests/fixtures/inventory_mechanics_lab.tscn`; não devem ser recolocados no mapa final para testar inventário. A Task 2.10 encenará o Saci após a abertura e a Task 2.12 validará o marcador de despertar reservado, que ainda está dentro de uma parede.

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

`tests/test_house_navigation.gd` verifica os recortes do atlas, os materiais compartilhados, o padrão dos móveis, os limites do mapa e os caminhos até os móveis usando a colisão real dos pés do Player. Também executa a ida e a volta pelo gatilho de física, conferindo a tela preta na troca, o bloqueio da movimentação/UI, os pontos de chegada, a ausência de transições repetidas e a persistência dos coletáveis já combinados.

`tests/test_backyard_navigation.gd` verifica os recortes e as camadas do quintal, a circulação até os pontos principais com o tamanho real dos pés do Player, o alcance da porta da cozinha e os fluxos Sim/Não/Esc/Tab. Também executa a ida e a volta por input real e verifica a persistência do inventário e dos coletáveis.

`tests/test_backyard_animals.gd` verifica a profundidade das cercas, a posição e o loop do cavalo, os frames das duas galinhas, a alternância de atividades, o raio dos passeios e a colisão com obstáculos.

`tests/test_house_camera.gd` verifica a câmera ativa, os limites calculados pelo piso, o enquadramento real nas bordas e nos pontos de chegada, o fundo escuro e o redimensionamento em formatos horizontal, ultrawide e vertical.
