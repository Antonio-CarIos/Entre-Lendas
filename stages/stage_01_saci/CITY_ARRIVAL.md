# Primeira chegada a Santa Teresa — Task 2.7

**F5 → Novo Jogo → livro → Santa Teresa** agora continua com a narração das letras nos dedos, ladeira, silêncio e vento, seguida do tutorial WASD/setas/E/Tab/diário. O entardecer usa `#ffdfb3`. E/Enter revela e avança cada trecho; Esc/Tab não dispensam o tutorial por baixo da narração. Depois aparece **Objetivo: Entrar na casa**. A conclusão é registrada em `intro_city` somente ao confirmar o último trecho. Trocar de cena interrompendo o texto permite retomá-lo; uma chegada concluída não se repete.

F6 na cidade mantém o roteiro inativo e a aparência de edição. Para testar o fluxo narrativo completo, iniciar pelo menu. A casa organizada e seus objetos narrativos serão encenados na **Task 2.8**; os coletáveis de teste ainda serão retirados nessa tarefa.

## Interações iniciais por E

| Interação | Área no mapa | Aproximação verificada | Conteúdo |
| --- | --- | --- | --- |
| Bonde | `(176, 326)` | `(176, 352)`, olhando para cima | Bonde vazio, banco ainda quente. Não apresenta os jornais nem libera a pista de 1917 nesta fase. |
| Placa | `(624, 432)` | `(624, 464)`, olhando para cima | “Rua do Saci”, estranhamento do nome. |
| Janela | `(792, 338)` | `(792, 370)`, olhando para cima | Abre/fecha e risadinha abafada, descrita também em texto. |
| Porta da casa | Gatilho existente `(856, 340)` | Chegar por `(856, 368)` | Porta entreaberta, Sim/Ainda não. |

As três áreas ficam em `NarrativeInteractions`, layer de interação existente, mask 0, sem colisão sólida. Os marcadores `PointsOfInterest` foram mantidos; a área do bonde/janela fica na borda alcançável do objeto, sem exigir entrar na fachada ou atravessar o bonde. A placa visual é `YSortRoot/SharedProps/StreetSign`: madeira do atlas de produção `colonial_props_atlas.png`, recorte `(10, 940, 76, 24)` inspecionado, e texto na fonte pixel. Nenhum PNG novo foi gerado e nenhum concept foi usado como textura.

A janela usa seu sprite atual, com movimento cosmético das folhas. Redução de efeitos desliga esse movimento e mantém a descrição textual. A interação chama `AudioManager.play_positional("saci_laugh", ...)`; **a gravação continua ausente**, junto às pendências sonoras da Task 2.6/2.23. Não se declara risada audível ou mistura final entregue. Lista dos arquivos: `assets/audio/README.md`.

As descrições iniciais continuam coerentes durante visitas antes do caos e são desativadas nas fases posteriores, para as variantes investigativas das próximas tasks. A quitandeira conserva idle_down e interação por E; na chegada orienta para a casa. Não libera peneira, confiança do bonde, leitura ou itens antes da investigação. Não foi criada saída para a ladeira; o marcador norte e o perímetro existentes continuam reservados para a Task 2.19.

## Entrada, recusa e retorno

A porta existente aceita roteiro opcional em `SceneDoor.narrative/entry_id`, apresentado pelo mesmo HUD usado para as confirmações comuns. Na Cena 2, o controlador atribui `city.door`. **Ainda não** mostra a hesitação “Algo no seu peito diz que não há para onde voltar” e restaura movimento. Permanecer na área não repete a pergunta; E permite interagir de novo. Esc cancela sem autorizar a viagem.

**Sim** valida destino, Player e spawn e apresenta “A porta range. Dentro, o cheiro de fumo de corda e madeira velha. Você entra.” Somente depois de concluir esse texto, `SceneTransition.open_map()` realiza a viagem, registra `house_entered` e avança `scene_2_sunset → scene_3_house_clean` sob a tela preta. Chegada no `FromCity` existente `(320, 624)`, olhando para cima, com câmera e movimento restaurados ao terminar o fade.

`DialogueContext.transient_effects` recebe a validação `enter_house`: uma consulta reavaliada em cada tentativa, sem gravar um efeito persistente que pule validação após cancelar. A viagem continua fora do callback, ao terminar a fala. Destino/spawn inválido gera aviso utilizável, mantém a fase e permite tentar depois do reparo. Cancelar a fala de entrada também não avança progresso. Se o estado mudar durante o fade, o serviço recusa a troca e devolve o movimento anterior ao Player da origem.

Depois da primeira entrada, voltar pela saída habitual preserva inventário, leitura e fase, chega em `(856, 368)` fora do gatilho e não repete chegada/tutorial. A porta volta à confirmação comum “Deseja entrar na casa?”; revisitar não reinicia a Cena 2 nem avança a fase de novo.

## Preservação e validação

A comparação com o arquivo anterior confirmou **332 blocos de nós e 48 sub-recursos existentes idênticos**; foram acrescentados apenas a placa e três áreas de interação. TileMapLayers, atlas, colisões sólidas, props, spawns, limites da câmera, UIDs e sobrescritas editáveis foram mantidos. Térreo, quarto, quintal e `project.godot` não foram alterados nesta Task.

`tests/test_stage_01_progression.gd` cobre chegada única/interrompida, tutorial e objetivo, input real nas três áreas, recusa/hesitação, cancelamento depois do Sim, falhas/reparos de destino/spawn, viagem à casa, retorno seguro, preservação de inventário/leitura, condições por fase, F6 e redução de efeitos. O teste do livro agora espera a narração de chegada depois do fade, em vez de movimento livre antes dela. Testes anteriores de navegação e câmera continuam preservados.

```bash
env XDG_DATA_HOME=/tmp/entre_lendas_task27/data XDG_CONFIG_HOME=/tmp/entre_lendas_task27/config godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_stage_01_progression.gd -gexit
env XDG_DATA_HOME=/tmp/entre_lendas_task27/data XDG_CONFIG_HOME=/tmp/entre_lendas_task27/config godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Validação de 19/11/2026: **12/12 testes específicos e 208/208 no projeto**, 9.320 asserts, sem erros ou warnings na suíte completa, Godot 4.7.2 / GUT 9.6.1. A abertura da cena inicial por CLI também passou.

A revisão gráfica nativa e a escuta com a gravação final continuam no acabamento da Task 2.23. Próxima implementação: **Task 2.8 — Casa organizada e memória do cachimbo**.
