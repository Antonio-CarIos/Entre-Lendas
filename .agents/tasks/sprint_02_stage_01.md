# Sprint 02 — Fase 1 completa: O Saci-Pererê

> Revisão de 19/11/2026. Escopo: entregar a **fase do Saci jogável do menu aos epílogos e créditos**, aproveitando a introdução da colega e os mapas existentes. As Fases 2–4 continuam no backlog geral; esta sprint não implementa a antologia inteira.
>
> Fonte narrativa: `Fase 1 - Saci.odt`, lido integralmente. Referências complementares: `.agents/context/07_stage_01_saci_design.md`, `stages/stage_01_saci/README.md` e `stages/stage_01_saci/SANTA_TERESA.md`. As decisões desta revisão resolvem as divergências indicadas abaixo; orientações mais recentes do usuário prevalecem.

## Como executar esta sprint

- Execute **uma Task por pedido**, respeitando as dependências. Um pedido para revisar o planejamento não autoriza começar todas as implementações.
- Antes de implementar, leia `.agents/AGENTS.md`, `02_architecture.md`, `03_physics_and_layers.md`, `04_engine_guidelines.md`, `07_stage_01_saci_design.md` e as skills pertinentes ao trabalho. Para arte, consulte `05_art_direction.md` e a skill de assets; para combate, `build_turn_based_combat.md`; para testes, `write_tests.md`.
- Preserve a pintura manual, colisões válidas, props, pivôs, Y-Sort, spawns, UIDs e transições existentes. Não reconstrua os mapas para executar tarefas narrativas. Compare o estado antes/depois; o Git contém trabalho local ainda não consolidado.
- Mantenha GDScript 2.0 explicitamente tipado, `TileMapLayer`, lógica pura testável e conteúdo narrativo em Resources. Reutilize `WorldState.inventory`, `SceneTransition`, Player, HUD e componentes existentes; não crie gerenciadores concorrentes.
- Marque `[x]` somente o que foi implementado e validado. A existência de uma cena, sprite ou método não comprova a conclusão narrativa de uma Task. Registre pendências de arte/áudio com caminho e requisito, sem declarar a entrega final concluída com placeholders.
- IDs anteriores foram redistribuídos: antiga 2.1 → 2.2/2.5/2.18; 2.2 → 2.4; 2.3 → 2.8–2.12; 2.4 → 2.7/2.13–2.19; 2.5 → 2.19–2.21. Use os novos títulos ao solicitar trabalho.

## Auditoria da base existente

| Já existe e deve ser aproveitado | Lacuna real |
| --- | --- |
| Player top-down, inventário por teclado, Examinar/Ler/Combinar, receita fita + peneira, seis itens narrativos e duas páginas genéricas `.tres` | Diário de investigação, flags da fase, condições narrativas e entrega correta dos itens ainda precisam de integração. |
| Térreo, quarto, quintal, cidade, portas/escadas com fade e persistência de coleta na sessão | Estados organizado/caótico completos, roteiro e epílogos ainda não estão implementados. Existem grupos de estado vazios e coletáveis de teste. |
| Cidade atual de 1024 × 576, marcadores dos POIs, luz de fim de tarde e luz dessaturada | O estado visual local da cidade ainda não é a progressão narrativa global. A subida e o terraço do clímax não existem. |
| Quitandeira em `idle_down` com conversa por E; varal, cavalo e galinhas no quintal | A conversa atual não entrega a peneira por condição; os puzzles e pistas ainda não estão ligados ao diário. |
| `scene_01_book_intro.tscn/.gd`, shaders e arte em `assets/art/ui/stage_01/book_intro/` | A sequência atual aceita clique, contém só uma imagem de livro configurada e não configura `proxima_cena`; pode terminar em tela preta. |
| `scene_02_santa_teresa_placeholder.tscn` | É um Node2D vazio, não uma segunda cutscene pronta. Não usar como destino final nem inventar cenas da colega inexistentes. |
| `assets/art/menu/menu_cover.jpeg` | Ainda não existe menu principal; `project.godot` inicia no quarto para edição. |
| Testes GUT de estado, Player, inventário, navegação, câmera e animais | Faltam testes da progressão completa, diálogos, diário, batalha, finais e retomada. |

Nos commits `Atualizando projeto` e `Cena 1`, o conteúdo de introdução foi integrado e organizado em `stage_01_saci` e `ui/stage_01/book_intro`. Preserve essa arte, os shaders e a composição; complete a sequência existente. Os nomes procurados pelo script (`livro - abrindo.png`, `livro - aberto completo.png`, `livro - virando.png`, `livro - virando 2.png`, `livro - desmanche.png`) não correspondem a PNGs presentes nessa pasta nesta auditoria. Arquivos `.import` não substituem imagens originais.

## Decisões de adaptação e continuidade

1. **RPG narrativo top-down:** movimento em quatro direções, interação por E, menus e escolhas pelo teclado, combate por turnos. Descartar primeira pessoa/raycast como controle principal, parkour, salto/plataformas, barra de Aproximação, esquiva obrigatória de projéteis na exploração, captura por timing/força e arrastar garrafa com mouse. A tensão virá do diálogo, som, investigação e decisões.
2. **Fluxo de abertura:** Menu → Novo Jogo → introdução do livro da colega → Santa Teresa ao entardecer → casa organizada → libertação/conversa → redemoinho/desmaio → casa caótica → investigação livre → ladeira/terraço → batalha → epílogo → créditos/menu. Não começar diretamente no quarto nem no placeholder.
3. **Mapas atuais prevalecem:** o ODT e o design antigo descrevem outra planta, incluindo coordenadas 1920 × 2240. Use os marcadores reais da cidade 1024 × 576 e os mapas de térreo/quarto/quintal já editados. Varal e cavalo ficam no quintal; a mureta e o portão removidos diante da casa na cidade não devem voltar. Adapte o texto que menciona esse portão.
4. **Clímax separado:** conectar a saída norte da cidade a uma nova cena de ladeira/terraço, preservando o mapa compacto. O marcador `WhirlwindBossSpawn` fora da área atual é só uma reserva, não uma arena funcional.
5. **Mural:** são seis quadros, apesar do título antigo dizer três. Deduplicar a fala repetida da quitandeira. O varal enumera cinco grupos, apesar de anunciar seis: usar meias, camisa, vestido, bilhete e conjunto dos sete gorros; lençol pode completar a decoração com descrição, sem inventar um sexto requisito de progresso.
6. **Itens e ordem:** inventário inicial vazio; retirar os coletáveis de teste da distribuição final. Garrafa vazia só após abrir a garrafa; fita na porteira do quintal; peneira somente da quitandeira; gorro somente no puzzle. Cachimbo na casa OU no banco, com identidade lógica única, sem duplicação. Sem limite rígido de 3–5 slots que descarte itens essenciais.
7. **Diário:** distinguir pista desbloqueada de pista lida. Contar apenas IDs únicos lidos; abrir/reler não aumenta o contador. As sete pistas-base e a página bônus estão definidas na Task 2.5. Descrições genéricas de itens não contam como novas pistas.
8. **Preparação e finais:** Captura exige `peneira_cruz` + `garrafa_vazia`; amizade exige `cachimbo_fumo` + três pistas-base lidas. A advertência da ladeira não bloqueia quem insiste em subir despreparado. O gorro facilita ações, sem virar requisito obrigatório nem substituir sozinho a investigação.
9. **Modelo de amizade:** usar `calm_progress` 0–100, conforme a revisão por turnos já existente. O antigo sistema alternativo de “dois pontos de confiança em três” fica substituído pelo medidor. Poupar exige calma 100 e preparação pacífica válida; cachimbo já oferecido no encontro continua atendendo ao requisito. Evitar completar amizade repetindo infinitamente a mesma piada ou ignorando as pistas.
10. **Final C recuperável:** nesta entrega ele faz parte do escopo, mesmo sendo opcional no ODT. Após três turnos improdutivos quando faltam as duas preparações, Saci se entedia e devolve o jogador à investigação. Não registra CAPTURE/FRIENDSHIP, não encerra definitivamente a fase e não remove os recursos necessários para tentar outra vez.
11. **Tom e folclore:** preservar suspense, humor, falas e consequências morais do ODT. Tratar explicações sobre a origem como versões da lenda; revisar simplificações culturais, especialmente a perna/capoeira, sem apresentar uma origem única e incontestável. Nenhum texto final deve conservar instruções editoriais do documento como fala do jogo.
12. **Fechamento da fase:** A/B encerram o capítulo e registram o resultado moral uma única vez. Incluir epílogo, tela de conclusão e créditos da fase; a futura Fase 2 não precisa existir para esta entrega terminar corretamente.

## Task 2.1 — Menu principal e início de Novo Jogo

**Depende de:** base da Sprint 01. **Entrega:** `ui/main_menu.tscn/.gd` e entrada executável do jogo.

- [x] Usar `res://assets/art/menu/menu_cover.jpeg` como capa de tela inteira, preservando proporção, título e personagens; escolher enquadramento responsivo sem distorcer a imagem. Não redesenhar a capa.
- [x] Criar `Novo Jogo`, `Opções`, `Créditos` e `Sair`, com fonte pixel, contraste legível, foco inicial em Novo Jogo, direcionais, E/Enter para confirmar e Esc para voltar. Não exibir botão Continuar sem carregamento funcional.
- [x] Fazer Novo Jogo limpar a sessão atual por uma única rotina e abrir a introdução existente. Impedir duplo acionamento e cliques/teclas atravessando o fade. Preparar a confirmação antes de substituir progresso salvo quando a Task 2.22 existir.
- [x] Alterar somente a cena inicial necessária em `project.godot`; preservar resolução, renderizador, inputs e demais configurações corretas. Os mapas continuam acessíveis com F6 para edição.
- [x] Entregar opções básicas de volume/mudo e créditos iniciais funcionais, com pontos de integração para 2.6 e 2.21. Não deixar botões sem ação.
- [x] **Aceite/testes:** F5 abre o menu; Novo Jogo chega à cutscene da colega com inventário vazio e sem vestígios da sessão anterior; foco e retorno dos submenus funcionam. `tests/test_main_menu.gd` cobre início único e reset. A conclusão da introdução será entregue em 2.4.

## Task 2.2 — Estado da fase, roteiro completo e progressão persistente

**Depende de:** 2.1. **Entrega:** estado puro da fase, dados narrativos e integração com WorldState.

- [x] Implementar `Stage01State` em `core/`, acoplado ao WorldState existente, com fases `book_intro`, `scene_2_sunset`, `scene_3_house_clean`, `scene_4_dialogue`, `scene_5_whirlwind`, `scene_6_house_chaos`, `scene_7_street_hub`, `scene_8_climax`, `epilogue_capture`, `epilogue_friendship`, `incomplete_recovery` e `completed`.
- [x] Guardar `saci_empatico`, `muro_pintado`, símbolo escolhido, quadros lidos, `viu_muro_ou_bonde`, entrega da peneira, puzzle do gorro, memória do cachimbo, pistas desbloqueadas/lidas, introduções vistas, objetivo atual, tentativas do clímax e resultado final. Usar IDs estáveis e reset completo de Novo Jogo.
- [x] Separar a fase global dos estados visuais derivados por mapa: atravessar uma porta não pode regredir a história nem voltar a organizar a casa antes do epílogo. Reaplicar estado ao carregar cada mapa.
- [x] Transcrever/revisar todo o roteiro útil do ODT em Resources de diálogo: oito cenas, narrações de chegada, cada interação ambiental, escolhas e respostas, memórias, sete POIs e epílogos. Registrar a cobertura por cena e preservar as falas longas, não apenas resumos do design técnico.
- [x] Validar transições de história, eventos de uma vez e ações repetíveis. Coleta, entrega e leitura não podem executar efeitos duplicados após revisitar a cena.
- [x] Conciliar o `07_stage_01_saci_design.md` com as decisões desta sprint ao implementar: planta atual, menu, entrada/saída do clímax, nomes reais da API e regras de diário/finais. Não replicar os erros `WorldState.Choice` ou APIs inexistentes.
- [x] **Aceite/testes:** `tests/test_stage_01_state_and_items.gd` cobre reset, progressão válida/inválida, flags únicas, manutenção entre mapas e os predicados de preparação. Não refazer a combinação de itens já implementada e testada.

## Task 2.3 — Diálogos ramificados e coordenação de cutscenes

**Depende de:** 2.2. **Entrega:** `core/dialogue/` e evolução compatível do HUD existente.

- [x] Implementar Resources de nós/falas/escolhas com condições de flags, itens e pistas, efeitos explícitos e sinais de início/fim. Reutilizar as confirmações, avisos e o componente de interação existentes.
- [x] Suportar narrador/personagem, múltiplas páginas, opções com mais de duas respostas e texto com acentos. E/Enter avança/confirma, direcionais escolhem e Esc retorna quando permitido. O mesmo evento não revela texto e confirma uma escolha crítica.
- [x] Controlar prioridade entre diálogo, cutscene, inventário, pausa e viagem; movimentação bloqueada enquanto necessário e restaurada em cancelamento, conclusão ou falha. Nenhuma tela pode depender do mouse.
- [x] Criar coordenador de sequências para animação, espera, câmera, som, fade e alteração de estado. Reutilizar SceneTransition, ampliando sua API quando não houver Player em cenas Control; não acoplar o menu ao caminho `YSortRoot/Player`.
- [x] Permitir pular efeitos/reproduções longas sem descartar decisões obrigatórias; preservar efeitos lógicos de uma cutscene concluída e evitar saltos que dupliquem itens.
- [x] **Aceite/testes:** `tests/test_dialogue_system.gd` cobre ramos, condições, avanço único, cancelamento e desbloqueio de movimento; falas simples da quitandeira e confirmações atuais continuam funcionando.

**Validação da Task 2.3 (19/11/2026):** 23/23 testes específicos e 154/154 testes do projeto aprovados via CLI headless, sem erros ou warnings. Prévia isolada em `ui/dialogue_preview.tscn` (F6); API em `core/dialogue/README.md`. Mapas e configuração inicial preservados. A Task 2.4 permanece pendente.

## Task 2.4 — Completar a introdução do livro da colega (Cena 1)

**Depende de:** 2.1–2.3. **Entrega:** completar `scene_01_book_intro.tscn/.gd`, preservando o material recebido.

- [x] Auditar a ordem real de cenas/imagens recebidas; reaproveitar `inicio.jpg`, `livro_aberto.png`, `rasgo_1.webp`, a composição e os shaders existentes. Listar os PNGs de páginas ausentes; não usar `.import` como arte nem recriar diretórios antigos `background/`, `scene/` e `scripts/`.
- [x] Mostrar o livro Lendas do Brasil e o tutorial por teclado. Completar conteúdo e virada de páginas; nas últimas, apresentar Saci, brilho e dissolução/letras caindo. Clique pode continuar como alternativa da introdução, sem ser necessário.
- [x] Configurar explicitamente a sequência final para `santa_teresa_map.tscn`, fase `scene_2_sunset`, spawn `PlayerEntrySpawn`; remover a dependência do placeholder vazio. Não terminar em tela preta aguardando um caminho ausente.
- [x] Bloquear avanço simultâneo durante tween/fade, assegurar reapresentação correta ao começar outro Novo Jogo e permitir pular a apresentação preservando a chegada/estado.
- [x] **Aceite/testes:** `tests/test_book_intro.gd` percorre todas as etapas e a saída real até a cidade por teclado, inclusive avanço rápido e ausência controlada de arte. Conferir visualmente a composição original. Arte provisória não fecha o aceite final de 2.23.

**Validação funcional da Task 2.4 (19/11/2026):** 14/14 testes específicos e 168/168 testes do projeto aprovados via CLI headless, sem erros ou warnings. Livro por E/Enter, skip por Esc e chegada real em Santa Teresa, fase `scene_2_sunset`, spawn `PlayerEntrySpawn`. Composição inspecionada via texturas/geometria real e prévia CPU. As cinco imagens de páginas continuam ausentes e os efeitos GPU precisam de revisão gráfica no editor; isso permanece no acabamento da Task 2.23, sem declarar arte final concluída. Auditoria e controles: `stages/stage_01_saci/BOOK_INTRO.md`. A Task 2.5 permanece pendente.

## Task 2.5 — Diário do livro e integração do inventário

**Depende de:** 2.2–2.3. **Entrega:** páginas de investigação em `core/` e UI de leitura ligada ao livro inicial.

- [x] Criar `JournalEntry` e Resources de páginas com título, texto completo, ilustração quando disponível, origem e ID. Integrar ao inventário/HUD atual, com navegação por teclado e indicação de páginas novas/lidas.
- [x] Cadastrar sete pistas-base: `clue_origem_saci` (cachimbo), `clue_poder_gorro_parede` (casa caótica), `clue_gorro_vermelho` (varal), `clue_mural_origens` (quadros 1–5), `clue_inquerito_1917` (bonde), `clue_crina_cavalo` (quintal), `clue_bambu_rachado` (bambuzal).
- [x] Desbloquear `clue_dia_do_saci_bonus` após ler as sete pistas-base: Dia do Saci em 31 de outubro. A página bônus não conta como uma oitava pista para facilitar requisitos. Os quadros podem ter subregistros, mas a pista agregada do mural conta só uma vez.
- [x] Definir leitura concluída ao terminar de apresentar o texto da entrada, no diálogo ou no diário. Reabrir, receber um ícone ou apenas desbloquear sem ler não soma pistas. `pistas_saci_lidas` deve ser derivado dos IDs únicos lidos.
- [x] Preservar inventário full-screen com `ui_inventory_background`, slots à esquerda sem painel atrás, opções no alto à direita, descrição apenas ao Examinar e `ui_scrollbar.png`. Manter Examinar/Ler e Combinar cinza quando falta ingrediente; ícones sem shader na UI.
- [x] Preservar textos sem “item [nome]” redundante, escala pequena dos coletáveis no mapa, insights e confirmação da peneira com cruz. As páginas genéricas de teste não substituem as pistas narrativas.
- [x] **Aceite/testes:** `tests/test_journal_system.gd` cobre leitura única, agregação do mural, bônus e persistência; ampliar os testes existentes do inventário apenas para as integrações novas.

**Validação da Task 2.5 (19/11/2026):** diário integrado ao inventário por teclado, oito Resources, sete pistas-base únicas e bônus; leitura incompleta não conta. 16/16 testes específicos e 184/184 testes do projeto aprovados via CLI headless, sem erros ou warnings. Geometria em quatro formatos e prévias CPU inspecionadas; revisão gráfica nativa continua em 2.23. Progresso persiste entre mapas na sessão, com reset em Novo Jogo; save em disco permanece em 2.22. A ligação narrativa dos POIs será executada nas tasks correspondentes. Documentação: `core/journal/README.md`. Próxima entrega: Task 2.6.

## Task 2.6 — Áudio, apresentação e opções acessíveis

**Depende de:** 2.1–2.3. **Entrega:** gerenciamento de áudio e opções compartilhadas.

- [x] Inventariar áudio disponível e pendências: menu, livro/páginas, ambiente/vento, casa, capoeira/berimbau, investigação, clímax, risada, rolha, portas, UI e epílogos. Registrar origem/licença e evitar múltiplas BGMs simultâneas.
- [x] Implementar buses Master/Music/SFX, volume e mudo persistentes, transições suaves por estado e áudio posicional quando útil. Usar no máximo o AudioManager previsto na arquitetura.
- [x] Oferecer ajuste de velocidade do texto e redução de tremor/flashes; efeitos devem transmitir informação também por texto/animação, sem depender exclusivamente de som ou cor.
- [x] Implementar silêncio de três segundos após coletar o gorro e retorno mais grave sem alterar a duração da pausa; restaurar a música correta se houver viagem/pausa durante o efeito.
- [ ] **Aceite/testes:** estado de áudio, restauração de volume e cancelamento de efeitos testáveis sem dispositivo de áudio; revisão manual da mistura, legibilidade e opções. Não declarar áudio final entregue quando faltarem arquivos.

**Validação funcional da Task 2.6 (19/11/2026):** 12/12 testes específicos e 196/196 testes do projeto, 9.138 asserts, aprovados via CLI headless sem erros ou warnings. AudioManager único, Master/Music/SFX, preferências persistentes, uma BGM com fade, áudio posicional, velocidade de texto, redução de tremor/flashes e silêncio de 3.000.000 µs do gorro com restauração após pausa/viagem. Sintaxe da lógica pura e abertura por CLI validadas. **O aceite sonoro/manual permanece pendente:** `assets/audio/` não tinha gravações; os 24 streams e suas origens/licenças ainda devem ser fornecidos e a mistura precisa de revisão auditiva. Por isso o checkbox de aceite completo continua aberto; não se declara áudio final entregue. Catálogo, pendências e contratos: `assets/audio/README.md` e `core/audio/README.md`. A próxima implementação narrativa é a Task 2.7; acabamento sonoro também é acompanhado na Task 2.23.

## Task 2.7 — Primeira chegada a Santa Teresa (Cena 2)

**Depende de:** 2.2–2.6. **Entrega:** primeira exploração narrativa na cidade existente.

- [x] Aplicar entardecer `#ffdfb3`, narração de chegada do ODT (letras nos dedos, ladeira, silêncio e vento) uma vez e tutorial breve de movimento/E/Tab. Objetivo: Entrar na casa.
- [x] Implementar bonde vazio com banco quente, placa Rua do Saci e janela balançando com risadinha. Criar a placa se faltar, usando os assets corretos; manter caminhos físicos acessíveis.
- [x] Adaptar a descrição da porta entreaberta ao cenário atual, sem mencionar portão removido; oferecer Sim/Ainda não, resposta de hesitação e entrada com cheiro de fumo e madeira.
- [x] Manter porta funcional na cidade, retorno seguro e visitas coerentes; investigação/entrega da peneira e subida do clímax só ficam disponíveis na fase narrativa apropriada. Nada de acionar a ladeira na Cena 2.
- [x] **Aceite/testes:** `tests/test_stage_01_progression.gd` cobre chegada única, interações iniciais, recusa, entrada e objetivo. Preservar testes de navegação e câmera da cidade.

**Validação funcional da Task 2.7 (19/11/2026):** 12/12 testes de progressão e 208/208 testes do projeto, 9.320 asserts, aprovados via CLI headless sem erros ou warnings. Narração/tutorial únicos após o fade, objetivo no HUD, bonde/placa/janela por E, Sim/Ainda não, entrada na casa organizada com fase/spawn sob preto e retorno preservando progresso. Pré-validação de destino reavaliada por tentativa e restauração da movimentação quando a viagem é interrompida durante o fade. Comparação: 332 blocos de nós e 48 sub-recursos antigos da cidade preservados; térreo/quarto/quintal e project.godot intactos. **Áudio final não entregue:** a chamada posicional e a descrição textual da risadinha estão prontas, mas sua gravação continua ausente no catálogo da Task 2.6; escuta/revisão gráfica nativa permanecem em 2.23. Detalhes: `stages/stage_01_saci/CITY_ARRIVAL.md`. Próxima implementação: Task 2.8.

## Task 2.8 — Casa organizada e memória do cachimbo (Cena 3)

**Depende de:** 2.2–2.7. **Entrega:** roteiro da casa organizada nos mapas existentes.

- [x] Aplicar estado organizado e narração de entrada. Configurar sofá/almofada, relógio com ponteiros para trás, leite azedo com data de hoje e cama do quarto com fio de crina trançado. Quarto permanece cena própria acessível pela escada.
- [x] Cachimbo: descrição, voz do Saci, memória completa sobre bambu/sete anos/77 anos/cogumelo/Saci-Cererê, efeito visual moderado e página Origem do Saci; depois Sim/Colocar de volta.
- [x] Separar ver a memória de guardar o cachimbo: recusar mantém a possibilidade de coleta posterior. Casa e banco representam a mesma unidade lógica; não reaparecer caso já coletado/oferecido.
- [x] Criar a garrafa fechada como interação narrativa separada da garrafa vazia. Abrir/Deixar: Deixar toca vibração, piscar, Tec e risada, e permite retomar a escolha sem prender o jogo em loop automático de modal.
- [x] Tirar fita, peneira e garrafa vazia de teste do fluxo final da casa organizada; preservar o que for necessário em cenas de teste separadas. Atualizar testes antigos que pressupunham essa distribuição provisória, mantendo cobertura de coleta/combinação.
- [x] **Aceite/testes:** variantes de interação, recusa/revisita, cachimbo único em duas localizações, escadas e impossibilidade de pegar a garrafa vazia antes do evento.

**Validação funcional da Task 2.8 (19/11/2026):** 14/14 testes específicos e 222/222 testes do projeto (9.475 asserts) via CLI headless sem erros ou warnings, incluindo caminhos com a colisão real dos pés, registrados em `stages/stage_01_saci/HOUSE_INVESTIGATION.md`. Chegada única; sofá/relógio/leite/cama por E; memória completa; página Origem do Saci com leitura separada; Sim/Colocar de volta; identidade única casa/banco após consumo; Abrir/Deixar sem loop; garrafa vazia indisponível antes do despertar. Os quatro pickups mecânicos antigos ficaram em `tests/fixtures/inventory_mechanics_lab.tscn`, mantendo coleta, brilho, UI e combinação testados. Todos os blocos anteriores de tiles/sub-recursos/móveis/colisões/portas/câmeras/marcadores foram preservados; cidade, quintal e project.godot intactos. Gravações continuam ausentes conforme Task 2.6; revisão gráfica/sonora final permanece em 2.23. A abertura entrega scene_4_dialogue e o sinal bottle_opening_completed; aparição/conversa não foram antecipadas. Próxima Task: 2.9.

## Task 2.9 — Saci e efeitos visuais necessários ao roteiro

**Depende de:** 2.2; pode auditar assets enquanto 2.7–2.8 avançam. **Entrega:** cena da entidade e catálogo de arte faltante.

**Situação: parcial, não concluída.** Entidade/redemoinho e auditoria disponíveis; template humano e perna única ausentes. Não iniciar 2.10 com vento no lugar da perna única.

- [ ] Inspecionar os PNGs reais em `assets/art/characters/folklore/saci/`, proporções e animações; montar a entidade reutilizável em `entities/folklore/`, com perna única, gorro e pivô nos pés. Reaproveitar sprites existentes, sem supor redemoinho disponível.
- [ ] Preparar aparição, idle, fala, giro/despedida e forma de redemoinho usando frames reais. A versão de perna única aparece na conversa; a forma de vento atende à saída e ao clímax.
- [x] Listar/generar somente com o fluxo autorizado os assets ausentes: fumaça, furacão grande, estados bagunçados, gorros/roupas, seis grafites, símbolos pintáveis, gomo rachado e recursos dos epílogos. Informar medidas, frames e caminhos para o usuário produzir no PixelLab pelo navegador se preferir.
- [x] Antes de qualquer geração, seguir a skill de assets e inspecionar templates. Não recortar concept/capa para virar sprite e não substituir silenciosamente arte faltante por ícones sem relação.
- [ ] **Aceite/testes:** recortes válidos, frames e pivôs alinhados, sem mudar os sprites da protagonista; pendências registradas por Task. Só marcar concluída com os recursos necessários ao uso da entidade disponíveis.

**Auditoria parcial da Task 2.9 (19/11/2026):** 24 PNGs reais, quatro idles 80×80 e cinco frames walk por direção (Down 64×80, demais 96×96), todos com redemoinho. SpriteFrames normaliza transparência/âncoras para canvas lógico 64×80 sem redimensionar nem cortar pixels. SaciActor inicia oculto, sem colisão; formas/ações ausentes retornam false e emitem visual_unavailable, sem aliases ou placeholders. Prévia F6 em saci_visual_preview.tscn. Catálogo por Task com medidas, frames, destinos e briefings: stages/stage_01_saci/ART_REQUIREMENTS.md; fontes em assets/art/characters/folklore/saci/ART_AUDIT.json. Template character_base/body ausente; a única correspondência remota do PixelLab é um Saci de batalha 96×96 com redemoinho, não reutilizado como exploração. Não houve geração nem alteração de PNGs, Player, mapas, spawns ou project.godot. 11/11 testes específicos e 234/234 testes do projeto, 9.935 asserts, aprovados via CLI headless sem erros ou warnings; scripts novos aprovados em --check-only e prévia inicia limpa. Requisitos de perna única/aparição/fala/giro/despedida continuam abertos e a Task NÃO está concluída. A suíte identificou efeitos de leitura/tutorial/rastreabilidade ausentes no roteiro desde antes da Task; restaurados somente os metadados, com teste de gravação/recarga, preservando falas/escolhas/UIDs.

**Atualização da busca (19/11/2026):** o usuário informou assets prontos, mas a versão de uma perna ainda não foi localizada entre os PNGs de produção. A listagem completa do PixelLab também encontrou o personagem `6a3eca75-75a1-4254-929c-ba2b30a2462b` (nome em inglês), correspondente ao redemoinho local; portanto a busca anterior apenas por “Saci” era incompleta. O pacote humano original existe em Downloads (`World Build - Character Pack - 0.2/Character/Body_A`), fora do caminho de templates do projeto. O cache antigo de uma prancha não foi tratado como arte aprovada. Nenhum PNG foi gerado ou substituído. Auditoria corrigida em `stages/stage_01_saci/ART_REQUIREMENTS.md`.

## Task 2.10 — Libertação e conversa com Saci (Cena 4)

> Auditoria da Task 2.8: `SaciBottleSpawn` ainda é reserva; validar posição livre junto da aparição. Não instanciar a entidade supondo que as coordenadas antigas estejam aprovadas.

**Depende de:** 2.3, 2.8–2.9. **Entrega:** sequência narrativa da garrafa até a despedida.

**Preparação parcial, sem ativação no mapa:** `SaciConversationScript` preserva os seis caminhos de escolhas e encerra antes da Cena 5. `SaciConversation` valida a arte humana, coordena aparição/idle/fala, mantém decisões obrigatórias, registra empatia e entrega a fase uma vez sem um frame de deslocamento entre sequências. Testes cobrem seis ramos, teclado, cancelamento/retomada, arte inválida e limpeza de dependências. Texturas sintéticas são usadas apenas em memória nos testes, nunca como assets finais. A Task permanece aberta: falta identificar os novos PNGs de uma perna, validar o marcador, integrar efeitos da garrafa, retomada e saída. Não há conexão nova em HouseInterior; mapas, Player e project.godot foram preservados. Contrato e pendências em `stages/stage_01_saci/SACI_CONVERSATION.md`.

- [ ] Abrir garrafa: cera derrete, rolha/Pop, fumaça e aparição de gorro/olhos/sorriso/perna única/Toc. Posicionar por marcadores seguros, sem coordenadas antigas do ODT.
- [ ] Preservar todos os ramos da primeira escolha: Eu só estava curioso / Quem é você? / Você ficou preso aí muito tempo? Somente a última registra `saci_empatico`.
- [ ] Incluir a parte comum sobre estar preso ouvindo o mundo mudar e o livro contar a história errada. Segunda escolha: Conta a sua versão / O que você vai fazer agora?, com respostas próprias.
- [ ] Despedida: agradecimento pela rolha, comemoração e indicação de procurar onde o vento fizer curva. Disparar Cena 5 uma vez, sem liberar deslocamento no meio da sequência.
- [ ] **Aceite/testes:** todos os ramos convergem corretamente, empatia persiste, interação repetida na garrafa não cria outro Saci nem recomeça o evento.

## Task 2.11 — Redemoinho, saída e desmaio (Cena 5)

**Depende de:** 2.6, 2.9–2.10. **Entrega:** cutscene in-engine de saída e mudança de estado sob tela preta.

- [ ] Animar giro sobre a perna única, transformação em vento e trajeto até a porta existente; móveis/colisores não podem prender a entidade durante a coreografia.
- [ ] Coordenar vento crescente, tremor opcional, vinheta, escurecimento e tela preta. Preservar Nearest; qualquer desfoque é efeito temporário da cena, nunca alteração permanente da pixel art.
- [ ] Sob preto, aplicar evento irreversível de garrafa aberta e estados caóticos; reposicionar protagonista em marcador livre no térreo e restaurar câmera antes de revelar a Cena 6.
- [ ] Pular/reentrar/cancelar efeitos não pode repetir a libertação nem deixar controles, áudio ou overlay presos. Persistir apenas um ponto estável ao salvar.
- [ ] **Aceite/testes:** evento único, jogador imóvel durante sequência, estado correto ao despertar e ausência de flash do mapa organizado.

## Task 2.12 — Despertar na casa caótica (Cena 6)

> Auditoria da Task 2.8: o marcador preexistente `PlayerWakeUpSpawn` (320, 384) está dentro de parede. Reposicionar e testar os pés no despertar; não afetar `FromCity`, `FromBedroom`, `FromBackyard` ou o spawn de edição, que continuam válidos.

**Depende de:** 2.5, 2.8, 2.11. **Entrega:** cenário e interações pós-redemoinho.

- [ ] Preencher variantes caóticas de modo editável, preservando a montagem organizada. Alternar visibilidade e colisões juntas; props invisíveis não bloqueiam o Player e o caminho às saídas fica transitável.
- [ ] Implementar almofada no lustre, relógio desordenado, leite derramado com carinhas, estante sem garrafa e bilhete Obrigado pela rolha, além do grafite Quem perde o gorro perde o rumo.
- [ ] Ativar garrafa vazia caída perto da estante, com confirmação e persistência. O grafite apresenta e desbloqueia a pista do poder do gorro.
- [ ] Implementar laço de crina bloqueando o acesso ao quarto por estado, com descrição da cama/travesseiro. Nunca bloquear o retorno de quem já esteja no quarto ao reaplicar um estado; manter rota segura por portas e escada.
- [ ] Saída: porta torta, vento e objetivo Descobrir o que aconteceu. Ao sair pela primeira vez, aplicar `scene_7_street_hub`; visitas posteriores preservam o progresso.
- [ ] **Aceite/testes:** caminhos na variante caótica, garrafa única, pista, bloqueio e retomada das transições para cidade/quintal.

## Task 2.13 — Rua caótica e investigação livre (Cena 7)

**Depende de:** 2.7, 2.12. **Entrega:** aplicação persistente do caos urbano.

- [ ] Aplicar luz dessaturada `#9eaab8`, narração da rua bagunçada e ativação das interações investigativas. Revisitar não repete a narração de abertura.
- [ ] Adicionar roupas nos postes, objetos deslocados/flutuantes e pegadas de uma perna só conectando os pontos de interesse e indicando a subida. Os rastros conduzem sem substituir a exploração por uma ordem obrigatória.
- [ ] Usar os sete POIs distribuídos entre cidade e quintal, preservando praça, quitanda, casas e bambuzal já montados. Usar marcadores, não coordenadas do mapa antigo.
- [ ] Exibir objetivo/pistas de próximo passo sem revelar soluções. Permitir entrar/sair da casa e do quintal sem reiniciar cenas nem recolocar itens.
- [ ] **Aceite/testes:** interações de Cena 2 mudam para suas variantes investigativas; POIs funcionam em ordens diferentes, sem bloqueios de circulação.

## Task 2.14 — Quintal: puzzle dos gorros, cavalo e fita (POIs 1 e 5)

**Depende de:** 2.5–2.6, 2.12–2.13. **Entrega:** investigação no quintal existente.

- [ ] Varal: narração das roupas pingando sem vento e descrições de meias desencontradas, camisa invertida, vestido/bilhete e poste com Quem tem o gorro manda no Saci. Não mover o varal de volta para a rua.
- [ ] Exibir sete gorros acessíveis por interação top-down: seis falsos balançam e retornam Frio/Mole/Hihihi; verdadeiro fica parado, morno e cheira a fumo. Não exigir salto, clique em sprite ou memorização de um pixel.
- [ ] Verdadeiro: Pegar/Deixar, item e página do gorro uma vez; micro-redemoinho e pausa de áudio de três segundos ao pegar. Deixar permite voltar.
- [ ] Cavalo: interação descreve crina trançada/cansaço e apresenta pista de travessuras com animais; preservar animação de comer e as duas galinhas caminhando/comendo.
- [ ] Fita na porteira: coletar uma vez sem abrir uma saída para mapa inexistente; garantir que ela não permaneça duplicada na casa.
- [ ] **Aceite/testes:** seis falsos, verdadeiro único, recusa/revisita, leitura e coleta separadas, fita única e retorno para a cozinha; física e profundidade atuais do quintal preservadas.

## Task 2.15 — Praça e cachimbo alternativo (POI 2)

**Depende de:** 2.8, 2.13. **Entrega:** banco como segunda oportunidade de obter cachimbo/fumo.

- [ ] Exibir cachimbo/fumo e fumaça no banco apenas se ainda não guardados na casa. Examinar apresenta a memória e a página Origem do Saci caso ainda não tenham sido vistas.
- [ ] Permitir guardar ou deixar; usar o mesmo registro lógico de item e memória da casa. Não duplicar a pista, o flashback nem a quantidade ao alternar entre casa e praça.
- [ ] Se já coletado/oferecido, usar descrição coerente do banco sem prometer um objeto inexistente.
- [ ] **Aceite/testes:** caminhos casa-primeiro e praça-primeiro, recusa, nova visita e retomada mantêm uma única unidade narrativa.

## Task 2.16 — Seis quadros e pintura do mural (POI 3)

**Depende de:** 2.5, 2.9, 2.13. **Entrega:** seis interações nos marcadores reais de MuralWall.

- [ ] Inserir a arte própria dos seis quadros; não marcar concluído com marcadores vazios. Apresentar a narração da tinta fresca e a assinatura do gorro.
- [ ] Quadros 1–5: menino da mata/Saci-Cererê, bambu/sete anos, capoeira/influências africanas, gorro/influências europeias, redemoinho/travessuras. Usar os textos completos revisados do ODT e registrar cada quadro lido.
- [ ] Qualquer quadro visto pode dar confiança à quitandeira (`viu_muro_ou_bonde`); só a leitura dos cinco quadros informativos completa `clue_mural_origens`. Não contar cinco pistas-base diferentes.
- [ ] Sincronizar o brilho do quadro 2 com o bambu por tempo/estado compartilhado, inclusive após trocar de mapa; animar as travessuras do quadro 5 sem prejudicar leitura.
- [ ] Quadro 6: frase Cada um conta o Saci do seu jeito, pincel e escolha Pintar/Deixar em branco. Pintar abre Gorro/Bambu/Redemoinho, salva símbolo e aplica decalque; deixar permite voltar depois. Preservar a arte escolhida nas revisitas e no epílogo.
- [ ] **Aceite/testes:** leitura em qualquer ordem, condição de página completa, pintura/cancelamento, símbolo persistente e comentário futuro do Saci.

## Task 2.17 — Bonde de 1917 e bambu rachado (POIs 4 e 7)

**Depende de:** 2.5, 2.9, 2.13. **Entrega:** duas pistas independentes acessíveis na cidade.

- [ ] Bonde: jornais amarelados, inquérito de 1917, relatos enviados a Monteiro Lobato e página correspondente. Definir `viu_muro_ou_bonde` ao examinar o conteúdo, sem exigir o mural.
- [ ] Bambuzal: inserir gomo rachado com mãozinha, vento/risadinha e texto sobre nascimento no bambu/sete anos, com página própria. Garantir acesso pela abertura atual entre as moitas.
- [ ] Manter sincronismo visual com o quadro 2 e textos coerentes antes/depois da leitura; repetir interação não entrega novos itens nem soma pistas novamente.
- [ ] **Aceite/testes:** bonde e bambu em qualquer ordem; confiança da quitandeira liberada pelo bonde; registro de duas páginas únicas.

## Task 2.18 — Quitandeira e obtenção narrativa da peneira (POI 6)

**Depende de:** 2.3, 2.5, 2.13, 2.16–2.17. **Entrega:** diálogo completo na NPC existente.

- [ ] Manter quitandeira parada em `idle_down`, atrás do balcão e alcançável por E. Abertura Psiu! Ele foi embora?, com Como faço para pará-lo? / Você viu o Saci?
- [ ] Incluir a história do fubá/pegada no pão e a receita da avó: peneira, fita em cruz, redemoinho e garrafa tampada. Remover a repetição acidental do ramo Você viu o Saci no ODT.
- [ ] Antes de ver mural OU bonde, usar resposta de desconfiança que oriente a investigação; depois, permitir a entrega da peneira uma única vez, independente da ordem dos POIs.
- [ ] Integrar à receita já existente e à UI: Combinar indisponível com um ingrediente, confirmação com ambos, remoção dos dois e resultado peneira com cruz. Não entregar outra peneira após combinar ou usar a primeira.
- [ ] **Aceite/testes:** antes/depois da condição, mural versus bonde, todos os ramos, visitas repetidas, item já combinado e coleta sem peneira de teste na casa.

## Task 2.19 — Ladeira, terraço e chegada ao clímax (Cena 8, abertura)

**Depende de:** 2.13–2.18. **Entrega:** nova cena de exploração `stages/stage_01_saci/saci_climax.tscn` ligada à saída norte.

- [ ] Criar ladeira e terraço top-down com piso, detalhes, limites, obstáculos coerentes, Y-Sort, câmera limitada e marcadores de ida/volta; preservar integralmente o bairro existente.
- [ ] Na subida, testar preparação de captura OU amizade. Se faltar, mostrar O vento diz que ainda tem coisa para ver. Subir assim mesmo? com Subir/Voltar. Cancelar restaura movimento sem repetir a pergunta enquanto o Player permanecer na área.
- [ ] Incluir trilha de pegadas, vento crescente e narrações da subida/topo. Furacão grande com objetos como efeito visual, sem colisão ofensiva ou barra de sobrevivência.
- [ ] Permitir interagir por E com o furacão e iniciar batalha com transição, estado e inventário preservados; oferecer retorno para investigar antes do confronto.
- [ ] **Aceite/testes:** ambas as preparações, despreparado/recusa/insistência, chegada sem colisão e retorno; usar APIs de transição compatíveis com cenas de combate Control.

## Task 2.20 — Batalha narrativa por turnos contra Saci

> Diretriz do usuário: usar um quadrado vermelho como representação provisória do Saci em batalha enquanto os assets definitivos são preparados; manter um ponto de substituição pela arte final.

**Depende de:** 2.3, 2.5–2.6, 2.9, 2.19. **Entrega:** `core/combat/`, `SaciCombatController` puro e `saci_turn_combat.tscn`.

- [ ] Implementar estados abertura → turno da protagonista → resposta do Saci → resolução. Bloquear inputs duplicados, validar ações antes de gastar itens e separar regras, dados e animação.
- [ ] Menu pelo teclado: Interagir/Brincar, Item, Confrontar, Amizade/Poupar. Cada submenu tem retorno; informar por que uma opção está indisponível. Não exigir combate de reflexo, barra de timing, força ou arrastar objetos.
- [ ] Calma 0–100: piada/adivinha +25, brincar +25, falar da origem +35 com três pistas lidas, elogiar +15 ou +25 se pintou, oferecer cachimbo +40 e devolver gorro leva a 100. Ganhos de cada ação são únicos por encontro; repetição gera fala sem ganho infinito. Valores ficam nos dados do encontro para ajuste.
- [ ] Poupar só resolve amizade com calma 100 e preparação pacífica (cachimbo possuído ou já oferecido + três pistas-base lidas). Devolver gorro sem essas condições rende resposta/orientação e não salta a investigação.
- [ ] Captura: peneira com cruz avança 0→1, Segurar Peneira ou mostrar o gorro avança 1→2, garrafa avança 2→3. Fora de ordem/faltando recurso, usar resposta narrativa sem consumir, travar menu ou avançar estágio. Gorro não é obrigatório.
- [ ] Reservar recursos usados no encontro e confirmar consumo somente na resolução A/B; saída por Final C/falha recuperável devolve as reservas. Peneira com cruz e garrafa são comprometidas na captura; cachimbo/gorro oferecidos, na amizade. Não perder itens essenciais em tentativas incompletas nem duplicá-los na volta.
- [ ] Respostas do Saci usam falas do ODT, brincadeiras de embaralhar opções por um turno e texto esverdeado/tremor opcional. Alterar ordem visual não pode fazer a confirmação executar outra ação; manter seleção pelo ID e sinalizar a travessura.
- [ ] Sem HP a zerar ou Game Over obrigatório. Com ambas as preparações ausentes, três turnos sem avanço real levam ao Final C; avanço real reinicia o contador. Com rota disponível, permitir resolver ou recuar de forma recuperável. Definir efeito de trocar intenção: iniciar amizade desfaz contenção temporária, reinicia estágio de captura e libera sua reserva sem duplicar recursos.
- [ ] **Aceite/testes:** `tests/test_stage_01_saci_combat_and_endings.gd` cobre todos os pré-requisitos, limites, repetição, três estágios, troca de intenção, recursos, recuperação C e opções embaralhadas. Testar a cena por input real além da lógica pura.

## Task 2.21 — Epílogos A/B, recuperação C e encerramento da fase

**Depende de:** 2.2–2.6, 2.12–2.13, 2.20. **Entrega:** três desfechos completos e conclusão jogável.

- [ ] A/Captura: apresentar peneira, luta do Saci, rolha/Pop, garrafa tampada e texto completo do ODT; arrumar casa/rua, desbotar desenhos e saturar cores de modo controlado, sem risada. Com quatro ou mais pistas lidas, incluir Você sabia o que ele era. Foi assim mesmo?
- [ ] B/Amizade: reproduzir falas conforme cachimbo oferecido, gorro devolvido, empatia e mural pintado; comentário considera o símbolo escolhido. Saci promete arrumar e brincar amanhã; redemoinho vira pétalas, roupas voltam, grafites florescem e há risada alegre.
- [ ] A/B: registrar exatamente uma vez `WorldState.register_entity_outcome(&"saci", WorldStateLogic.Outcome.CAPTURE/FRIENDSHIP)` e conclusão. Evitar reaplicar consumo, recompensa ou mudança moral ao carregar/reentrar no epílogo.
- [ ] C/Incompleto: bocejo/Que tédio, casa quase organizada com relógio invertido; retornar a spawn seguro, preservar leitura, itens e flags. Manter POIs pendentes acessíveis, inclusive a escada do quarto quando apropriado. Não disparar créditos de conclusão nem registrar resultado moral definitivo.
- [ ] Entregar epílogo explorável breve ou sequência guiada, objetivo final e tela Fase do Saci concluída para A/B; créditos da equipe/colega/assets e opções Voltar ao menu/Novo Jogo. Sem porta ou botão apontando a uma Fase 2 inexistente.
- [ ] **Aceite/testes:** três desfechos, comentários condicionais, estados de cada mapa, registro único e C seguido por nova investigação e resolução A ou B.

## Task 2.22 — Pausa, checkpoints e retomada da fase

**Depende de:** 2.2–2.5, 2.20–2.21. **Entrega:** pausa e save/load de pontos narrativos estáveis.

- [ ] Adicionar pausa por Esc quando não houver modal prioritário: Retomar, Opções e Voltar ao menu com confirmação. Fechar diálogo/inventário primeiro; não disparar pausa por baixo deles.
- [ ] Salvar em `user://` uma versão de dados: fase, mapa/spawn seguro, inventário/quantidades, registros de coleta, diário, puzzles, empatia, pintura, resultado e checkpoint de conclusão. Não serializar Nodes ou recursos arbitrários como estado de sessão.
- [ ] Criar checkpoints depois da chegada à cidade, do despertar, de marcos de investigação e da resolução. Não salvar em meio a tween, troca de cena, animação crítica ou reserva de item de batalha; ao interromper combate, retomar de estado estável sem perda/duplicação.
- [ ] Mostrar Continuar somente com save válido; validar versão, IDs e caminhos antes de carregar. Arquivo ausente/corrompido falha com mensagem e menu utilizável, sem quebrar Novo Jogo. Gravar de modo seguro e preservar opções de áudio separadas do progresso.
- [ ] Novo Jogo pede confirmação se substituir uma partida salva; a confirmação pertence ao jogador no menu, não a uma aprovação da implementação. Reset limpa todos os flags e não herda final anterior.
- [ ] **Aceite/testes:** `tests/test_stage_01_save.gd` cobre round-trip, reset, save inválido, checkpoint antes do combate, retomada de epílogo sem repetir moral e retorno de C com recursos íntegros.

## Task 2.23 — Acabamento de arte, áudio, texto e experiência

**Depende de:** 2.4–2.22; inventário de faltas pode avançar antes. **Entrega:** conteúdo final da fase sem placeholders críticos.

- [ ] Consolidar lista de assets por caminho, tamanho, animação, uso e origem/licença: páginas ausentes do livro, Saci/redemoinho, seis grafites/símbolos, objetos caóticos, roupas/gorros, pistas, terraço, efeitos de pétalas e áudio. Separar falta funcional de diferença estética opcional em relação ao concept.
- [ ] Integrar os arquivos finais fornecidos/gerados pelo fluxo autorizado; preservar templates e inspirações, organizar por domínio e atualizar referências sem quebrar imports/UIDs. Não gerar arte com ferramenta diferente da solicitada pelo usuário.
- [ ] Revisar todos os textos do ODT adaptados, pontuação/acentos, consistência do nome da protagonista, pronomes e nomes dos itens, sem comentários editoriais, repetições ou promessa de ação ausente.
- [ ] Revisar tela inteira do menu, inventário, diário, diálogo e combate em 640 × 360 e formatos de janela distintos. Foco de teclado sempre visível, texto sem corte, ícones limpos e indicação de voltar/confirmar.
- [ ] Revisar todos os mapas/estados visualmente no Godot: caminhos, profundidade, telhados/sombras acima da protagonista, colisões nos pés, nenhuma zona cinza visível pela câmera e spawn livre. Não alterar a composição manual por conveniência do roteiro.
- [ ] **Aceite:** checklist visual/sonoro realizado; nenhuma pendência essencial marcada concluída só porque lógica headless passou. Assets cosméticos opcionais restantes devem ser explicitamente listados.

## Task 2.24 — Validação do início ao fim e build da Fase 1

**Depende de:** todas as anteriores. **Entrega:** fase concluída e pacote executável verificável.

- [ ] Executar toda a suíte GUT existente e nova, com 100% de aprovação, sem erros, warnings de scripts ou Nodes órfãos. Atualizar expectativas antigas somente quando o comportamento de produto mudou; não apagar testes para ocultar regressão.
- [ ] Criar `tests/test_stage_01_full_flow.gd` exercitando menu → introdução → cidade → casa → conversa → desmaio → investigação → clímax → A/B; cobrir também C → recuperar → concluir, usando inputs/eventos de produto em marcos reais.
- [ ] Cobrir combinações: empático/não empático; mural pintado/não pintado; cachimbo da casa/praça; gorro pego/deixado; quitandeira antes/depois do muro OU bonde; POIs em ordens diferentes; save/Continuar; segundo Novo Jogo após um final.
- [ ] Jogar manualmente A, B e C sem comandos de debug, mouse obrigatório ou desbloqueio artificial; conferir som, leitura, ritmo de cenas, créditos e retorno ao menu. Automação não substitui essa revisão visual.
- [ ] Criar preset de export para a plataforma de entrega, verificar templates de export e empacotar somente assets de produção. Se faltarem templates, registrar dependência real e não marcar a build pronta.
- [ ] Testar o executável fora do editor: abrir no menu, iniciar, salvar/retomar, concluir e sair. Documentar controles, versão/plataforma, build, testes executados e pendências opcionais no README da fase.
- [ ] **Aceite final:** a fase do Saci inteira pode ser terminada a partir de Novo Jogo e reproduzida a partir de um estado limpo. A conclusão não depende de fases futuras, sprites de teste ou acesso ao editor.

## Matriz de cobertura do documento original

| Trecho/necessidade | Tasks responsáveis |
| --- | --- |
| Menu com capa e Novo Jogo, ausente no ODT | 2.1, 2.22 |
| Cena 1: livro, tutorial, brilho e transporte | 2.3–2.4 |
| Cena 2: chegada, bonde, placa, janela e entrar/recusar | 2.7 |
| Cena 3: sofá, relógio, leite, quarto, cachimbo e garrafa | 2.8 |
| Cena 4: três respostas iniciais, dois ramos seguintes e empatia | 2.9–2.10 |
| Cena 5: redemoinho e desmaio | 2.11 |
| Cena 6: cenário caótico, bilhete, crina, grafite e garrafa vazia | 2.12 |
| Cena 7: narração, rua caótica, pegadas e exploração livre | 2.13 |
| POI 1 varal e POI 5 cavalo/porteira | 2.14 |
| POI 2 praça/cachimbo | 2.15 |
| POI 3 mural completo e pintura | 2.16 |
| POIs 4 e 7 bonde/bambuzal | 2.17 |
| POI 6 quitandeira e receita | 2.18 |
| Diário e página bônus Dia do Saci | 2.5 |
| Cena 8: ladeira, encontro e escolha adaptada a turnos | 2.19–2.20 |
| Captura, amizade, falas condicionais e recuperação incompleta | 2.21 |
| Áudio, opções, pausa, save, acabamento, créditos e build | 2.6, 2.21–2.24 |

## Validação técnica durante as implementações

Validar sintaxe dos scripts alterados e executar os testes pertinentes a cada entrega; ampliar para toda a suíte nos marcos de integração e no aceite final. Scripts que dependem de Autoloads devem ser compilados no contexto real do projeto/GUT; um `--check-only` isolado que não inicializa WorldState não substitui esse teste.

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Em ambiente CLI com diretórios de usuário restritos, apontar `XDG_DATA_HOME` e `XDG_CONFIG_HOME` para diretórios temporários graváveis, sem alterar `project.godot`. Registrar comando, resultado e limitações reais. Esta revisão de planejamento não marca nenhuma implementação nova como concluída.
