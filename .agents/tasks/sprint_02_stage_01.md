# Sprint 02: Implementação Completa da Fase 1 (O Saci-Pererê)

> **Instrução para o Agente CLI:** Antes de iniciar qualquer task abaixo, leia obrigatoriamente `.agents/AGENTS.md`, `.agents/context/07_stage_01_saci_design.md` e `.agents/skills/build_turn_based_combat.md`. Mantenha tipagem estática em 100% do GDScript 2.0 e valide cada entrega com o GUT via CLI.

---

## Task 2.1: Expansão do `WorldState`, Itens e Diário da Fase 1
- [ ] Adicionar no `WorldState` (ou num módulo `Stage01State` acoplado ao `WorldState`) as variáveis da Fase 1: `stage1_phase`, `saci_empatico`, `muro_pintado`, `muro_simbolo_escolhido`, `viu_muro_ou_bonde` e o registro de páginas do diário (`unlocked_diary_pages: Array[StringName]`).
- [ ] Implementar no `InventorySystem` o método `combine_items(item_a_id: StringName, item_b_id: StringName) -> bool` para permitir combinar `peneira` + `fita_vermelha` gerando `peneira_cruz`.
- [ ] Criar os 6 arquivos `.tres` da Fase 1 em `res://core/inventory/items/stage_01/`: `garrafa_vazia.tres`, `gorro_saci.tres`, `cachimbo_fumo.tres`, `fita_vermelha.tres`, `peneira.tres`, `peneira_cruz.tres`.
- [ ] **Teste GUT (`res://tests/test_stage_01_state_and_items.gd`):** Testar combinação da peneira com a fita, contagem de pistas lidas (`pistas_saci_lidas`) e validação dos requisitos dos Finais A, B e C.

---

## Task 2.2: Cena 1 — O Livro Introdutório (`scene_01_book_intro.tscn`)
- [ ] Criar `res://stages/stage_01_saci/scene_01_book_intro.tscn` e `scene_01_book_intro.gd`.
- [ ] Implementar a paginação interativa do livro *Lendas do Brasil*, o efeito de brilho na última página e a transição de letras caindo para carregar `santa_teresa_map.tscn` no estado `&"scene_2_sunset"`.

---

## Task 2.3: Mapa Interno — A Casa (`house_interior.tscn` — Cenas 3, 4, 5 e 6)
- [ ] Estruturar `res://stages/stage_01_saci/house_interior.tscn` como térreo com cozinha, sala e escada, respeitando o mapa em construção e a Seção 4 de `07_stage_01_saci_design.md`.
- [ ] Criar cena separada para o quarto, conectada à escada do térreo, e cena separada para o quintal, conectada à porta da cozinha; a porta principal conecta o térreo à cidade. Prever pontos de retorno e persistência do estado.
- [ ] Após o desenho dos mapas, configurar colisões de cenário, móveis e transições conforme `03_physics_and_layers.md`.
- [ ] Implementar em `house_interior.gd` a função `apply_house_state(phase: StringName) -> void` alternando entre `State_Organized` (Cena 3) e `State_Chaotic` (Cena 6).
- [ ] Configurar todas as `InteractableArea` da **Cena 3**: Sofá, Relógio (ponteiros para trás), Leite azedo, Quarto (crina no travesseiro), Cachimbo (flashback de 77 anos + página `clue_origem_saci`) e Garrafa na estante (`[Abrir]/[Deixar]` com shake e piscar de luz).
- [ ] Implementar o fluxo de diálogo ramificado da **Cena 4** (registrando `saci_empatico = true` na opção empática) e a animação de redemoinho/desmaio da **Cena 5**.
- [ ] Configurar as interações da **Cena 6**: Almofada no lustre, Relógio maluco, Leite com carinhas sorrindo, acesso ao quarto pela escada bloqueado pelo laço de crina, Bilhete na estante, coleta de `garrafa_vazia.tres`, leitura do grafite na parede (`clue_poder_gorro_parede`) e saída pela porta torta rumo à Cena 7.

---

## Task 2.4: Mapa Externo — Santa Teresa e os 7 Pontos de Interesse (`santa_teresa_map.tscn`)
- [ ] Estruturar `res://stages/stage_01_saci/santa_teresa_map.tscn` (`1920 x 2240` px) com suporte aos estados `&"scene_2_sunset"` (`CanvasModulate` dourado `#ffdfb3`) e `&"scene_7_street_hub"` (`CanvasModulate` dessaturado `#9eaab8`).
- [ ] Configurar as interações da **Cena 2**: Bonde quente, Placa *"Rua do Saci"*, Janela balançando e Porta entreaberta da casa.
- [ ] Implementar os **7 Pontos de Interesse da Cena 7**, distribuídos entre cidade e quintal; coordenadas do quintal serão definidas no seu próprio mapa:
  1. **POI 1 (Varal no quintal - posição a definir):** 5 interações de roupas/poste + Puzzle dos 7 gorros (6 com `Tween` de vento, 1 parado dando `gorro_saci.tres` + pausa de 3s na trilha sonora).
  2. **POI 2 (Praça + Banco - `960, 1152`):** Coleta de `cachimbo_fumo.tres` (caso não pego na casa) e memória.
  3. **POI 3 (Muro de Grafites - `1504, 1152`):** Leitura dos Quadros 1 a 5 (`viu_muro_ou_bonde = true`) + Quadro 6 com escolha `[Pintar]/[Deixar em branco]` e seleção de símbolo (`gorro`, `bambu`, `redemoinho`).
  4. **POI 4 (Bonde - `480, 1472`):** Inquérito de 1917 (`viu_muro_ou_bonde = true` + `clue_inquerito_1917`).
  5. **POI 5 (Cavalo e porteira no quintal - posições a definir):** Cavalo (`clue_crina_cavalo`) + Porteira (`fita_vermelha.tres`).
  6. **POI 6 (Quitanda - `512, 1984`):** Diálogo com a Quitandeira entregando `peneira.tres` (condicionado a `viu_muro_ou_bonde`).
  7. **POI 7 (Bambuzal - `1408, 1984`):** Gomo rachado piscando em sincronia com o Quadro 2 (`clue_bambu_rachado`).

---

## Task 2.5: Cena 8 — Clímax em Combate por Turnos (`saci_turn_combat.tscn`) e os 3 Finais
- [ ] Implementar o gatilho da ladeira em `(960, 864)` validando os pré-requisitos e exibindo o aviso *"O vento diz que ainda tem coisa para ver. Subir assim mesmo?"* caso incompleto.
- [ ] Adicionar o grande furacão interativo do Saci no centro da praça superior `(960, 320)` (`WhirlwindBossArea`), que ao receber `interact` dispara a transição para o combate por turnos.
- [ ] Criar a lógica pura do encontro (`SaciCombatController` herdando de `RefCounted`) e a cena de interface `res://stages/stage_01_saci/saci_turn_combat.tscn` (estilo *Undertale / EarthBound / Mother 3 / Omori*):
  - **Rota Pacífica (`[INTERAGIR / BRINCAR]` + `[ITEM]` + `[AMIZADE]`):** Ações de contar piadas/adivinhas, entrar na brincadeira, contar causos da origem e elogiar travessuras, além do uso de `cachimbo_fumo` e devolução de `gorro_saci` para elevar `calm_progress` até `100%` e liberar o botão `[AMIZADE (POUPAR)]`.
  - **Rota Agressiva (`[ITEM]` + `[CONFRONTAR]`):** Sequência de captura em turnos usando `peneira_cruz` (`capture_stage = 1`), contenção com `[Segurar a Peneira]` ou `gorro_saci` (`capture_stage = 2`) e aprisionamento final com `garrafa_vazia` (`capture_stage = 3`).
  - **Turnos do Saci:** Travessuras de interface (embaralhar botões de turno, texto esverdeado) e falas reativas ao progresso de calma ou captura.
- [ ] Implementar a resolução e os epílogos dos **3 Finais** (Final A: Captura hipersaturada e silenciosa; Final B: Pacífico com falas condicionais de `saci_empatico`/`muro_pintado`, flores no muro e pétalas; Final C: Incompleto por tédio após 3 turnos sem requisitos).
- [ ] **Teste GUT (`res://tests/test_stage_01_saci_combat_and_endings.gd`):** Testar em modo *headless* a progressão de `calm_progress` (piadas/brincadeiras/itens), a sequência de `capture_stage` (peneira -> contenção -> garrafa) e o disparo correto dos Finais A, B e C no `WorldState`.