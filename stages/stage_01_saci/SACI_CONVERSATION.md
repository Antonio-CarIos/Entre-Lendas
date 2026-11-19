# Cena 4 — preparação da conversa com o Saci

**Entrega parcial, sem integração no mapa. Tasks 2.9 e 2.10 continuam abertas.** O usuário informou que os assets estão prontos, mas o caminho da versão de uma perna ainda precisa ser identificado. Os 24 PNGs de produção e os personagens encontrados no PixelLab mostram redemoinho. Não usar essa forma na conversa, nem criar aliases de fala/aparição para caminhada.

`core/dialogue/stage_01/saci_conversation_script.gd` cria uma cópia independente do roteiro: preserva as três respostas iniciais, as duas seguintes e a despedida; torna as decisões obrigatórias; termina antes de `whirlwind.departure`. A rubrica `(risonho)` sai do texto visível apenas nessa cópia. Somente a escolha sobre o tempo preso registra empatia.

`components/transitions/saci_conversation.gd` recebe explicitamente um `SaciActor` já posicionado e um `GameplayHUD`. Usa `CutsceneCoordinator`, respeita o estado de controle anterior e valida os clipes humanos `appear_down` (sem loop), `idle_down` e `talk_down` (com loop). O canvas deve corresponder ao Resource, sem recortes fora da textura. A duração da aparição inclui as durações relativas dos frames. Arte ausente/inválida rejeita o início antes de adquirir controles ou alterar progresso.

O controlador só aceita a fase `scene_4_dialogue`, depois do Pop. Não abre a garrafa, instancia outro Saci, concede a garrafa vazia ou aplica o caos. Ao confirmar a última página da despedida, avança uma vez para `scene_5_whirlwind`, registra `saci_conversation_completed` e emite `whirlwind_requested(actor)`. A HUD mantém a movimentação bloqueada aguardando a Cena 5. O futuro controlador da saída deve chamar `release_to_whirlwind()` e adquirir seu próprio bloqueio na mesma chamada, sem aguardar um frame entre as operações. `cancel()` e a saída dos nós restauram modal, callbacks e apresentação. Uma conversa interrompida na Cena 4 pode ser retomada com `start(actor, hud, false)`, preservando a empatia já registrada e sem repetir a animação da aparição.

## Integração que falta

1. Confirmar a pasta dos PNGs humanos e inspecionar anatomia, escala, grid e animações reais. Vincular os frames a `SaciVisuals.one_leg` e concluir a auditoria da Task 2.9.
2. Validar/reposicionar `SpawnPoints/SaciBottleSpawn`: as coordenadas reservadas atuais estão dentro de parede. Não alterar os spawns ativos da protagonista.
3. Integrar cera, rolha/Pop e fumaça à aparição; validar a apresentação antes da decisão irreversível da garrafa e novamente ao concluir o Pop.
4. Instanciar um único ator sob `YSortRoot`, conectar `HouseInvestigation.bottle_opening_completed` e tratar retomada após carregamento. Essa conexão **ainda não existe**: o mapa mantém o comportamento anterior da Task 2.8.
5. Integrar a saída da Task 2.11 antes de ativar a conversa no jogo: a entrega isolada termina com o Player bloqueado aguardando essa sequência.

`tests/test_saci_conversation.gd` cobre as seis combinações de respostas, empatia, teclas E/setas/Esc/Tab, término obrigatório, entrega única, validação de arte, retomada, dependências removidas e restauração de controles. Os testes usam texturas sintéticas **somente em memória**, para testar o contrato; elas não são sprites do jogo nem demonstram que a arte final está disponível. Testes headless não substituem a revisão visual da sequência completa.

Validação em 19/11/2026: suíte completa **250/250 testes** (18 scripts, 10.245 asserts) e verificação específica final **16/16 testes**, sem erros ou warnings. O catálogo puro passou em `--check-only`. Comparação de hashes confirmou mapas, Player, PNGs e `project.godot` intactos. Foram restaurados novamente os metadados de leitura/tutorial/rastreabilidade ausentes no roteiro, preservando integralmente falas, escolhas e UIDs. O progresso parcial está registrado na sprint, sem marcar a Task concluída.
