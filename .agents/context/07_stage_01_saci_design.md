# Fase 1 — O Saci-Pererê: design e contrato de implementação

> Revisão funcional da Task 2.7, 19/11/2026. Fonte narrativa: `Fase 1 - Saci.odt`, adaptado para RPG top-down inspirado em Undertale, EarthBound, Mother 3 e Omori. A ordem das entregas está em `.agents/tasks/sprint_02_stage_01.md`. Orientações mais recentes do usuário prevalecem.

## 1. Escopo e situação atual

A fase começa no menu do jogo, passa pela introdução do livro da colega, pela exploração de Santa Teresa e da casa, pela investigação das travessuras e pelo confronto narrativo com o Saci. Captura e amizade encerram o capítulo com epílogo e créditos; o desfecho incompleto permite investigar e tentar novamente.

Já implementados: menu/Novo Jogo (Task 2.1), fundação de estado narrativo e catálogo completo de textos (Task 2.2), sistema reutilizável de diálogos e coordenação de cutscenes (Task 2.3), introdução do livro por teclado ligada à cidade (Task 2.4), diário por teclado e pistas únicas (Task 2.5), controle de áudio/acessibilidade (Task 2.6, arquivos sonoros e mistura final pendentes), chegada narrativa e primeira entrada na casa (Task 2.7), Player, inventário/combinação, mapas conectados e fade. O catálogo não executa diálogos sozinho: o HUD abre uma DialogueSession e um DialogueContext valida condições/efeitos; CutsceneCoordinator coordena apresentação, sem Player obrigatório. Distribuição narrativa dos itens e desbloqueios nos POIs, encenação de cada cena, puzzles, batalha e epílogos serão ligados ao jogo nas próximas tasks. A introdução usa os textos `book.open → book.saci → book.light`, preserva a composição recebida e chega à cidade por E/Enter ou skip por Esc. `SceneTransition.open_map()` registra `book_finished`, aplica `scene_2_sunset` e posiciona no `PlayerEntrySpawn` sob preto, antes de liberar movimento. Cinco imagens de páginas ainda faltam; a alternativa textual não conclui a arte final da Task 2.23. Auditoria e limites gráficos em `stages/stage_01_saci/BOOK_INTRO.md`. A prévia isolada `ui/dialogue_preview.tscn` permite testar por F6 sem alterar o estado real.

As mecânicas de primeira pessoa, parkour, pulo/plataformas, barra de Aproximação, esquiva obrigatória na exploração, captura por timing/força e arrastar garrafa foram descartadas. O confronto será por turnos, com escolhas e itens. Não criar uma segunda versão de inventário, Player ou WorldState.

## 2. Cenas e mapas que devem ser preservados

| Cena | Papel |
| --- | --- |
| `ui/main_menu.tscn` | Entrada por F5, capa original `assets/art/menu/menu_cover.jpeg`, Novo Jogo, Opções, Créditos e Sair. |
| `stages/stage_01_saci/scene_01_book_intro.tscn` | Livro da colega: teclado, leitura e saída funcional na Task 2.4; composição preservada e cinco páginas de arte ainda pendentes. |
| `stages/stage_01_saci/santa_teresa_map.tscn` | Bairro atual baseado em concept_street, **1024 × 576 px (32 × 18 tiles de 32 px)**. Cena 2 e hub da Cena 7. |
| `stages/stage_01_saci/house_interior.tscn` | Térreo com sala, cozinha e escada; Cenas 3–6 e retorno dos epílogos. |
| `stages/stage_01_saci/house_bedroom.tscn` | Quarto separado, conectado pela escada. |
| `stages/stage_01_saci/house_backyard.tscn` | Quintal separado, acessado pela cozinha: varal, cavalo, galinhas e porteira. |
| `stages/stage_01_saci/saci_climax.tscn` | **Planejada na Task 2.19:** ladeira e terraço conectados à saída norte do bairro. |
| `stages/stage_01_saci/saci_turn_combat.tscn` | **Planejada na Task 2.20:** tela de batalha por turnos. |

A planta anterior de 1920 × 2240 e suas coordenadas não são mais instruções de montagem. Não reconstruir o bairro para recuperá-las. Usar os TileMapLayers, grupos, colisões e marcadores reais dos mapas; ajustar interações ao desenho manual. O portão/muretas removidos diante da casa na cidade não devem ser recriados. O placeholder `scene_02_santa_teresa_placeholder.tscn` é um nó vazio recebido, sem participação no fluxo de Novo Jogo.

`HouseLevel` em `house_level.gd` coordena portas/escadas existentes. O serviço persistente `WorldState.scene_transition` oferece `travel_to()` para mapas com Player/spawn, `open_scene()` para telas sem Player e `open_map()` para entrar em mapa a partir de Control, com fase/evento/spawn explícitos sob fade. Não inventar um `house_interior.gd` já existente nem duplicar o serviço de fade.

## 3. Estado da sessão e API real

`WorldState.stage01` é uma instância única de `Stage01State` (`core/stages/stage_01_state.gd`, `RefCounted`). O inventário continua em `WorldState.inventory`; o registro moral continua em `WorldStateLogic`.

- `WorldState.start_new_game()`: limpa sessão e ativa `book_intro`; chamado pelo menu sob o fade.
- `WorldState.reset()`: limpa tudo e deixa o roteiro inativo, preservando o uso dos mapas por F6 para edição/testes.
- `stage01.advance_to(next_phase)`: avança somente pela transição narrativa válida. Carregar um mapa ou atravessar uma porta não avança nem regride a história.
- `stage01.changed` e `phase_changed`: notificam os consumidores; mapas reaplicam a aparência sem alterar a fase global.
- `stage01.resolve_ending(...)`: valida clímax/preparação, registra o resultado uma vez e emite `ending_resolved`; WorldState chama o registro moral existente.
- A API moral correta é `WorldState.register_entity_outcome(&"saci", WorldStateLogic.Outcome.CAPTURE/FRIENDSHIP)`. **Não existe `WorldState.Choice`.** Para resolver a Fase 1, usar `stage01.resolve_ending()` e evitar registros paralelos divergentes.

Fases válidas:

```text
book_intro → scene_2_sunset → scene_3_house_clean → scene_4_dialogue
→ scene_5_whirlwind → scene_6_house_chaos → scene_7_street_hub → scene_8_climax

scene_8_climax → incomplete_recovery → scene_7_street_hub → nova tentativa
scene_8_climax → epilogue_capture OU epilogue_friendship → completed
```

Epílogos só são acessíveis pela resolução validada, não por `advance_to()` diretamente. Saltos, regressões, repetição da fase e IDs desconhecidos retornam false. `climax_attempts` conta entradas reais no clímax.

Consultas de progresso: `phase`, `active`, `objective`, `saci_empatico`, `muro_pintado`, `muro_simbolo_escolhido`, `viu_muro_ou_bonde`, `peneira_entregue`, `gorro_obtido`, `cachimbo_memoria`, `garrafa_aberta`, `pistas_saci_lidas` e `final_outcome`. Alterar por métodos, não atribuir flags por fora.

- `mark_empathy()` registra a escolha da Cena 4 uma única vez.
- `paint_mural(gorro/bambu/redemoinho)` preserva a primeira pintura no hub.
- `record_event(id)` registra narrações vistas e efeitos únicos; `has_event(id)` consulta. `pipe_memory` identifica a memória do cachimbo; `bottle_opened` é reservado à passagem para a Cena 4.
- `mark_tram_seen()` e `read_mural_panel(1…6)` registram a investigação apropriada no hub.
- Coleções retornadas pelos getters são cópias; não manter um contador de pistas paralelo.

A persistência da Task 2.2 é entre mapas da **mesma sessão**. Save/load em disco pertence à Task 2.22. Novo Jogo não apaga preferências de áudio.

## 4. Aparência derivada por mapa

`get_map_visual_state(map_id)` é consulta pura para `house_interior`, `house_bedroom`, `house_backyard` e `santa_teresa_map`.

- Antes do caos: casa/quarto/quintal recebem `house_clean`; cidade recebe `scene_2_sunset`.
- Cenas 6–8: interiores/quintal recebem `house_chaos`; cidade recebe `scene_7_street_hub`.
- Recuperação incompleta: `incomplete_recovery`, preservando investigação, leitura, itens e possibilidade de concluir.
- Após resolução A/B, inclusive em `completed`: `epilogue_capture` ou `epilogue_friendship` permanece associado ao resultado.

`HouseLevel.applied_story_state` e `story_state_applied` expõem essa aplicação em cada carregamento/mudança. A cidade já respeita entardecer `#ffdfb3` e hub `#9eaab8` quando a sessão está ativa; F6 conserva a aparência de edição.

Os grupos caóticos atuais ainda não contêm toda a arte. **Não esconder os móveis desenhados para exibir um grupo vazio.** `story_variants_ready` fica false até a Task 2.12 completar as variantes; ao habilitá-la, visibilidade e presença física devem mudar juntas. As colisões das saídas precisam continuar alcançáveis em todos os estados. O bloqueio por crina jamais pode aprisionar quem já está no quarto.

## 5. Roteiro completo em Resources

`core/dialogue/stage_01/stage_01_script.tres` contém **130 entradas e 37 escolhas**: oito cenas, todos os ramos principais, sete POIs, diário e três desfechos. `DialogueEntry`, `DialogueChoiceData` e `Stage01Narrative` são Resources de dados. DialogueContext avalia condições de flags/itens/pistas e executa efeitos explícitos; carregar o catálogo não os executa. DialogueSession separa revelar, avançar e decidir, com efeitos únicos por fala/resposta/etapa. Viagens e eventos específicos (`enter_house`, `open_bottle`, `enter_climax`) exigem callbacks registrados pelo controlador da respectiva cena; IDs desconhecidos falham sem simular sucesso. API e contrato do coordenador: `core/dialogue/README.md`.

`text` é fala/narração exibível. `stage_direction` contém rubricas de câmera, animação e adaptação, separadas para não aparecerem como texto do jogo. `source_paragraphs` referencia os parágrafos do ODT, incluindo títulos/tabelas, a partir de 1. A cobertura e as adaptações estão em `core/dialogue/stage_01/README.md`.

| Cena | Conteúdo que deve ser encenado |
| --- | --- |
| 1 — Livro | Leitura de Lendas do Brasil, últimas páginas sobre Saci, brilho, letras caindo e transporte. Cutscene da colega reutilizada, leitura por teclado e skip até a cidade implementados; completar arte/revisão gráfica na Task 2.23. |
| 2 — Rua | Implementada na Task 2.7: chegada/tutorial únicos após o fade, objetivo no HUD, bonde com banco quente, placa do atlas existente, janela com movimento opcional e descrição da risadinha. Porta entreaberta Sim/Ainda não; concluir texto de fumo/madeira entra na casa organizada sob fade. Gravação da risadinha ainda pendente. |
| 3 — Casa organizada | Narração de entrada, sofá/poeira, relógio ao contrário, leite azedo/data atual, cama/crina no quarto. Memória completa do cachimbo: bambu, sete anos, 77 anos, cogumelo, Saci-Cererê. Guardar/Colocar de volta. Garrafa: Abrir/Deixar, suspense sem loop automático que prenda o jogador. |
| 4 — Saci | Aparição da fumaça, perna única/Toc e abertura. Primeira escolha: curioso / quem é você / ficou preso muito tempo (empatia). Parte comum sobre ouvir o mundo mudar e o livro contar errado. Segunda escolha: sua versão / planos. Despedida e pista do vento que faz curva. |
| 5 — Redemoinho | Giro, saída pela porta, vento crescente, tremor opcional, vinheta e desmaio. Aplicar caos sob tela preta e revelar a protagonista em spawn seguro. |
| 6 — Despertar | Almofada no lustre, relógio caótico, leite/carinha, quarto bloqueado por crina, bilhete na estante, garrafa vazia caída e grafite Quem perde o gorro perde o rumo. Saída e objetivo Descobrir o que aconteceu. |
| 7 — Investigação | Rua caótica, pegadas e sete POIs em ordem livre, com retorno à casa/quintal sem repetir efeitos. |
| 8 — Clímax | Aviso de preparação, subida, terraço/furacão, diálogo e encontro por turnos. A/B concluem o capítulo; C devolve à investigação. |

Preservar humor, suspense e falas longas. As influências culturais são apresentadas como versões e interpretações da lenda, sem reduzir a origem a uma única explicação. Corrigir o título antigo de “três quadrinhos” para seis quadros e remover o ramo duplicado da quitandeira. A enumeração do varal contém cinco grupos, embora anuncie seis; não inventar um requisito extra.

## 6. Itens narrativos e prevenção de duplicação

Os seis `.tres` existentes continuam em `core/inventory/items/stage_01/`. Não refazer a combinação implementada.

| ID | Origem final e regra |
| --- | --- |
| `cachimbo_fumo` | Casa organizada OU banco no hub. Uma única identidade, mesmo após oferecer/consumir; memória, coleta e leitura são registros distintos. |
| `garrafa_vazia` | Chão perto da estante, somente depois de abrir a garrafa e despertar. |
| `fita_vermelha` | Porteira do quintal durante investigação. Não abre saída para um mapa inexistente. |
| `gorro_saci` | Puzzle do varal; um verdadeiro parado, morno e com cheiro de fumo, seis falsos balançando. |
| `peneira` | Entrega única da quitandeira depois de ver mural OU bonde. Não entregar de novo após combinar. |
| `peneira_cruz` | Somente pela combinação de peneira + fita vermelha no inventário. |

`can_grant_quest_item()`/`grant_quest_item()` validam fase, condição e identidade já recebida. Inventário não deve publicar um estado que permita uma segunda entrega reentrante. Itens de teste ainda posicionados na casa serão retirados do fluxo narrativo na Task 2.8; não ativá-los como distribuição final.

Manter inventário inicial vazio, sem limite de slots que descarte recursos essenciais; ícones limpos na UI e brilho apenas no mapa. Preservar navegação por teclado, fundo full-screen, opções Examinar/Ler/Combinar e confirmação da receita. Não usar “item [nome]” de modo redundante.

## 7. Diário: desbloquear não é ler

| ID da pista-base | Fonte |
| --- | --- |
| `clue_origem_saci` | Memória do cachimbo, na casa ou praça. |
| `clue_poder_gorro_parede` | Grafite da casa caótica. |
| `clue_gorro_vermelho` | Puzzle do varal no quintal. |
| `clue_mural_origens` | Leitura dos cinco quadros informativos; conta uma pista, não cinco. |
| `clue_inquerito_1917` | Jornais no bonde. |
| `clue_crina_cavalo` | Cavalo no quintal. |
| `clue_bambu_rachado` | Gomo rachado no bambuzal. |

`unlock_clue(id)` só disponibiliza a página. `mark_clue_read(id)` registra o término da apresentação/leitura da entrada, sem repetir contagem. `pistas_saci_lidas` é derivado dos IDs únicos lidos; descrições genéricas e páginas de teste não geram pistas extras.

Ler as sete pistas-base desbloqueia `clue_dia_do_saci_bonus` (Dia do Saci, 31 de outubro). Ler essa página não eleva o contador para oito. Não desbloqueá-la diretamente antes das sete. A Task 2.5 integrou `WorldState.journal` e oito Resources em `core/journal/` ao inventário existente. Tab abre a mochila; J alterna o diário, também acessível por ↑ no topo, ←/→ e E/Enter. NOVA/LIDA e o contador usam o mesmo Stage01State. Examinar não conta leitura; E/Enter após o último trecho medido com a fonte confirma o texto integral. Esc/Tab/troca de seção interrompem sem marcar. Os oito `journal.*` correspondentes têm condição de desbloqueio e efeito ao concluir; `mural.panel_1`…`mural.panel_6` registram somente textos terminados, com uma pista agregada após 1–5. Trocar de cena/HUD preserva a sessão, Novo Jogo limpa; save em disco permanece em 2.22. As próximas tasks ainda ligarão os POIs aos desbloqueios, sem antecipar recompensas. Contratos e 16 testes específicos: `core/journal/README.md`.

## 8. Sete pontos de interesse

1. **Varal/quintal:** roupas pingando sem vento; meias desencontradas, camisa invertida, vestido/bilhete, poste e sete gorros. Pegar/Deixar o verdadeiro, micro-redemoinho e silêncio de três segundos com retorno musical mais grave. Deixar permite voltar.
2. **Praça/banco:** cachimbo e fumo como segunda oportunidade; não repetir memória nem recompensar outro cachimbo se já recebeu na casa.
3. **Mural:** quadro 1 menino da mata; 2 bambu/sete anos; 3 capoeira/influências africanas em versões da lenda; 4 gorro/influências europeias; 5 vento/travessuras; 6 espaço aberto e pincel. Qualquer quadro visto dá confiança à quitandeira; a pista agregada exige ler 1–5. Pintar/Deixar em branco; Gorro/Bambu/Redemoinho preservado e comentado no final. Sincronizar brilho do quadro 2 e bambuzal.
4. **Bonde:** jornais do inquérito de 1917 e página sobre relatos enviados a Monteiro Lobato; também libera confiança da quitandeira sem exigir o mural.
5. **Cavalo/porteira:** crina trançada e cansaço, página sobre travessuras e fita vermelha. Preservar cavalo comendo e duas galinhas caminhando/comendo.
6. **Quitanda:** NPC parada em idle_down atrás do balcão, interação por E, ramos sobre ter visto o Saci e como pará-lo; receita da avó e peneira única após a condição. Antes da condição, orientar investigação. Repetir conversa não dá outra peneira.
7. **Bambuzal:** gomo rachado, mãozinha, vento/risadinha e página de nascimento; passagem acessível entre as moitas existentes.

## 9. Clímax e batalha por turnos

A saída norte do bairro será ligada à nova ladeira/terraço (Task 2.19). O marcador de furacão fora do mapa é só reserva, não uma arena pronta. Não criar desafio de sobrevivência para chegar ao Saci.

Preparação de captura: `is_capture_prepared(inventory)` exige peneira com cruz + garrafa vazia. Preparação pacífica: `is_friendship_prepared(inventory, pipe_offered)` exige cachimbo possuído/já oferecido + três pistas-base lidas. Se nenhuma estiver satisfeita, perguntar **“O vento diz que ainda tem coisa para ver. Subir assim mesmo?”**, Subir/Voltar. Insistir é permitido.

Na borda do furacão, E inicia a transição para batalha. A máquina de estados da Task 2.20 fará abertura → turno da protagonista → resposta do Saci → resolução, com menus por teclado:

- **Interagir/Brincar:** piada/adivinha +25; brincar +25; contar origem +35 com três pistas lidas; elogiar +15 ou +25 se pintou. Ganho único por ação no encontro, sem repetir para acumular infinitamente.
- **Item:** cachimbo oferecido +40 de calma; devolver gorro leva a 100, mas não substitui preparação pacífica. Itens de captura respeitam a sequência abaixo.
- **Confrontar:** com peneira contendo o Saci, muda para Segurar Peneira. Sem recurso apropriado, resposta narrativa sem avanço ou consumo inválido.
- **Amizade/Poupar:** disponível para resolver com calma ≥100 e preparação pacífica válida.

Captura: peneira com cruz 0→1; segurar peneira OU mostrar gorro 1→2; garrafa 2→3. O gorro é facilitador opcional. O controlador de combate valida a etapa final e chama `resolve_ending()`; a fundação de estado não simula a batalha.

Reservar recursos durante o encontro e consumi-los somente ao confirmar A/B. Retorno C/falha recuperável libera reservas sem duplicar/perder itens. Mudar para amizade desfaz a contenção temporária e libera a reserva da captura. Respostas do Saci podem embaralhar opções por um turno ou alterar visual do texto, mantendo seleção pelo ID, legibilidade e opção de reduzir efeitos.

**Diretriz do usuário:** usar um **quadrado vermelho como representação provisória do Saci em batalha**, com ponto de substituição pelo asset final. Essa exceção não exige gerar sprites de combate agora e não substitui a arte de exploração existente.

## 10. Finais e recuperação

- **A/Captura:** o controlador conclui os três estágios, valida os recursos e resolve CAPTURE. Falas da peneira/rolha, garrafa pesada, casa/rua organizadas, desenhos desbotados, paleta saturada e silêncio. Com quatro pistas-base lidas, mostrar “Você sabia o que ele era. Foi assim mesmo?”. Moral -1 para Saci, uma única vez.
- **B/Amizade:** calma 100 e preparação pacífica; o controlador resolve FRIENDSHIP. Falas condicionais de cachimbo, gorro, empatia e símbolo pintado; promessa de arrumar e brincar amanhã, pétalas, flores no muro e risada alegre. Moral +1 para Saci, uma única vez.
- **C/Incompleto:** após três turnos improdutivos com ambas as preparações ausentes, Saci se entedia. Voltar a uma chegada segura, casa quase organizada/relógio invertido, mantendo investigação, itens, leitura e flags. Não registrar moral nem concluir o capítulo; permitir nova tentativa. O contador de turnos pertence ao controlador futuro; o estado já aceita a transição de recuperação.

A/B preservam o resultado em `completed`, seguem para conclusão/créditos e permitem voltar ao menu/Novo Jogo, sem depender de uma Fase 2 inexistente. Registro moral e consumo não podem se repetir ao carregar o epílogo.

## 11. Referências de posição atuais

| Referência no bairro | Posição atual |
| --- | --- |
| `SpawnPoints/PlayerEntrySpawn` | (512, 448), olhando para cima. |
| `SpawnPoints/FromHouseInterior` | (856, 368), olhando para baixo, fora do gatilho. |
| `Transitions/EnterHouse` | Centro (856, 340), área 40 × 16; fachada/porta em (856, 336). |
| Banco / bonde | (512, 384) / ponto de interesse (176, 304). |
| Muro / marcadores dos quadros | Ponto de interesse (800, 160); usar Panel01…Panel06 existentes. |
| Quitanda / quitandeira | Balcão (144, 536), NPC (144, 528), aproximação frontal (144, 560). |
| Passagem do bambuzal | (880, 544). |
| Saída norte reservada | (512, 32); conexão do clímax ainda pendente. |

Consultar `stages/stage_01_saci/SANTA_TERESA.md` e o README dos mapas para portas, spawns e detalhes de edição. Se o usuário mover um objeto, prevalece o desenho atual: reposicionar seu componente e marcador sem refazer o cenário.

## 12. Validação e referências técnicas

`tests/test_stage_01_state_and_items.gd` cobre a fundação, o catálogo e a ida/volta real entre mapas. Os testes de navegação, câmera, inventário, Player e menu continuam obrigatórios. A correção das sobrescritas editáveis da cidade inclui teste de reempacotamento para não perder limites de câmera e área da porta ao salvar novamente.

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Detalhes da API: `core/stages/README.md`. Rastreabilidade do ODT: `core/dialogue/stage_01/README.md`. O encerramento da Task 2.2 não significa que as próximas sequências já estejam encenadas; implementar uma Task por pedido, com validação a cada entrega.

## 13. Áudio e acessibilidade — controle funcional da Task 2.6

`AudioManager` é o único serviço de áudio; `default_bus_layout.tres` define Master/Music/SFX. `AudioDirector` é a lógica pura de uma BGM com fade, sem sobrepor músicas. Menu, livro, mapas e fases selecionam contexto; SFX e áudio posicional usam SFX. `MenuPreferences` compartilha volumes/mudos, velocidade do texto 15–120 caracteres/s e redução de tremor/flashes, persistidos fora do progresso. Opções rolam por foco de teclado. Livro e CutsceneStep.intense_effect preservam texto/duração/lógica ao omitir apresentação intensa.

Concessão narrativa única do gorro dispara silêncio de 3.000.000 µs, usando tempo monotônico e processamento mesmo com mapa pausado. Trocar de mapa durante o efeito atualiza a faixa de retorno; fim usa pitch 0.85 e conserva volumes/mudos atuais. Reset/Novo Jogo/menu cancelam o efeito. O puzzle e suas pistas textuais serão ligados na Task 2.14.

Validação funcional: 12/12 testes específicos, 196/196 no projeto, sem erros ou warnings. **Áudio final pendente:** pasta sem gravações, catálogo com 24 streams ausentes e origem/licença ainda não fornecidas; mistura e revisão gráfica nativa não aprovadas. Não contar infraestrutura como trilha entregue. Inventário de faltas: `assets/audio/README.md`; API e testes: `core/audio/README.md`.

## 14. Chegada e primeira entrada — Task 2.7

`SantaTeresaMap` coordena a Cena 2 sem reconstruir o mapa. Só na cena atual e após concluir o fade, `city.arrival` apresenta narração/tutorial, sem permitir que Esc/Tab abram outro modal por baixo. `intro_city` é registrado depois do último trecho; revisitas não repetem a chegada. HUD mostra objetivo na exploração. `NarrativeInteractions` acrescenta áreas de bonde, placa e janela; permanecem independentes dos desbloqueios investigativos e são desativadas após o caos. Quitandeira inicial orienta para a casa, sem entregar peneira. A ladeira continua sem acesso até 2.19.

SceneDoor aceita roteiro opcional. `city.door` oferece Sim/Ainda não; recusar mostra hesitação e restaura controle. `enter_house` é consulta transitória em DialogueContext.transient_effects, revalidada em cada tentativa. Só concluir `city.enter` pede SceneTransition.open_map para house_interior/FromCity, avança scene_3_house_clean e registra house_entered sob preto. Destino/spawn inválidos não avançam e permitem nova tentativa; interrupção do fade restaura movimento anterior. Retorno pela porta habitual mantém inventário, leitura e fase, usa FromHouseInterior seguro e não repete introdução.

12/12 testes específicos e 208/208 no projeto, sem erros ou warnings. Comparação confirmou os 332 blocos de nós/48 sub-recursos anteriores da cidade preservados; mapas da casa e project.godot intactos. A placa usa madeira do atlas de produção e fonte pixel; nenhuma arte nova foi gerada. Risadinha posicional tem integração/texto, mas a gravação e a revisão gráfica/sonora final continuam pendentes. API, posições e aceite funcional: `stages/stage_01_saci/CITY_ARRIVAL.md`. Próxima Task: 2.8.

## 15. Casa organizada e memória — Task 2.8

HouseInvestigation estende HouseLevel no térreo/quarto sem refazer mapas. Narração única só após o fade; sofá/relógio invertido/leite azedo/cama com crina por E. NarrativePipe usa a mesma identidade narrativa para casa e banco: memória, desbloqueio, leitura e concessão separados. Recusa permite coleta posterior; coleta/oferta/consumo impede reaparecer. HouseInvestigationScript duplica o catálogo para mostrar Origem do Saci antes da pergunta sem alterar o Resource global.

Garrafa fechada é prop/diálogo, sem ItemData de garrafa vazia. Deixar apresenta Tec/vibração/piscar/risada e devolve controle até outra interação; redução de efeitos conserva texto e lógica. Abrir entrega scene_4_dialogue uma vez ao concluir Pop e emite bottle_opening_completed, integração para 2.10, sem antecipar a conversa. Nenhuma garrafa vazia/fita/peneira é distribuída no térreo organizado. Os quatro pickups antigos estão em tests/fixtures/inventory_mechanics_lab.tscn, preservando testes de coleta/combinação/UI.

14/14 testes específicos e 222/222 no projeto, 9.475 asserts, sem erros ou warnings, aprovam fluxo, página interrompida, recusa/revisita, duas localizações, consumo, garrafa e escada. Caminhos usam os pés reais. Todos os blocos anteriores dos mapas permanecem; cidade/quintal/configurações intactos. PlayerWakeUpSpawn antigo (320, 384) está dentro de parede, reservado à correção no despertar em 2.12; SaciBottleSpawn deve ser validado na aparição em 2.10. Gravações e revisão gráfica/sonora final continuam pendentes. Detalhes, posições e suíte completa: stages/stage_01_saci/HOUSE_INVESTIGATION.md. Próxima Task: 2.9.

## 16. Auditoria parcial do Saci — Task 2.9

SaciActor e SaciVisuals em entities/folklore/saci separam one_leg/whirlwind. Somente o redemoinho possui arte local: 24 PNGs em tamanhos nativos 80×80, 64×80 e 96×96, normalizados por AtlasTexture/margens para 64×80 lógico, sem reamostragem nem cortes visíveis. Idle estático e walk de cinco frames nas quatro direções a 8 FPS. O ator começa oculto e sem colisão, permite base física opcional e informa visual_unavailable em vez de substituir arte ausente. Prévia isolada saci_visual_preview.tscn por F6, E alterna poses/caminhada; nenhum avanço de história.

A forma de uma perna e suas ações não existem; character_base/body também está ausente. A consulta PixelLab só encontrou arte de batalha distinta, não integrada. A Task 2.9 permanece parcial e 2.10 não foi antecipada. Catálogo de arquivos faltantes por Task, medidas/frames e briefings para navegador: stages/stage_01_saci/ART_REQUIREMENTS.md. Não gerar nova anatomia sem restaurar/inspecionar a base exigida pela skill e não usar conceitos/capa como sprites. Mapas, Player, PNGs e configurações preservados. Foi necessário restaurar metadados de leitura/tutorial/rastreabilidade que já faltavam no roteiro; falas/escolhas/UIDs preservados e gravação/recarga coberta por teste. Validação: 11/11 testes específicos e 234/234 no projeto, 9.935 asserts, sem erros ou warnings. A aprovação não inclui os assets ausentes.
