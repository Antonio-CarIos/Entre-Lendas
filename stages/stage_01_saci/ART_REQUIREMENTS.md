# Arte da Fase 1 — auditoria da Task 2.9

**Situação: entrega parcial. A Task 2.9 não está concluída.** A entidade reutilizável e a forma de redemoinho existente estão integradas e testáveis, mas faltam a forma de uma perna e os frames específicos de aparição/fala/giro/despedida. Não iniciar a Cena 4 mostrando o redemoinho no lugar da perna. O quadrado vermelho autorizado pelo usuário continua reservado ao combate da Task 2.20.

## O que foi encontrado

| Recurso | Evidência / uso |
| --- | --- |
| Saci de exploração com redemoinho | 24 PNGs em `assets/art/characters/folklore/saci/`: quatro poses idle e cinco frames walk por direção. Todos mostram vento no lugar das pernas. |
| Tamanhos nativos | Idle 80×80; walk_down 64×80; walk_up/left/right 96×96. O desenho visível chega a 41 px de largura e 69 px de altura; forçar recorte 32×64 apagaria pixels. |
| Saci com uma perna | Não encontrado nos PNGs de produção. O usuário informou novos assets prontos; aguarda-se o caminho. Um cache antigo `saci_perna_unica.png` tem aparência/anatomia divergentes e não foi promovido a asset final. Não há clipes humanos aprovados de aparição, fala, giro ou despedida. |
| Base humana obrigatória | Não existe no caminho do projeto `assets/art/_templates/character_base/body/`. Foi localizado o pacote original em Downloads, `Assets/World Build - Character Pack - 0.2/Character/Body_A/`, com Head/Chest/Legs/Arm_L/Arm_R e Idle/Walk/Run. Não foi copiado para produção; antes de gerar, inspecionar seu grid real (pranchas Idle Down de Head/Legs medem 384×128) e seus termos. |
| Templates de cenário | Presentes em `_templates/tileset_base/`; atlas Light_Woody/Props inspecionado. Escala 32×32, madeira quente, laranja, contorno escuro e sombras simples. |
| Inventário | Oito ícones limpos 32×32 já existem em `assets/art/items/stage_01/`. Gorro e páginas são candidatos relacionados a props estáticos; não precisam de nova geração só para aparecer na UI. Não aplicar brilho de mapa às texturas da UI. |
| Objetos e espaços existentes | Sofá/almofada/leite e móveis no atlas da casa; relógio nativo e fio de crina da Task 2.8; pegadas em `tilesets/stage_01/forest/saci_footprints.png`; banco/bonde/quitanda/cavalo/galinhas/bambuzal já disponíveis. Preservar todos. |
| Mural | Seis Marker2D `Panel01…Panel06`, com reserva individual de **40×48**, separados por 56 px. O muro existe; os seis desenhos narrativos não. |
| PixelLab conectado | A listagem completa também localizou `6a3eca75-75a1-4254-929c-ba2b30a2462b`, chamado “dark-skinned boy wearing a red”, com quatro direções e redemoinho, correspondente aos PNGs locais. A busca apenas por “Saci” omitia esse personagem. O Saci de batalha 96×96 com duas direções (`43129601-5ea4-4163-bc44-c7aab7ab4179`) também tem vento. As imagens antigas inspecionadas na galeria igualmente mostram redemoinho. Nenhum foi usado como substituto da perna única ou do quadrado vermelho de combate. |

Nenhum PNG foi gerado, redesenhado, reamostrado ou sobrescrito nesta Task. O catálogo de origem/licença dos PNGs do Saci recebidos ainda precisa de confirmação do autor; não atribuir esses arquivos automaticamente a uma geração efetuada nesta sessão. O pacote de cenário tem os termos de Anokolisa já guardados em `_templates/tileset_base/_source/world_build/Terms.txt`.

## Entidade e alinhamento

`entities/folklore/saci/saci.tscn` tem `CharacterBody2D` em FLOATING, Nearest, Y-Sort, AnimatedSprite2D e colisor 20×12 nos pés. Começa oculta e sem colisão; o controlador narrativo deve validar a disponibilidade antes de mostrá-la. `SaciVisuals` guarda separadamente `one_leg` (ausente) e `whirlwind` (disponível). `SaciActor.show_form()` e `play_action()` retornam bool; uma solicitação sem arte oculta o ator e emite `visual_unavailable(form, action, direction)`. Não há aliases de talk/spin/appear/depart para idle/walk.

Os 24 frames reais estão em `whirlwind_frames.tres`, oito clipes a 8 FPS: `idle_down/up/left/right` e `walk_down/up/left/right`. Idle é uma pose estática por direção, não uma animação de respiração inventada. Existem arquivos distintos de esquerda/direita; não espelhamos outra direção.

O canvas lógico do redemoinho é **64×80**, com offset `(0,-40)`. Isso é uma adaptação explícita dos arquivos recebidos, não uma alegação de que a arte cumpre o alvo 32×64. AtlasTexture recorta só transparência e usa margens para acomodar o desenho no canvas, com escala 1:1. Cada clipe compartilha um único recorte e deslocamento; o movimento original entre seus cinco frames permanece. O eixo X usa a mediana do centro das duas últimas linhas opacas; Y usa o ponto mais baixo do clipe. Não se recentraliza cada frame de caminhada independentemente, evitando anular a oscilação original. Nenhum gorro, mão, cachimbo ou vento visível é cortado.

`ART_AUDIT.json` ao lado dos PNGs contém os caminhos, tamanhos nativos, caixas opacas, hashes da inspeção, recortes, margens e âncoras dos oito clipes. Ao substituir fontes, atualizar os Resources e esse relatório; os testes verificam conteúdo/recortes e não congelam hashes de futuras revisões do usuário.

Colisão física é opcional: `set_body_solid(true)` usa World + NPCs (5) / Mask World + Player (3), compatível com o Player atual cuja máscara é World. O padrão é false para a coreografia não prender o ator nos móveis. Ocultar desativa também sua presença física. Não muda configurações globais, câmera, inputs, inventário ou fase. Não foi colocado um Saci prematuro nos mapas.

## Pacote prioritário para continuar a Cena 4

Os caminhos abaixo são **destinos propostos**, não arquivos existentes nem referências obrigatórias de carregamento. Frames separados `frame_000.png`, `frame_001.png` etc. são preferidos; se vier sheet, informar colunas/linhas, ordem, tamanho de cada célula e FPS. Não misturar escalas e não redimensionar pixel art para encaixar. Os números de frames são um briefing proposto: confirmar o layout do template humano restaurado antes de gerar.

| Prioridade / Task | Destino relativo a `assets/art/` | Canvas por frame / quantidade proposta | Conteúdo e pivô |
| --- | --- | --- | --- |
| Essencial 2.9–2.10 | `characters/folklore/saci/one_leg/idle/{down,up,left,right}/` | 32×64; 4 frames por direção; 8 FPS, loop | Mesmo menino, pele brasileira natural, gorro vermelho cônico, shorts rasgados, **uma única perna centralizada**; base dos pés no centro inferior. |
| Essencial 2.9–2.10 | `characters/folklore/saci/one_leg/appear/down/` | 32×64; 8 frames; 8 FPS, sem loop | Gorro, olhos, sorriso e uma perna que pousa; fundo transparente. A fumaça é efeito separado. |
| Essencial 2.9–2.10 | `characters/folklore/saci/one_leg/talk/down/` | 32×64; 4 frames; 8 FPS, loop | Boca/expressão/pequenos gestos, mesma roupa e silhueta, pé fixo. |
| Essencial 2.9–2.11 | `characters/folklore/saci/one_leg/spin/down/` | 32×64; 8 frames; 8 FPS, sem loop | Giro sobre uma perna; manter o apoio e não desenhar segunda perna. |
| Essencial 2.9–2.11 | `characters/folklore/saci/one_leg/depart/down/` | 32×64; 8 frames; 8 FPS, sem loop | Transição coerente para vento, final transparente. Não apenas repetir walk. |
| Exploração futura | `characters/folklore/saci/one_leg/walk/{down,up,left,right}/` | 32×64; 8 frames por direção; 8 FPS, loop | Deslocamento em pequenos pulos da perna única, sem mecânica de plataforma. Side pode ser espelhado **se** esse for o layout fornecido; adaptar explicitamente o mapeamento. |
| Essencial 2.10 | `effects/stage_01/saci/bottle_smoke/` | 64×96; 8 frames; 8 FPS, sem loop | Fumaça creme/cinza quente subindo da garrafa; origem centro inferior, não tapar todo o texto. |
| Essencial 2.11/2.19 | `effects/stage_01/saci/whirlwind_large/` | 128×192; 8 frames; 8 FPS, loop | Furacão de poeira/vento, com objetos da casa orbitando; centro inferior. Não ampliar o Saci pequeno como se fosse esse asset. |

A forma de redemoinho já disponível pode servir à exploração/saída quando apropriada; não serve à conversa de perna única ou ao furacão grande. Se o objetivo for também substituir sua arte por frames estritos 32×64, criar uma variante coerente sobre a mesma base/identidade, preservando os PNGs legados até validar o novo conjunto. O slot `whirlwind_canvas` aceita o tamanho real do novo Resource, sem alterar a protagonista.

## Demais pendências por Task

| Task | Destino proposto relativo a `assets/art/` | Medidas / frames propostos | Uso e reaproveitamento |
| --- | --- | --- | --- |
| 2.12 | `props/stage_01/house/spilled_milk.png` | 32×32; 2 frames | Leite derramado com carinhas. A jarra atual é reutilizável; a poça não existe. |
| 2.12 | `props/stage_01/house/horsehair_barrier.png` | 96×32; 1 frame | Crina trançada na escada. O fio pequeno sobre a cama existe; não é a barreira da escada. |
| 2.12 | `props/stage_01/house/gorro_graffiti.png` | 64×48; 1 frame | Gorro desenhado a carvão; frase “Quem perde o gorro perde o rumo” em Label pixel separado ou diálogo, para legibilidade. |
| 2.12 | Sem PNG novo obrigatório | Recortes existentes | Almofada no lustre, móveis deslocados, relógio caótico, bilhete Obrigado pela rolha e estante sem garrafa podem usar atlas/nós atuais. A **variante caótica editável ainda precisa ser montada e testada**, não está pronta por esses recortes existirem. |
| 2.13 | `props/stage_01/street/hanging_clothes/` | 32×48; 4 frames por peça | Camisa/roupa em poste. Reutilizar os mesmos tecidos do varal quando coerente. Pegadas já existem; conferir recortes e traçado na implementação. |
| 2.14 | `props/stage_01/house/clothesline/mismatched_socks.png` | 32×32; 4 frames | Meias sem par e pingos. |
| 2.14 | `props/stage_01/house/clothesline/shirt.png` | 32×48; 4 frames | Camisa invertida com número/buraco. Texto narrativo legível no diálogo, sem depender de letras minúsculas desenhadas. |
| 2.14 | `props/stage_01/house/clothesline/dress_note.png` | 32×48; 4 frames | Vestido e bilhete preso; manter mesma iluminação. |
| 2.14 | `props/stage_01/house/clothesline/fake_cap.png` | 32×32; 6 frames de balanço | Seis instâncias com fases diferentes, não seis novos itens no inventário. O gorro verdadeiro permanece parado e distinguível pelo texto/temperatura/cheiro. |
| 2.14 | Reusar `items/stage_01/gorro_saci.png` como candidato | 32×32; 1 frame existente | Ícone relacionado e limpo; para varal, compor pregador/apoio e aprovar visualmente, sem alterar o ícone da UI. Não considerar o puzzle pronto só porque o PNG existe. |
| 2.14 | `effects/stage_01/saci/micro_whirlwind/` | 32×32; 6 frames; sem loop | Pulso do gorro; som/silêncio já têm infraestrutura em 2.6. |
| 2.14 | Opcional `props/stage_01/house/clothesline/sheet.png` | 64×32; 4 frames | Lençol decorativo; não vira sexto requisito de investigação. |
| 2.15 | `effects/stage_01/saci/pipe_smoke/` | 32×32; 6 frames; loop | Fumo fino sobre o banco/cachimbo. Ícone do cachimbo e identidade lógica já existem. |
| 2.16 | `props/stage_01/street/mural/panel_01.png` | **40×48**; 1 frame | Menino da mata/Saci-Cererê entre rios e árvores. |
| 2.16 | `props/stage_01/street/mural/panel_02.png` | **40×48**; 1 base + 4 frames de brilho | Bambu com mãozinha; brilho sincronizado pelo controlador ao bambuzal. |
| 2.16 | `props/stage_01/street/mural/panel_03.png` | **40×48**; 1 frame | Roda de capoeira; representação de uma versão da lenda, sem impor origem única. |
| 2.16 | `props/stage_01/street/mural/panel_04.png` | **40×48**; 1 frame | Gorro e referências a outras narrativas; manter o mesmo menino. |
| 2.16 | `props/stage_01/street/mural/panel_05.png` | **40×48**; 6 frames; loop | Vento e travessuras/objetos. |
| 2.16 | `props/stage_01/street/mural/panel_06.png` | **40×48**; 1 frame | Mãos nas bordas e centro vazio para pintar. Frase em Label/diálogo, sem copiar o concept. |
| 2.16 | `props/stage_01/street/mural/symbol_{gorro,bambu,redemoinho}.png` | 32×32; 1 frame cada | Três decalques originais com transparência, margem para caber no quadro 6. Ícones da mochila não contam como seis grafites concluídos. |
| 2.17 | `props/stage_01/street/cracked_bamboo.png` | 32×48; 1 base + 4 frames de brilho | Gomo rachado e mãozinha, coerente com quadro 2. O bambuzal atual existe, este gomo não. |
| 2.17 | Reusar página/atlas, ou `props/stage_01/street/newspapers_1917.png` | 32×32; 1 frame | Jornais no bonde; a leitura de 1917 fica no diálogo/diário, sem exigir texto legível em 32 px. |
| 2.19 | Usar tiles atuais de estrutura, pedra e escada | Tiles de 32×32 existentes | Ladeira/terraço ainda não montados. Só pedir peças extras se os recortes reais não resolverem; o furacão grande continua essencial. |
| 2.20 | Nenhuma geração agora | Quadrado vermelho autorizado | Manter ponto para futura arte de batalha. O asset remoto encontrado não substitui automaticamente a decisão do usuário. |
| 2.21 | `effects/stage_01/saci/petals/` | 32×32; 6 frames; sem loop | Pétalas na amizade, luz quente, cores que não confundam com dano. |
| 2.21 | `props/stage_01/street/mural/flowers.png` | 32×32; 1 frame repetível | Flores no muro após amizade. Paleta do template de vegetação. |
| 2.21 | Reusar garrafa e quadros com efeitos de paleta | Sem PNG novo obrigatório | Captura: garrafa cheia/pesada, quadros desbotados e retorno à ordem. Não apagar pintura/progresso; encenar e validar em 2.21. |
| 2.23 | Cinco páginas da introdução e áudio | Ver `BOOK_INTRO.md` / `assets/audio/README.md` | Pendências anteriores continuam abertas; não são supridas pela entidade de exploração. |

As quantidades de PNGs/sheets dependem do formato de exportação escolhido; cada célula deve permanecer no tamanho indicado. Propostas de novos efeitos têm pivô central inferior, transparência real e nenhuma colisão ofensiva de exploração. Preparar metadados de autoria/licença e nome/ID da geração quando houver.

## Briefings para PixelLab no navegador

**Personagem, após restaurar/inspecionar a base:** usar a composição do manequim em 32×64 como referência de pose, proporção, linha e sombra; customizar com pele brasileira natural, shorts vermelhos rasgados, gorro vermelho cônico clássico e uma única perna centralizada. Perspectiva RPG top-down 3/4. Manter rosto, gorro, escala e apoio em todos os frames/direções. O concept é só inspiração semântica; não fornecer recorte dele como sprite. Gerar uma ação por vez, revisar anatomia e depois animar a mesma identidade. **Não iniciar nova geração humana enquanto a base obrigatória estiver ausente.**

**Fumaça/vento:** usar o Saci de produção já inspecionado e os templates de cenário como referência de paleta/traço. Poeira cinza/creme e marrom quente, contorno seletivo, aglomerados de pixels limpos, nenhuma luz 3D ou borrão. Canvas transparente, crescimento a partir do centro inferior, frames separados. Fumaça da garrafa e furacão grande são efeitos diferentes.

**Mural:** usar atlas colonial de produção/template White/Props para paleta e espessura de contorno, com textura de pintura sobre muro. Seis artes originais 40×48, personagens consistentes e conteúdo da tabela; o sexto mantém espaço para símbolo. O brilho e textos longos devem ser nós/efeitos separados. Não recortar `concept_street.jpg` nem a capa do menu.

**Roupas/caos/pistas:** mesma vista top-down 3/4 e iluminação dos atlas. Contornos escuros de um pixel, sombras simples, transparência fora do objeto. Preservar a leitura visual do objeto em tamanho nativo; não pintar fundo junto do sprite nem incluir textos que só se leem ampliados.

## Validação e próximos passos

Abra `stages/stage_01_saci/saci_visual_preview.tscn` e pressione **F6** para inspecionar as quatro direções. E/Enter/Espaço alternam as poses idle e os cinco frames walk a 8 FPS. A prévia deixa explícita a ausência da forma de uma perna e não usa Player, HUD, inventário nem avanço narrativo. F5 continua começando pelo menu existente.

`tests/test_saci_actor.gd` verifica fontes reais, recortes, margens/pivôs, direções, validação de clipes, recusa explícita da arte ausente, isolamento entre Resources, desligamento da colisão e teclado da prévia. A textura sintética usada num teste fica apenas em memória e não é arte de produção. Teste headless não aprova acabamento gráfico nem transforma um slot vazio em asset entregue.

A suíte revelou ainda uma regressão já presente no roteiro antes desta Task: as listas de efeitos de leitura, as páginas do tutorial de chegada e os índices `source_paragraphs` estavam ausentes do `.tres`. Foram repostos apenas esses metadados, usando as condições de pista e a tabela de rastreabilidade existentes, sem remover/alterar falas, escolhas ou UIDs. `test_catalog_roundtrip_preserves_reading_effects_tutorial_and_source_indices` grava e recarrega o Resource para proteger esse conteúdo. Não foi atribuída uma causa à perda dos campos sem evidência.

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_saci_actor.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Para concluir 2.9: identificar os novos assets de uma perna com as ações reais; vincular `one_leg` em `saci_visuals.tres`, respeitar canvas/pivô, rever a prévia e repetir os testes. A preparação isolada da conversa de 2.10 está em [SACI_CONVERSATION.md](SACI_CONVERSATION.md), sem ativação no mapa e sem efeitos da garrafa. Saída/desmaio de 2.11 continuam pendentes. Os marcadores de Saci/despertar documentados na Task 2.8 ainda devem ser validados nessas cenas.

**Validação de 19/11/2026:** 11/11 testes específicos do Saci e **234/234 testes do projeto**, 9.935 asserts, via Godot 4.7.2/GUT 9.6.1 headless, sem erros ou warnings. Os três scripts novos passaram em `--check-only`; a prévia iniciou com `--quit-after 3` sem erros. Comparação de hashes confirmou todos os mapas, Player, PNGs/imports originais, templates disponíveis e project.godot intactos. Inspeção de recortes por CPU não substitui a revisão gráfica nativa final. Esses resultados aprovam a infraestrutura e o material existente, não os assets ainda ausentes.
