# Diálogos e sequências — Task 2.3

Abra `ui/dialogue_preview.tscn` e pressione **F6** para testar a conversa real com o Saci. A prévia usa estado/inventário próprios, sem alterar a sessão do jogo. E/Enter pula a espera inicial; durante a fala revela o texto, avança páginas ou confirma a resposta. Direcionais selecionam respostas; Esc cancela quando permitido. Ao terminar, Rever conversa permite repetir.

## Dados e execução

- `DialogueEntry`: ID, personagem/narrador, texto, páginas opcionais, destino, condições, efeitos e `cancel_allowed`.
- `DialogueChoiceData`: resposta, destino, condições e efeitos. Não há limite de duas respostas.
- `Stage01Narrative`: catálogo validável. Abrir o `.tres` não executa efeitos.
- `DialogueContext`: consulta `Stage01State`/`InventorySystem` e aplica comandos explícitos, sem dependência da árvore de cenas.
- `DialogueSession`: leitura, paginação, ramos e sinais `started`, `changed`, `finished(completed, reason)`.
- `DialogueView`: apresentação com a fonte/tema pixel existentes; paginação considera espaço e medidas reais da fonte. Listas de respostas rolam acompanhando o foco.

A Task 2.6 conecta a velocidade de `DialogueView` às preferências compartilhadas de acessibilidade. SOUND usa o canal SFX e `CutsceneStep.intense_effect` identifica tremor/flash cosmético que pode ser omitido com redução de efeitos, conservando duração, escolhas e lógica. Áudio, buses e contratos: [core/audio/README.md](../audio/README.md).

O catálogo da Fase 1 conserva suas **130 entradas e 37 escolhas**. IDs de nós devem ser únicos na sessão, inclusive entre catálogos: eles identificam os efeitos já executados.

`text` é paginado automaticamente. `pages` permite quebras editoriais; páginas muito longas também são subdivididas. Rubricas em `stage_direction` nunca aparecem como fala nem são interpretadas como código. A primeira confirmação revela o texto; somente outra confirmação pode avançar ou escolher. Eventos de teclado repetidos não confirmam decisões.

`event_id` e `effects` da fala são aplicados ao concluir sua última página ou escolher uma resposta. Cancelar uma leitura incompleta não a registra. Efeitos de uma resposta ocorrem somente quando ela é escolhida. Uma condição de destino é autorizada antes dos efeitos da resposta: isso permite entregar a peneira e entrar na fala de entrega, cuja condição exige que ela ainda não tivesse sido entregue. Condições de escolhas são reavaliadas ao confirmar.

## Condições

`condition_id` continua compatível com o catálogo anterior. `conditions: PackedStringArray` acrescenta requisitos cumulativos (todos precisam ser verdadeiros).

| Expressão | Consulta |
| --- | --- |
| `flag:nome` | Evento já registrado no estado. |
| `item:cachimbo_fumo` | Item presente no inventário. |
| `clue:clue_origem_saci` | Pista desbloqueada. |
| `read_clue:clue_origem_saci` | Pista efetivamente lida. |
| `!flag:nome` | Negação de uma condição conhecida. |

Também estão implementados todos os IDs do roteiro: `wall_or_tram_seen/unseen`, `sieve_claimed/not_claimed`, `three_read_clues`, `four_read_clues`, `friendship_ready`, `saci_empatico`, `painted_gorro/bambu/redemoinho`.

Condições adicionais podem ser registradas em `context.conditions[id]` com `Callable` sem argumentos que retorne `bool`. Condições desconhecidas falham fechadas, inclusive negadas. Uma decisão obrigatória sem nenhuma resposta disponível é recusada antes de bloquear o Player.

## Efeitos e identidade

`effects: PackedStringArray` executa comandos em ordem. Respostas também conservam `effect_id` para compatibilidade.

| Comando | Operação validada |
| --- | --- |
| `flag:nome` | `record_event()` |
| `clue:id` / `read_clue:id` | Desbloquear/registrar leitura, respeitando regras do estado. |
| `read_mural_panel:N` | Registrar o texto completo do quadro 1–6; os cinco informativos concluem uma única pista agregada. |
| `phase:id` | `advance_to()`, respeitando a sequência válida. |
| `claim_cachimbo_fumo`, `claim_garrafa_vazia`, `claim_fita_vermelha`, `claim_gorro_saci`, `claim_peneira` | Carregar o `.tres` existente e usar `grant_quest_item()`. |
| `mark_empathy` | `mark_empathy()` |
| `paint_gorro/bambu/redemoinho` | `paint_mural()` |

`context.effects[id]` aceita um callback sem argumentos que retorne `bool`. **`open_bottle` e `enter_climax` ainda precisam ser registrados pelos controladores das respectivas cenas nas próximas tasks.** A camada genérica não inventa viagem, avanço da história ou sucesso para um efeito ausente. Para viajar, o controlador valida/prepara o destino e realiza a troca depois de concluir o diálogo e liberar o bloqueio; não troca a cena dentro de um callback reentrante de concessão de item.

Na Task 2.7, `SantaTeresaMap` registra `enter_house` em **`context.transient_effects`**: consultas/intenção de viagem sem persistir uma flag de efeito. Elas são reavaliadas em cada tentativa, inclusive após cancelar uma fala. Não usar esse canal para concessões ou efeitos que precisem de identidade persistente. A viagem/avanço ocorre só ao concluir `city.enter`, por `SceneTransition.open_map()`; `can_open_map()` oferece pré-validação sem alterar estado. `open_bottle` e `enter_climax` continuam aguardando seus controladores.

Cada efeito recebe uma chave estável por fala/resposta/índice ou sequência/etapa. O contexto reserva a chave antes de emitir sinais e registra sua conclusão em `Stage01State` como `dialogue_effect:...`. Assim, voltar ao mapa ou reconstruir o contexto não repete efeitos. `grant_quest_item()` protege também a identidade dos itens após consumo/combinação. Novo Jogo limpa esses registros.

Efeitos já concluídos são preservados se uma etapa posterior falhar; não existe rollback de sinais, áudio ou mudanças externas. Uma tentativa posterior retoma os efeitos pendentes sem reaplicar os concluídos. Um callback que retorne `false` deve fazê-lo **antes** de modificar o mundo. Efeitos desconhecidos encerram a apresentação com `completed == false` e motivo, liberando seu bloqueio.

## HUD e interação

A [Task 2.5](../journal/README.md) integra as oito páginas do livro à mochila. As entradas `journal.*` correspondentes exigem a pista desbloqueada e só registram leitura ao concluir o texto. O mesmo ID lido no diário ou no diálogo conta uma vez. Os subregistros culturais do mural não viram pistas-base extras.

```gdscript
var catalog: Stage01Narrative = preload("res://core/dialogue/stage_01/stage_01_script.tres")
var started: bool = hud.start_dialogue(catalog, &"clean.sofa")
```

Ou configure `narrative` e `entry_id` no `DialogueInteractable` existente. Se `narrative` não estiver atribuído, ele conserva `speaker/message` e o aviso simples atual da quitandeira.

`GameplayHUD` mantém as confirmações de coleta/portas e o inventário existentes. Diálogos e sequências têm exclusividade modal: TAB, novas interações e avisos não os substituem. Pausa suspende o processamento; fades de viagem consomem input. O Player tem sua condição anterior de movimento restaurada ao terminar, cancelar, falhar ou remover o HUD, sem liberar um bloqueio que já existia. A apresentação também funciona sem Player em cenas `Control`.

## Coordenador de cutscenes

`CutsceneSequence` é um Resource com ID estável e `Array[CutsceneStep]`. `CutsceneCoordinator` recebe suas dependências explicitamente:

```gdscript
var accepted: bool = coordinator.start(sequence, hud, scene_root)
```

| `CutsceneStep.Kind` | Configuração |
| --- | --- |
| `WAIT` | Esperar `duration` segundos. |
| `ANIMATION` | `target_path` relativo a `scene_root`, `animation`, duração de apresentação. Aceita `AnimatedSprite2D` e `AnimationPlayer`. |
| `CAMERA` | `target_path` para `Camera2D`, `camera_position` global e duração de deslocamento. |
| `SOUND` | `sound: AudioStream`, duração positiva de reprodução. |
| `FADE` | `fade_alpha` e duração; usa a cortina persistente de `SceneTransition`. |
| `EFFECT` | `effect_id` executado pelo contexto do HUD. |
| `DIALOGUE` | `narrative` e `entry_id`; espera a conclusão real, inclusive decisões. |

E/Enter/Esc durante uma apresentação visual chama `request_skip()`: pula etapas visuais marcadas `skippable`, completando destinos de câmera/fade, mas **executa EFFECT e aguarda DIALOGUE**. Durante uma fala, as teclas pertencem à leitura e às escolhas. Use `cancel_allowed = false` para decisões obrigatórias. `cancel()` é uma interrupção externa da sequência, não o atalho de pular efeitos. Etapas visuais não puláveis preservam sua espera.

Animações devem conter apresentação, sem conceder itens ou decidir resultados por tracks de métodos. Mutações lógicas pertencem a EFFECT para continuar corretas ao pular. Duração positiva controla o intervalo de animação/som; duração zero permite aplicar câmera/fade imediatamente. Sequências não têm corrotinas de espera pendentes: o processamento é interrompido junto com o nó e respeita pausa.

O coordenador emite `started/finished`, reserva o fade contra outra sequência/viagem e restaura câmeras, animações anteriores, som, cortina e movimento ao concluir, cancelar, falhar ou perder suas dependências. Não cria outro Autoload. A sequência deve revelar a cortina (`FADE` para 0) antes de pedir uma resposta visível; a cortina de viagem continua na camada superior.

## Verificação e próximas entregas

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_dialogue_system.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

São **23 testes específicos**: condições, ramos reais, páginas/acentos, tecla única, efeitos/recompensas únicas, reentrada, reset, cancelamento, falhas, compatibilidade com coleta/quitandeira, prioridade, pausa, apresentação sem Player, áudio/animação/câmera/fade, remoção de dependências e geometria em quatro tamanhos de tela. A UI foi verificada por geometria e métricas de fonte em headless; a prévia por F6 permite a revisão visual no editor.

Resultado da entrega: **23/23 testes específicos e 154/154 testes do projeto aprovados**, sem erros, warnings ou Nodes órfãos. A prévia foi aberta também via CLI headless. O checklist e a atualização do design estão registrados na documentação da sprint e da fase.

Esta entrega fornece o sistema reutilizável. A **Task 2.4** já ligou o livro à cidade usando DialogueSession; controles, arte pendente e validação estão em [BOOK_INTRO.md](../../stages/stage_01_saci/BOOK_INTRO.md). Diário e encenação/distribuição narrativa nos mapas continuam nas tasks seguintes. Mapas, tiles, colisões, props, câmera do jogo e configuração inicial foram preservados.
