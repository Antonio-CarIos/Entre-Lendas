# Estado da Fase 1 — Task 2.2

`Stage01State` é lógica pura (`RefCounted`). A única instância da sessão é `WorldState.stage01`; mapas não a recriam. Ela guarda progresso, eventos já executados, identidade dos itens narrativos, pistas e resultado. O inventário continua em `WorldState.inventory`, e o registro moral continua em `WorldStateLogic`.

## Início e reset

`WorldState.start_new_game()` limpa inventário, decisões morais, coletas e progresso, depois ativa a fase em `book_intro`. O menu usa essa rotina sob o fade existente. `WorldState.reset()` limpa tudo e mantém a fase inativa, permitindo editar/testar mapas com F6 sem ativar o roteiro por acidente. Nenhum Autoload novo foi criado.

Persistência nesta entrega significa **entre mapas da mesma sessão**. Save/load em disco permanece na Task 2.22. Opções de áudio não são apagadas por Novo Jogo.

## Progressão válida

```text
book_intro → scene_2_sunset → scene_3_house_clean → scene_4_dialogue
    → scene_5_whirlwind → scene_6_house_chaos → scene_7_street_hub
    → scene_8_climax

scene_8_climax → incomplete_recovery → scene_7_street_hub → nova tentativa
scene_8_climax → resolve_ending(CAPTURE) → epilogue_capture → completed
scene_8_climax → resolve_ending(FRIENDSHIP) → epilogue_friendship → completed
```

`advance_to()` aceita somente a próxima fase permitida; recusa salto, repetição, regressão, ID desconhecido e entrada direta em epílogos. As travessias entre cidade, casa, quarto e quintal **não chamam** esse método. O coordenador de narrativa das próximas tasks fará as transições após seus eventos correspondentes.

## Consultas e mutações

| API | Contrato |
| --- | --- |
| `phase`, `active`, `objective` | Consultar o estado global e o objetivo derivado. |
| `mark_empathy()` | Registra uma vez a escolha empática, somente na conversa da Cena 4. |
| `paint_mural(symbol)` | Aceita gorro/bambu/redemoinho no hub e preserva a primeira escolha. |
| `record_event(id)` / `has_event(id)` | Narrações e efeitos únicos; IDs vazios e repetidos são recusados. `pipe_memory` identifica a memória do cachimbo. `bottle_opened` é reservado à transição para a Cena 4. |
| `mark_tram_seen()` / `read_mural_panel(1…6)` | Liberam a confiança da quitandeira no hub; cinco quadros informativos completam a pista agregada. |
| `unlock_clue(id)` / `mark_clue_read(id)` | Desbloquear não significa ler; somente pistas válidas e desbloqueadas podem ser lidas uma vez. |
| `get_unlocked_clues()` / `get_read_clues()` | Retornam cópias, evitando alterações externas no contador. |
| `can_grant_quest_item(id, inventory)` | Consulta o momento correto, a condição de entrega e a identidade já coletada. |
| `grant_quest_item(item, inventory)` | Uma única unidade lógica de cachimbo, garrafa, fita, gorro ou peneira. Continua recusando nova entrega após consumir ou combinar. Registra a identidade antes dos sinais de inventário, evitando reentrada. |
| `is_capture_prepared(inventory)` | Peneira com cruz **e** garrafa vazia. |
| `is_friendship_prepared(inventory, pipe_offered)` | Cachimbo possuído/já oferecido **e** três pistas-base lidas. Gorro não substitui investigação. |
| `resolve_ending(outcome, inventory, calm_progress, pipe_offered)` | Só no clímax; exige preparação e, na amizade, calma ≥100. Emite resultado uma vez; WorldState atualiza a moral. Não consome itens, pois reservas/consumo pertencem ao futuro controlador de batalha. |
| `get_map_visual_state(map_id)` | Consulta pura da aparência de casa/quarto/quintal/cidade; não altera a fase global. |

A peneira com cruz continua sendo criada pela receita existente em `InventorySystem.combine_items()`. Ela não é concedida diretamente como recompensa. A memória do cachimbo, guardar o cachimbo e ler a página são registros distintos.

As sete pistas-base são `clue_origem_saci`, `clue_poder_gorro_parede`, `clue_gorro_vermelho`, `clue_mural_origens`, `clue_inquerito_1917`, `clue_crina_cavalo` e `clue_bambu_rachado`. Ler as sete desbloqueia `clue_dia_do_saci_bonus`; a página bônus não aumenta `pistas_saci_lidas` para oito.

## Integração com os mapas

`HouseLevel.applied_story_state` recebe o estado derivado ao carregar o mapa e quando o progresso muda, com sinal `story_state_applied`. Cidade reaplica o entardecer ou o tom dessaturado existente a partir do estado global. Carregar outra cena não restaura a casa organizada.

As variantes caóticas atuais ainda contêm grupos vazios. Por isso, `story_variants_ready` permanece **false** nas cenas existentes: o estado narrativo é aplicado, mas os móveis/colisões desenhados não somem. A Task 2.12 preencherá as variantes e habilitará a troca conjunta de visibilidade e física. Epílogos e recuperação C também já têm estados derivados próprios; sua arte será implementada nas tasks correspondentes.

Pinturas de tiles, props e spawns foram preservados nesta entrega. A cidade respeita a progressão global quando a sessão narrativa está ativa; em F6 a aparência de edição continua funcionando. A suíte também detectou que a cena da cidade já havia perdido as configurações locais de câmera e gatilho da casa antes desta Task: foram restauradas apenas essas duas sobrescritas e marcadas as instâncias como editáveis. Um teste reempacota a cena e verifica que os limites 1024 × 576 e o gatilho 40 × 16 permanecem, evitando que se percam ao salvar novamente.

## Roteiro e próximos passos

O catálogo [stage_01_script.tres](../dialogue/stage_01/stage_01_script.tres) contém 130 entradas e 37 escolhas, com IDs de destino, condição/efeito e referências aos parágrafos do ODT. A [cobertura narrativa](../dialogue/stage_01/README.md) registra as adaptações e os trechos de origem.

`DialogueEntry`, `DialogueChoiceData` e `Stage01Narrative` são Resources de **dados**, sem execução automática. Abrir um Resource não entrega itens, desbloqueia páginas ou inicia diálogos. A Task 2.3 acrescentou [sessões, condições/efeitos e apresentação](../dialogue/README.md), além do coordenador de cutscenes; a [Task 2.5](../journal/README.md) conectou o diário à UI e ao mesmo registro de pistas; as Tasks 2.7–2.21 ligarão as interações e sequências aos mapas. A [Task 2.4](../../stages/stage_01_saci/BOOK_INTRO.md) já liga livro e cidade por `SceneTransition.open_map()`: registra `book_finished` e aplica `scene_2_sunset` sob preto, com spawn explícito e sem ativar pistas lidas ou conceder itens.

## Testes

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_stage_01_state_and_items.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Os 20 testes específicos cobrem reset completo, fases inválidas, efeitos/recompensas únicas, reentrada por sinal, leitura e bônus, mural/pintura, duas preparações, Final C recuperável, registro moral único, validação do grafo narrativo e ida/volta real cidade–casa preservando o estado.

Resultado original da Task 2.2: **20/20 testes específicos e 131/131 testes do projeto aprovados**, sem erros, warnings de scripts ou Nodes órfãos na suíte completa. A revisão do design em `.agents/context/07_stage_01_saci_design.md` e o checklist dessa entrega foram aplicados pelo usuário. A continuação está documentada em [core/dialogue/README.md](../dialogue/README.md).
