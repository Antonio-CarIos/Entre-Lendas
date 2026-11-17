# Fase 1: O Saci-Pererê (Santa Teresa) — Level Design & Especificação Técnica

## 1. Visão Geral e Arquitetura de Cenas
O jogador lê o livro *Lendas do Brasil* e é transportado para Santa Teresa (Rio de Janeiro). Ao entrar em uma casa silenciosa e abrir uma garrafa misteriosa, liberta o Saci-Pererê. Após um diálogo e um redemoinho que o faz desmaiar, o jogador acorda com a casa e a rua em estado caótico. Ele deve investigar 7 pontos de interesse, coletar pistas no Diário e itens no inventário para subir a ladeira, interagir com o grande furacão do Saci e iniciar o **Combate por Turnos**, escolhendo entre **Capturar o Saci (Final A - Rota Agressiva)**, **Fazer Amizade/Pacífico (Final B - Rota de Compreensão)** ou **Subir Despreparado (Final C - Incompleto)**.

Para evitar duplicação de mapas e telas de carregamento desnecessárias na Godot 4, as **8 cenas narrativas** são distribuídas entre as seguintes cenas de exploração e a interface de combate. Os nomes das novas cenas são sugestões, sujeitos à implementação:

| Arquivo de Cena (`res://stages/stage_01_saci/...`) | Cenas do Roteiro Contempladas | Resolução (Tiles `32x32`) | Dimensão em Pixels |
| :--- | :--- | :--- | :--- |
| **`scene_01_book_intro.tscn`** | **Cena 1** (O Livro - Tutorial) | Viewport Fixa | `640 x 360` px |
| **`house_interior.tscn`** | Térreo: cozinha, sala e escada; Cenas 3, 4, 5, 6 e Epílogo C | A definir conforme o mapa | A definir |
| **`house_bedroom.tscn`** | Quarto no andar superior, acessado pela escada do térreo | A definir | A definir |
| **`house_backyard.tscn`** | Quintal, acessado pela porta da cozinha; varal e demais elementos do quintal | A definir | A definir |
| **`santa_teresa_map.tscn`** | **Cenas 2, 7, 8 (Mapa)** + **Epílogos Finais A e B** | `60 x 70` tiles | `1920 x 2240` px |
| **`saci_turn_combat.tscn`** | **Cena 8 (Batalha por Turnos)** | Viewport Fixa | `640 x 360` px |

---

## 2. Variáveis de Estado e Inventário da Fase 1 (`WorldState` & `InventorySystem`)

### 2.1. Flags Booleanas e Contadores da Fase 1
- `stage1_phase: StringName` (`&"scene_2_sunset"`, `&"scene_3_house_clean"`, `&"scene_4_dialogue"`, `&"scene_6_house_chaos"`, `&"scene_7_street_hub"`, `&"scene_8_climax"`, `&"epilogue"`)
- `saci_empatico: bool = false` (Ativado na Cena 4 se o jogador perguntar *"Você ficou preso aí muito tempo?"*).
- `muro_pintado: bool = false` (Ativado na Cena 7 no Quadro 6 se o jogador escolher `[Pintar]`).
- `muro_simbolo_escolhido: StringName` (`&"gorro"`, `&"bambu"`, `&"redemoinho"` ou `&""`).
- `viu_muro_ou_bonde: bool = false` (Requisito para a Quitandeira entregar a peneira).
- `pistas_saci_lidas: int = 0` (Contador incrementado a cada página do diário desbloqueada na Fase 1).

### 2.2. Catálogo de Itens e Pistas (`res://assets/art/items/stage_01/`)
1. **`garrafa_vazia.tres`**: Coletada no chão da sala na Cena 6 `(464, 336)`.
2. **`gorro_saci.tres`**: Coletado no puzzle do varal do quintal na Cena 7 (posição a definir).
3. **`cachimbo_fumo.tres`**: Coletado na mesa da sala (Cena 3) ou no Banco da Praça (Cena 7).
4. **`fita_vermelha.tres`**: Coletada na porteira do quintal na Cena 7 (posição a definir).
5. **`peneira.tres`**: Entregue pela Quitandeira na Cena 7 `(512, 1984)` após `viu_muro_ou_bonde == true`.
6. **`peneira_cruz.tres`**: Resultado da combinação no inventário de `peneira.tres` + `fita_vermelha.tres`.

### 2.3. Páginas do Diário Desbloqueáveis (`pistas_saci_lidas`)
1. `clue_origem_saci`: Ao tocar no cachimbo (Cena 3 ou Cena 7) — *"Nascido no bambu, 77 anos, Saci-Cererê"*.
2. `clue_poder_gorro_parede`: Ao ler o grafite na parede da sala na Cena 6 — *"Quem perde o gorro perde o rumo"*.
3. `clue_gorro_vermelho`: Ao resolver o puzzle dos 7 gorros no Varal (Cena 7).
4. `clue_mural_origens`: Ao ler os Quadros 1 a 5 do Muro de Grafites (Indígena, Bambu, Capoeira/Africana, Gorro/Europeia, Redemoinho).
5. `clue_inquerito_1917`: Ao examinar as páginas coladas no Bonde (Monteiro Lobato, 1917).
6. `clue_crina_cavalo`: Ao examinar o cavalo no Quintal.
7. `clue_bambu_rachado`: Ao examinar o gomo de bambu rachado no Bambuzal.
8. `clue_dia_do_saci_bonus`: Desbloqueada automaticamente ao ler todas as pistas anteriores (Dia do Saci - 31 de outubro).

---

## 3. Especificação da Cena 1: O Livro (`scene_01_book_intro.tscn`)
- **Tipo:** `Control` (`640 x 360` px).
- **Fluxo:**
  1. Jogador vira as páginas com `interact` (`E` / `Espaço` / Clique).
  2. Nas últimas páginas, o texto apresenta o Saci e a página brilha (`Tween` de modulação).
  3. Efeito de transição: distorção de tela + partículas/sprites de letras caindo da página. Carrega `santa_teresa_map.tscn` no estado `&"scene_2_sunset"`.

---

## 4. Especificação do Mapa Interno: A Casa (`house_interior.tscn`)

### 4.1. Dimensões e Estrutura
- O térreo de `house_interior.tscn` está sendo desenhado e contém sala, cozinha e escada para o quarto.
- A escada conecta ao quarto em cena própria; a porta da cozinha conecta ao quintal em cena própria; a porta principal conecta à cidade. As transições devem permitir o retorno e usar pontos de entrada adequados.
- O quintal contém o varal, o cavalo e a porteira com a fita vermelha. As dimensões e coordenadas desses mapas serão definidas durante a construção.
- O desenho do mapa vem primeiro; colisões de cenário, móveis e áreas de transição serão configuradas posteriormente, conforme a matriz de física do projeto.

### 4.2. Organização das Cenas
- No térreo, preservar camadas `TileMapLayer`, `YSortRoot`, móveis, estados organizado/bagunçado, pontos de entrada, escada e saídas para quintal e cidade.
- Quarto e quintal devem ter seus próprios pontos de entrada e saída, e apresentar os estados e interações relevantes à fase.
- O estado narrativo e os itens coletados devem persistir ao transitar entre cenas; não recriar ou reiniciar o progresso ao retornar.
- As coordenadas do projeto original descritas nas interações abaixo são referências narrativas antigas, não posições obrigatórias para o térreo ou o quarto. Adapte-as ao mapa efetivamente desenhado.

### 4.3. Comportamento e Diálogos por Estado na Casa

#### Estado 1: `scene_3_house_clean` (Casa Organizada)
- **Narração ao entrar:** *"Sala limpa. Móveis alinhados. Um relógio de parede marcando uma hora que não existe. Tudo no lugar. O que me trouxe aqui? Que sensação estranha…"*
- **Sofá `(160, 352)`:** *"A almofada ainda tem a marca de alguém sentado. Mas a poeira cobre o resto da casa inteira."*
- **Relógio `(320, 224)`:** Ponteiros giram devagar para trás. *"Os ponteiros giram devagar... para trás? Está quebrado?"*
- **Mesa da Cozinha `(192, 160)`:** *"Uma jarra de leite aberta sobre a mesa. Você cheira. Está azedo. Mas a data da embalagem é de hoje."*
- **Cama no quarto (cena separada; posição a definir):** *"A cama está feita. Em cima do travesseiro, um fio de crina de cavalo, trançado em um nó perfeito."*
- **Cachimbo na Mesa de Centro `(320, 368)`:** Dispara flashback com tela tremendo:
  > **Saci:** *"Eu nasci num gomo de bambu. Sete anos lá dentro, ouvindo o vento... Aprontei tanto que me deram setenta e sete anos para aprontar. Depois disso, viro cogumelo... Antes de ter gorro e de ter cachimbo, eu era um curumim... Os mais velhos me chamavam de Saci-Cererê."*
  - Desbloqueia página `clue_origem_saci`. Exibe escolha `[Deseja guardar? Sim / Colocar de volta]`. Se Sim, adiciona `cachimbo_fumo.tres`.
- **Garrafa na Estante `(512, 288)`:** *"Uma garrafa de vidro escuro, tampada com cera vermelha. Dentro, uma fumaça gira devagar..."* Escolha: `[Abrir] / [Deixar]`.
  - **Se `[Deixar]`:** Garrafa vibra (shake), luz pisca (`HouseModulate`), som *"Tec"* e risadinha. A escolha se repete até `[Abrir]`.
  - **Se `[Abrir]`:** *"Pop."* Rolha salta, fumaça sobe e inicia a **Cena 4**.

#### Estado 2: `scene_4_dialogue` & `scene_5_whirlwind` (Encontro e Redemoinho)
- Saci surge em `(480, 336)`: *"Hihihi! Quanto tempo faz? Contei até perder a conta. Quem é você, que mexe em garrafa dos outros?"*
- **Escolha 1:**
  - `[Eu só estava curioso]` -> *"Curioso! Hihihi! Todo mundo que me solta é curioso..."*
  - `[Quem é você?]` -> *"Eu? Eu sou o vento que bagunça o varal. Sou o leite que azeda..."*
  - `[Você ficou preso aí muito tempo?]` -> **Define `WorldState.saci_empatico = true`**. *"Ninguém tinha perguntado isso antes. Muito tempo. Mais do que um bambu leva para crescer..."*
- **Escolha 2:** `[Conta a sua versão]` ou `[O que você vai fazer agora?]`.
- **Despedida (Cena 5):** *"Obrigado pela rolha, moço. Vou comemorar... do meu jeito! Se quiser me achar, procura onde o vento fizer curva!"*
- Saci gira em redemoinho até a porta `(320, 480)`, câmera treme, vinheta fecha em preto (desmaio) e transiciona para **Cena 6**.

#### Estado 3: `scene_6_house_chaos` (Despertar na Casa Bagunçada)
- `State_Organized.visible = false`, `State_Chaotic.visible = true`. Luz instável.
- **Sofá `(160, 352)` / Lustre `(320, 272)`:** *"A almofada está pendurada no lustre. Não tem escada. Não tem corda. Só uma risadinha, bem baixa, vinda do teto."*
- **Relógio `(320, 224)`:** *"Agora ele marca todas as horas ao mesmo tempo. Os ponteiros giram. Todos para o lado errado."*
- **Cozinha `(192, 176)`:** *"A jarra de leite virou. O chão está branco. Cada gota formou uma carinha sorrindo. Você prefere não pisar."*
- **Acesso ao quarto pela escada:** Bloqueado fisicamente por um laço de crina na entrada do quarto. *"A cama está desfeita e o travesseiro, no armário. A crina trançada virou um laço enorme na maçaneta, impedindo a passagem para o quarto."*
- **Estante `(512, 288)`:** *"A garrafa não está mais aqui. No lugar dela, um bilhete de carvão: 'Obrigado pela rolha. Hihihi!'"*
- **Garrafa Vazia no Chão `(464, 336)`:** Coletável -> Adiciona `garrafa_vazia.tres` ao inventário.
- **Parede com Grafite `(96, 240)`:** *"Um desenho a carvão: um menino de uma perna só, rindo. Ao lado: 'Quem perde o gorro perde o rumo.'"* -> Desbloqueia `clue_poder_gorro_parede`.
- **Porta de Saída `(320, 480)`:** Carrega `santa_teresa_map.tscn` no estado `&"scene_7_street_hub"`.

---

## 5. Especificação do Mapa Externo: Santa Teresa (`santa_teresa_map.tscn`)

### 5.1. Dimensões e Coordenadas Globais
- **Tamanho Total:** `60 x 70` tiles (`1920 x 2240` px).
- **Eixo Central da Rua Principal:** `X = 960 px` (Largura: `256 px` / 8 tiles).
- **Trilhos Horizontais do Bonde:** Cruzam de `X = 0` a `X = 1920` na altura `Y = 1472 px`.

### 5.2. Planta Baixa e Coordenadas de Referência

Os pontos da cidade mantêm as coordenadas planejadas abaixo. Varal, cavalo e porteira pertencem à cena separada do quintal, acessível pela cozinha; suas antigas coordenadas no mapa da cidade não se aplicam.

| ID / Ponto no Mapa | Coordenada `(X, Y)` | Visível na Cena 2? | Visível na Cena 7? | Descrição e Regras de Interação |
| :--- | :--- | :--- | :--- | :--- |
| **Spawn Inicial (Cena 2)** | `(960, 1760)` | Sim | Sim | Ponto onde o jogador surge após a Cena 1. |
| **Saída da Casa (Cena 7)** | `(736, 1728)` | Sim | Sim | Ponto onde o jogador surge ao sair da casa bagunçada. |
| **Fachada da Casa** | `(736, 1696)` | Sim | Sim | Porta entreaberta. Na Cena 2, escolher `[Ainda não]` diz: *"Algo no seu peito diz que não há para onde voltar."* |
| **Janela da Casa** | `(688, 1664)` | Sim | Sim | Na Cena 2 balança sozinha: *"Ela abre e fecha sozinha, no ritmo de uma risadinha abafada."* |
| **Placa da Rua** | `(1120, 1696)` | Sim | Sim | *"'Rua do Saci.' Estranho. Você tem quase certeza de que não era esse o nome."* |
| **POI 1: Varal no quintal** | A definir na cena do quintal | Não | **Sim** | Contém os 6 sub-itens interativos e o puzzle dos 7 gorros (ver Seção 5.3). |
| **POI 2: Praça + Banco** | `(960, 1152)` | Sim (Vazio)| **Sim (Com Item)** | Cachimbo e fumo de corda fumegando em `(972, 1144)`. Dá `cachimbo_fumo.tres` + memória de 77 anos. |
| **POI 3: Muro de Grafites**| `(1504, 1152)` | Sim (Limpo)| **Sim (Pintado)** | 6 Quadros (`X: 1400` a `1580`) + Pincel no chão em `(1580, 1180)` (ver Seção 5.4). |
| **POI 4: Bonde Amarelo** | `(480, 1472)` | Sim (Limpo)| **Sim (Com Jornais)**| **Cena 2:** *"O banco ainda está quente."* **Cena 7:** Páginas do Inquérito de 1917 (Monteiro Lobato). Define `viu_muro_ou_bonde = true` e dá `clue_inquerito_1917`. |
| **POI 5: Quintal e Cavalo** | A definir na cena do quintal | Conforme acesso à casa | **Sim** | Porteira dá `fita_vermelha.tres`; cavalo dá `clue_crina_cavalo`. |
| **POI 6: Quitanda** | `(512, 1984)` | Sim (Fechada)| **Sim (Com NPC)** | Quitandeira atrás do balcão `(512, 1968)`. Se `viu_muro_ou_bonde == true`, entrega `peneira.tres`. |
| **POI 7: Bambuzal** | `(1408, 1984)` | Sim | **Sim (Rachado)** | Gomo rachado em `(1360, 2016)` com marca de mãozinha. Piscando em sincronia com o Quadro 2 do Muro. Dá `clue_bambu_rachado`. |
| **Gatilho da Ladeira** | `(960, 864)` | Bloqueado | **Sim** | Checa requisitos mínimos antes de subir para a Praça do Clímax. |
| **Furacão do Saci (Cena 8)**| `(960, 320)` | Inativo | **Ativo na Cena 8** | Grande redemoinho com `InteractableArea`. O jogador se aproxima, interage e inicia o **Combate por Turnos**. |

### 5.3. Detalhamento do POI 1: O Varal no Quintal
As posições locais do varal e seus elementos serão definidas no mapa do quintal; as coordenadas abaixo são apenas referências antigas.
Ao se aproximar, exibe a narração das roupas pingando sem vento. Possui **6 interações**:
1. **Meias Soltas `(368, 1152)`:** *"Nenhuma é par da outra. Alguém tem uma perna só. Ou muito azar com as meias."*
2. **Camisa de Time `(392, 1152)`:** *"Com um buraco no formato de uma risada. O número nas costas está de cabeça para baixo."*
3. **Vestido de Festa `(416, 1152)`:** Bilhete preso com alfinete: *"Quem lava e não recolhe, a mim pertence."*
4. **Bilhete no Poste Esquerdo `(352, 1152)`:** Escrito a carvão: *"Quem tem o gorro, manda no Saci. Mas ele sabe quando você está com ele."*
5. **Puzzle dos 7 Gorros (`X: 432` a `480, Y: 1152`):**
   - **6 Gorros Falsos:** Balançam com animação/Tween de brisa. Ao tocar: *"Frio. Mole. Sem graça. 'Hihihi!'"*
   - **1 Gorro Verdadeiro:** **Completamente parado (`rotation = 0`)**. Ao chegar perto, indica que está morno e cheira a fumo de corda.
   - **Ao Pegar:** Trilha sonora silencia por `3.0s` e retorna em tom mais grave. Entrega `gorro_saci.tres` e desbloqueia `clue_gorro_vermelho`.

### 5.4. Detalhamento do POI 3: O Muro de Grafites (`(1504, 1152)`)
Interagir com qualquer quadro define `viu_muro_ou_bonde = true`.
- **Quadro 1 `(1400, 1152)`:** O menino da mata (Saci-Cererê, origem indígena, duas pernas).
- **Quadro 2 `(1436, 1152)`:** O bambu e os sete anos (pisca no mesmo ritmo do gomo do Bambuzal).
- **Quadro 3 `(1472, 1152)`:** A perna perdida na roda de capoeira (influência africana).
- **Quadro 4 `(1508, 1152)`:** O gorro vermelho e o cachimbo (influência europeia).
- **Quadro 5 `(1544, 1152)`:** O redemoinho e as travessuras (animação sequencial dos itens voando).
- **Quadro 6 `(1580, 1152)` + Pincel `(1580, 1180)`:** Mãos coloridas ao redor do espaço em branco: *"Cada um conta o Saci do seu jeito."*
  - Escolha: `[Pintar] / [Deixar em branco]`.
  - Se `[Pintar]`: Abre sub-menu com 3 opções (`[Gorro]`, `[Bambu]`, `[Redemoinho]`). Salva `WorldState.muro_pintado = true` e `WorldState.muro_simbolo_escolhido`, ativa o decalque correspondente no muro e toca risadinha agradecida.

---

## 6. Especificação da Cena 8: Clímax — Combate por Turnos (`saci_turn_combat.tscn`)

### 6.1. Subida da Ladeira (`(960, 864)`) e Gatilho do Redemoinho (`(960, 320)`)
- **Validação na Base da Ladeira `(960, 864)`:**
  - **Condição Ideal de Captura:** Possuir `peneira_cruz` E `garrafa_vazia`.
  - **Condição Ideal Pacífica:** Possuir `cachimbo_fumo` E `pistas_saci_lidas >= 3`.
  - Se o jogador **não** atender a nenhuma das duas condições, exibe o aviso:
    > *"O vento diz que ainda tem coisa para ver. Subir assim mesmo?"* `[Subir] / [Voltar]`
- **Interação no Topo `(960, 320)`:**
  - No centro da praça superior há um grande sprite animado do furacão do Saci (`WhirlwindBossArea`).
  - Não há obstáculos arremessados no mapa top-down; o jogador caminha até a borda do furacão e pressiona `interact` (`E`).
  - A tela faz o efeito clássico de transição de encontro (flash preto/branco + som de vento) e abre a interface de **Batalha por Turnos** (inspirada em *Undertale*, *EarthBound*, *Mother 3* e *Omori*).

### 6.2. Estrutura da Batalha por Turnos contra o Saci
A batalha é governada por dois contadores na máquina de estados (`CombatStateMachine`):
- **`calm_progress: int` (`0` a `100`):** Medidor de **Amizade / Calma** (Rota Pacífica).
- **`capture_stage: int` (`0` a `3`):** Progresso de **Subjugação / Captura** (Rota Agressiva).

#### Menu Principal de Turno do Jogador (4 Botões)
1. **`[ INTERAGIR / BRINCAR ]` (Rota Pacífica — Ações Estilo *ACT* do Undertale):**
   Abre sub-menu de interações sociais e lúdicas para acalmar o Saci:
   - **`[Contar Piada / Adivinha]`:** O jogador conta uma charada folclórica (*"O que é, o que é: cai em pé e corre deitado?"*). O Saci dá gargalhadas e o vento diminui (`calm_progress += 25`).
   - **`[Entrar na Brincadeira]`:** O jogador imita o pulo de uma perna só ou faz graça com as travessuras da rua. O Saci se diverte vendo que você não tem medo dele (`calm_progress += 25`).
   - **`[Contar Causos da Origem]`:** Disponível se `pistas_saci_lidas >= 3`. Menciona o nascimento no bambu, os 77 anos e o nome *Saci-Cererê* (`calm_progress += 35`).
   - **`[Elogiar as Travessuras]`:** Comentário bem-humorado sobre o leite azedo e o mural pintado (`calm_progress += 15`, ou `+25` se `muro_pintado == true`).

2. **`[ ITEM ]` (Suporte à Rota Agressiva ou Pacífica):**
   Permite usar os itens coletados na Fase 1 diretamente no turno:
   - *Para Captura (Rota Agressiva):*
     - **Usar `peneira_cruz` (`capture_stage: 0 -> 1`):** Você lança a peneira com a fita vermelha em cruz no meio do furacão! O redemoinho fica preso dentro da trama da peneira e o Saci começa a se debater.
     - **Usar `gorro_saci` (Opcional / Facilitador — `capture_stage: 1 -> 2`):** Você mostra que está com o gorro reserva. O Saci perde as forças de vento imediatamente. (Caso não tenha o gorro, o jogador usa a ação `[Segurar Peneira]` no menu de confronto para avançar ao estágio 2).
     - **Usar `garrafa_vazia` (`capture_stage: 2 -> 3`):** Com o Saci enfraquecido na peneira, você aproxima a garrafa e fecha a rolha (`Pop!`), encerrando o combate imediatamente no **Final A (Captura)**.
   - *Para Amizade (Rota Pacífica):*
     - **Oferecer `cachimbo_fumo`:** O Saci sente o cheiro de antes, acende o cachimbo e a fumaça desenha um menino de duas pernas rindo (`calm_progress += 40`).
     - **Devolver `gorro_saci`:** Você estende o gorro voluntariamente sem exigir pedidos. O vento para de imediato (`calm_progress = 100`).

3. **`[ CONFRONTAR ]` (Rota Agressiva / Forçar Captura):**
   - Caso o jogador já tenha lançado a `peneira_cruz` (`capture_stage == 1`), este botão muda para **`[Segurar a Peneira]`**, contendo o Saci à força até que ele fique exausto (`capture_stage = 2`), pronto para receber a `garrafa_vazia`.
   - Caso tente confrontar sem a `peneira_cruz`, o ataque atravessa o vento sem efeito (*"Você tenta agarrar o vento com as mãos vazias! O Saci apenas ri: 'Hihihi!'"*).

4. **`[ AMIZADE (POUPAR) ]`:**
   - Fica habilitado (texto amarelo/verde brilhante) quando `calm_progress >= 100`.
   - Selecionar esta opção encerra o combate pacificamente e leva ao **Final B (Pacífico)**.

#### Turnos de Resposta do Saci (Reações Narrativas e Travessuras de Turno)
A cada turno do Saci, em vez de causar *Game Over*, ele responde ao comportamento do jogador com falas dinâmicas e travessuras visuais na janela de batalha (estilo *EarthBound* / *Omori*):
- *"Vou embolar sua linha!"* -> Embaralha a ordem dos 4 botões do menu por 1 turno.
- *"Vou azedar seu leite!"* -> A caixa de texto fica esverdeada e trêmula no próximo turno.
- *"Hihihi! Todo mundo quer me pegar, todo mundo quer me ouvir. Ninguém quer as duas coisas!"*
- Conforme `calm_progress` sobe (50%, 75%, 100%), os ataques de vento cessam e o Saci passa o turno rindo das suas piadas ou ouvindo suas histórias.

---

## 7. Resolução dos 3 Finais

### Final A: Captura — Rota Agressiva (`WorldState.Choice.CAPTURE`)
- **Condição de Disparo:** Usar `peneira_cruz` -> conter o Saci -> usar `garrafa_vazia` no Combate por Turnos (`capture_stage == 3`).
- **Diálogo de Captura:**
  > *A peneira gira no ar. A fita vermelha faz a cruz. Por um instante, o redemoinho inteiro cabe dentro dela.*  
  > **Saci:** *"Não! Não! A rolha, não! Eu ia devolver! Eu ia..."*  
  > *Pop. A garrafa tampada pesa na sua mão. Lá dentro, uma fumaça gira devagar. Sempre no mesmo sentido.*
- **Epílogo no Mapa:** Rua limpa instantaneamente, roupas descem dos postes, desenhos desbotam. Cores excessivamente saturadas (`CanvasModulate`), silêncio absoluto sem risadas. Se `pistas_saci_lidas >= 4`, exibe: *"Você sabia o que ele era. Foi assim mesmo?"*

### Final B: Pacífico — Rota da Amizade (`WorldState.Choice.FRIENDSHIP`)
- **Condição de Disparo:** Atingir `calm_progress >= 100` (contando piadas, fazendo brincadeiras, falando da origem, oferecendo o cachimbo ou devolvendo o gorro) e selecionar **`[ AMIZADE (POUPAR) ]`**.
- **Diálogo de Amizade e Falas Condicionais:**
  - Se ofereceu o cachimbo: *"Esse cheiro. Esse bambu. Isso é meu de antes."*
  - Se devolveu o gorro: *"Você podia mandar em mim com isso. Sabia? ...E mesmo assim devolveu."*
  - Se `saci_empatico == true`: *"Você foi o primeiro que perguntou se eu estava preso há muito tempo. Ninguém mais perguntou."*
  - Se `muro_pintado == true`: *"Vi seu desenho no muro. O bambu ficou torto. Mas ficou meu."*
  > **Saci:** *"Está bem, moço. Eu arrumo tudo. Mas amanhã eu bagunço de novo, hein?"*
- **Epílogo no Mapa:** O redemoinho se desfaz em pétalas de papel, os grafites viram flores no muro, a rua recupera suas cores naturais e ouve-se uma risadinha alegre ao longe.

### Final C: Incompleto (Fallback Opcional)
- **Condição de Disparo:** Iniciar o combate sem `peneira_cruz`/`garrafa_vazia`, sem `cachimbo_fumo` e com `pistas_saci_lidas < 3`, passando 3 turnos sem conseguir capturar nem acalmar o Saci.
- **Desfecho:** O Saci boceja no combate (*"Você nem sabe quem eu sou e nem sabe brincar. Que tédio."*) e encerra a batalha sozinho. O jogador retorna para a casa quase arrumada, mas com o relógio da sala ainda girando ao contrário, permitindo voltar à rua e explorar o que faltou.