# Casa organizada — Task 2.8

A Cena 3 usa o térreo e o quarto já desenhados. `HouseInvestigation` estende `HouseLevel`: mantém portas, escadas, câmera, spawn e a consulta ao estado global. Não habilita as variantes caóticas ainda vazias. A chegada `clean.arrival` começa só na cena atual, depois do fade, e registra `intro_house_clean` depois da última confirmação. Revisitas não a repetem. F6 com progresso inativo permite editar/explorar sem iniciar nem conceder eventos narrativos; use **F5 → Novo Jogo** para testar a história.

## Interações por teclado

Aproxime-se olhando para o objeto e pressione **E**. Setas escolhem respostas; **E/Enter** revelam/avançam/confirmam em passos separados. O Player fica bloqueado durante o diálogo. Esc cancela as inspeções; chegada e trecho da abertura já confirmada exigem concluir o texto. Tab abre o inventário durante a exploração e **Tab → J** abre o diário.

| Objeto | Posição / aproximação livre | Conteúdo |
| --- | --- | --- |
| Sofá | `(416, 376)` / `(416, 416)`, cima | Almofada marcada e poeira. |
| Relógio | `(496, 304)` / `(496, 390)`, cima | Ponteiros animados para trás. Área de interação abaixo da parede. |
| Leite na mesa existente | Filho `Table/Milk` / `(192, 540)`, esquerda | Leite azedo, data de hoje. A lateral evita as cadeiras. |
| Cachimbo | `(380, 378)` / `(380, 410)`, cima | Memória, página e Sim/Colocar de volta. |
| Garrafa fechada | `(560, 352)` / `(560, 394)`, cima | Abrir/Deixar, vidro escuro, cera e fumaça. |
| Cama do quarto | Cama existente `(128, 256)` / `(128, 288)`, cima | Fio de crina trançado no travesseiro. |

Os pontos de inspeção são componentes `DialogueInteractable` na Layer 3 (`collision_layer = 4`), Mask 0. Sofá e objetos pequenos usam recortes do atlas de produção `house_furniture_atlas.png`, inspecionado antes da seleção; o sofá usa `(448, 1920, 96, 32)`, não uma cama/banco. A colisão nova do sofá cobre sua base e seu sprite termina no pivô. Relógio, cera, fumaça e fio de crina usam nós nativos simples, sem gerar bitmap nem recortar conceitos. Os objetos pequenos seguem a escala visual do OilLamp. Não foi alterada a pintura de qualquer TileMapLayer nem a colisão de móveis existentes.

## Memória, leitura e posse

`HouseInvestigationScript.create()` duplica o catálogo Resource; não altera os textos ou ligações globais de `stage_01_script.tres`. A memória contém o bambu, sete anos, setenta e sete anos, cogumelo e Saci-Cererê, com falas atribuídas ao Saci. Ao terminar a memória, desbloqueia `clue_origem_saci` e mostra sua página antes de perguntar sobre guardar o cachimbo. Somente concluir a página registra leitura; cancelar deixa a página NOVA no diário.

`pipe_memory`, desbloqueio/leitura e concessão de `cachimbo_fumo` são registros distintos. Recusar ou cancelar não concede o objeto. Nova interação não repete a memória já vista; oferece a página ainda não lida ou a coleta. Releituras não somam pistas. O componente reutilizável `NarrativePipe` tem `at_bench`: casa na Cena 3, banco no hub/recuperação. Ambos consultam `Stage01State.is_quest_item_claimed`, não apenas a presença no inventário. Depois de guardar/oferecer/consumir, nenhuma localização pode conceder outra unidade. A colocação narrativa no banco continua na Task 2.15; os testes instanciam essa segunda oportunidade para validar a identidade desde agora.

## Garrafa e limite desta entrega

A garrafa fechada é um prop narrativo, sem `ItemData` de garrafa vazia nem `CollectibleItem`. **Deixar** apresenta Tec, vibração e risada em texto, com integração aos SFX existentes e um leve movimento/escurecimento. Restaura controle e só retorna à escolha após outra interação; não existe loop automático de modal. A memória usa uma alteração moderada da luz. A preferência de redução de efeitos omite movimento/tintura e preserva falas e decisões. Cancelar, viajar, encerrar a cena ou mudar preferências limpa os efeitos.

**Abrir** valida novamente a fase/cena, apresenta cera/rolha/Pop e, só ao confirmar o último trecho, avança uma vez para `scene_4_dialogue` e emite `bottle_opening_completed`. Essa passagem é o ponto de integração da Task 2.10: fumaça de aparição, entidade, conversa e despedida ainda não estão encenadas nesta Task. Não concede garrafa vazia; o estado só permite essa recompensa depois do despertar na Cena 6/hub. As gravações ainda estão ausentes do catálogo da Task 2.6; a fala textual do Saci não significa que uma dublagem foi produzida. Qualidade sonora/revisão gráfica nativa permanecem pendentes; o preview por CPU serviu apenas para conferir recortes e disposição.

## Retirada dos testes mecânicos

Os quatro pickups antigos (`BottleCollectible`, `PipeCollectible`, `RibbonCollectible`, `SieveCollectible`) saíram da casa do roteiro. Permanecem em `tests/fixtures/inventory_mechanics_lab.tscn`, cena herdada para testar brilho, confirmação, UI e combinação sem distribuir recompensas futuras no jogo. `test_inventory_system.gd` usa esse laboratório. Os testes de navegação preparam seu inventário/pickup explicitamente e continuam percorrendo os mapas reais. Nenhum item inicial foi adicionado ao inventário.

Cidade, quintal e project.godot estão byte a byte iguais ao início da Task. No térreo foram preservados todos os blocos anteriores de tiles, sub-recursos, móveis, colisões, portas, câmeras e marcadores; apenas os quatro pickups foram retirados. No quarto, todos os blocos existentes foram mantidos e a inspeção/crina foram acrescentadas. Roots usam o controlador especializado, mantendo os UIDs das cenas.

O marcador futuro `PlayerWakeUpSpawn` em `(320, 384)` já estava dentro da parede antes desta Task. Ele não é usado pela Cena 3, por portas ou escadas; foi preservado, e deve ser reposicionado para um ponto livre ao encenar o despertar na Task 2.12. Os spawns ativos `PlayerEntrySpawn`, `FromCity`, `FromBedroom` e `FromBackyard` continuam livres e alcançáveis. `SaciBottleSpawn` também é uma reserva a validar junto da aparição na Task 2.10, não uma posição aprovada para instanciar a entidade.

## Validação

`tests/test_house_investigation.gd` cobre chegada única, F6 inativo, ausência de pickups prematuros, inspeções por E, ponteiros invertidos, memória completa, leitura interrompida, recusa/revisita, concessão única casa/banco mesmo após consumo, escolhas da garrafa, preferência de efeitos reduzidos e ida/volta pela escada com inspeção da cama. A busca de caminhos usa a colisão real dos pés até os novos objetos e chegadas ativas; não usa teleporte dentro de paredes como prova de acesso.

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_house_investigation.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Aceite funcional: **14/14 testes específicos e 222/222 testes do projeto**, 9.475 asserts, via Godot 4.7.2/GUT 9.6.1 headless sem erros ou warnings. Próxima Task: **2.9 — Saci e efeitos visuais necessários ao roteiro**.
