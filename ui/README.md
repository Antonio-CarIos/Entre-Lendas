# Menu principal — Sprint 02, Task 2.1

**Task 2.7:** o HUD exibe o objetivo da fase durante a exploração e o oculta nos modais. A chegada a Santa Teresa apresenta narração/tutorial antes de liberar movimento; portas podem usar roteiro opcional para Sim/Ainda não. Detalhes da primeira entrada e retorno: [CITY_ARRIVAL.md](../stages/stage_01_saci/CITY_ARRIVAL.md).

Pressione **F5** para iniciar em `ui/main_menu.tscn`. A capa original fica inteira acima dos botões; uma segunda camada da mesma imagem, escurecida e com proporção preservada, preenche o fundo. O layout foi verificado em 640 × 360, 360 × 640, 960 × 360 e 320 × 240.

- **Direcionais:** escolher opções; esquerda/direita ajustam o volume quando o slider está selecionado.
- **E/Enter:** confirmar. **Esc:** retornar; na tela principal, abre a confirmação de saída.
- **Novo Jogo:** usa o serviço `WorldState.scene_transition`, bloqueia input durante o fade, limpa inventário/decisões/coletas e abre a introdução existente da colega.
- **Opções:** volumes e mudo de Master/Music/SFX, velocidade do texto e redução de tremor/flashes, persistidos em `user://preferences.cfg`. ↑/↓ percorrem a lista com rolagem automática, ←/→ ajustam sliders, E/Enter alternam opções. Controle e integração da Task 2.6 estão documentados em [core/audio/README.md](../core/audio/README.md); os arquivos de áudio e a mistura final continuam pendentes.
- **Créditos:** equipe, colaboração na introdução, Anokolisa/World Build e fonte do projeto. Direcionais para cima/baixo permitem rolar o texto em janelas pequenas.
- **Sair:** confirmação com Não selecionado inicialmente; Sim fecha o executável.

Não existe botão Continuar antes da implementação da Task 2.22. A propriedade `new_game_confirmation_required` prepara a integração com salvamento: quando habilitada, Novo Jogo pergunta antes de substituir o progresso. Nesta entrega, não há detecção fictícia de saves.

## Integração e limites desta entrega

Somente a cena inicial foi alterada em `project.godot`. Os mapas, a composição/arte/shaders da introdução e as transições de exploração permanecem preservados. F6 continua executando o mapa aberto para edição.

`SceneTransition.open_scene()` atende telas sem Player e conserva o fade persistente; `travel_to()` continua cuidando de portas e escadas. Destino ausente é recusado antes do reset, e o menu continua utilizável. Os controles da cena de destino ficam suspensos até terminar o fade.

A entrega original da Task 2.1 terminava ao entrar na cutscene existente. A **Task 2.4** completou leitura por teclado, efeitos e saída até a cidade; a arte de páginas ainda pendente está documentada em [BOOK_INTRO.md](../stages/stage_01_saci/BOOK_INTRO.md).

Para a futura **Task 2.20**, o usuário pediu um **quadrado vermelho como representação provisória do Saci em batalha**, enquanto prepara os assets. Essa exceção autoriza o placeholder de combate, sem alterar a arte de exploração existente.

## Validação

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_main_menu.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Os testes usam arquivo de preferências próprio e restauram áudio, janela, cena e estado global. A suíte do menu inclui chegada real à introdução, proteção contra duplo acionamento/input no fade, cancelamento da confirmação de nova partida, falha de destino sem perda de progresso, persistência/validação das opções e geometria dos painéis em diferentes proporções.

Validação da Task 2.1: **8/8 testes do menu e 110/110 testes do projeto aprovados** na entrega original, sem erros ou warnings na suíte completa. A abertura da cena principal também foi executada por CLI. Seu checklist já foi aplicado à Sprint 02. A fundação narrativa da Task 2.2 está documentada em [core/stages/README.md](../core/stages/README.md); as próximas entregas continuam seguindo a ordem da sprint, uma por pedido.

## Diálogos e cutscenes — Task 2.3

`GameplayHUD.start_dialogue(catalog, entry_id)` apresenta narrador/personagem, páginas e respostas por E/Enter, direcionais e Esc quando permitido. O primeiro acionamento revela o texto; outro confirma a resposta. O inventário não substitui um diálogo ou uma sequência ativa. As confirmações de coleta/portas e a fala simples da quitandeira continuam funcionando.

Para testar sem avançar a história real, abra **`ui/dialogue_preview.tscn` e pressione F6**. A prévia usa estado isolado e a conversa de três respostas do Saci. Por F5, Novo Jogo agora passa pelo livro e chega à cidade; veja [BOOK_INTRO.md](../stages/stage_01_saci/BOOK_INTRO.md).

O novo `DialogueView` usa o tema e a fonte pixel existentes, mede o texto para paginar e acompanha o foco ao rolar respostas. O layout foi verificado em 640×360, 360×640, 960×360 e 320×240. A documentação de Resources, condições, efeitos e sequências está em [core/dialogue/README.md](../core/dialogue/README.md).

## Diário — Task 2.5

Tab abre o inventário; J alterna Mochila/Diário. As seções também são acessíveis com ↑ na primeira linha, ←/→ e E/Enter. No diário, ↑/↓ escolhem páginas NOVA/LIDA; E abre opções, ←/→ escolhem Examinar/Ler. A última confirmação da leitura registra a pista, sem contar novamente nas releituras. Esc retorna; Tab/I fecha e restaura movimento. São sete pistas-base e uma página bônus de 31 de outubro, liberada pelas sete leituras. A distribuição das pistas nos POIs continua nas próximas tasks. Contratos, Resources e testes: [core/journal/README.md](../core/journal/README.md).
