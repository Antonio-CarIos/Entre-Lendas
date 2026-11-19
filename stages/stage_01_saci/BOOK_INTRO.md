# Introdução do livro — Task 2.4

A Task 2.7 acrescenta a narração/tutorial da chegada após terminar o fade na cidade. O Player permanece parado durante essa leitura e recebe o objetivo ao concluir; detalhes em [CITY_ARRIVAL.md](CITY_ARRIVAL.md).

Integração da Task 2.6: o livro seleciona seu contexto de áudio e chama `page_turn`; os streams ainda estão pendentes em `assets/audio/README.md`. A velocidade do texto segue Opções. Com redução de efeitos, brilho, borda da dissolução e letras em movimento são omitidos, mantendo o texto, fade gradual, duração e chegada à cidade.

**F5:** Menu → Novo Jogo → biblioteca/livro → Santa Teresa. Para editar/testar só a introdução, abra `scene_01_book_intro.tscn` e pressione **F6**.

- **E/Enter:** mostrar capa, iniciar leitura, revelar texto e avançar. Cada acionamento tem uma única função.
- **Esc:** pular a apresentação e chegar à cidade, inclusive durante abertura, troca de página e dissolução. Não concede itens nem marca pistas como lidas.
- Clique esquerdo permanece como alternativa; o botão Pular também funciona. Mouse não é necessário.

## Sequência e composição

O cenário `inicio.jpg`, a capa `livro_aberto.png`, a textura `rasgo_1.webp` e os shaders recebidos foram preservados. A biblioteca continua ao fundo; a capa mantém o enquadramento central original de **535,2 × 298,4** na tela base 640 × 360. Janelas menores reduzem o livro proporcionalmente. Texto e botões usam a fonte pixel e o tema já existentes.

Apesar do nome, **`livro_aberto.png` é uma capa fechada**. O material recebido não contém ilustrações de páginas abertas. A alternativa funcional mantém essa capa e apresenta a leitura em um painel; não usa `.import` como imagem nem fabrica novas ilustrações.

`DialogueSession` apresenta os três textos existentes no catálogo: `book.open` → `book.saci` → `book.light`. O título Lendas do Brasil e o tutorial aparecem na biblioteca. A última página apresenta Saci-Pererê; depois há brilho, dissolução e letras desenhadas/animadas com a fonte do jogo. Não foi criado um novo sprite para substituir a arte ausente.

O shader de virada conserva a mistura entre texturas e a dissolução recebidas. Foi acrescentado brilho e corrigido o respeito à modulação do nó, para a opacidade da capa funcionar. O shader de desfoque também respeita essa opacidade. Materiais do livro são duplicados por instância; outro Novo Jogo não herda dissolução, brilho ou progresso de uma execução anterior.

`BookIntroLetters` é uma animação de texto (`Control._draw`), sem novo bitmap. Imagens e catálogo compartilhados não são modificados em runtime. A troca de página bloqueia confirmações simultâneas e repetições de tecla; o skip continua disponível durante os efeitos.

## Arte pendente e ordem de carregamento

Coloque os originais abaixo em `assets/art/ui/stage_01/book_intro/`, preservando transparência e proporções compatíveis com a capa. Eles são procurados em ordem explícita; o código não depende da ordem de enumeração do diretório.

| Índice | Arquivo | Uso |
| --- | --- | --- |
| 0 | `livro_aberto.png` — disponível | Capa recebida. |
| 1 | **`livro - abrindo.png` — ausente** | Abertura anterior ao texto. |
| 2 | **`livro - aberto completo.png` — ausente** | Primeira página de leitura. |
| 3 | **`livro - virando.png` — ausente** | Página do Saci. |
| 4 | **`livro - virando 2.png` — ausente** | Última página, letras brilhando. |
| 5 | **`livro - desmanche.png` — ausente** | Dissolução final. |

`imagens_do_livro` continua exportado e aceita atribuições manuais nesses índices. `get_missing_art()` retorna uma cópia dos caminhos ainda não atendidos. Se faltar uma página, a capa é mantida e o texto continua; mesmo sem nenhuma textura opcional ou sem ShaderMaterial, leitura e saída não travam.

`rasgo_1.webp` contém dois fragmentos de papel em um fundo escuro. Continua sendo usado como ruído do shader original, não como ilustração de livro aberto. Não há justificativa para reutilizar esses fragmentos como páginas finais completas. As cinco imagens faltantes permanecem pendência de acabamento da **Task 2.23**.

## Entrada na cidade e falhas

A cena configura explicitamente `proxima_cena = santa_teresa_map.tscn` e `arrival_spawn = PlayerEntrySpawn`. O placeholder recebido permanece como arquivo histórico, sem participar do fluxo.

`SceneTransition.open_map(source, scene_path, spawn_name, next_phase, completion_event)` atende a saída de uma tela `Control`, sem exigir Player na origem. Valida cena, Player/spawn do destino e transição de fase antes de iniciar; revalida a origem e a fase ao cobrir a tela. Usa referência fraca da origem para permitir remoção segura durante o fade.

Após aceitar a troca de cena e sob preto, registra `book_finished` e avança de `book_intro` para `scene_2_sunset`. A cidade já recebe o estado correto em `_ready()`. Posiciona a protagonista em **(512, 448)**, olhando para cima, atualiza câmera/física e só libera os controles após revelar o mapa. A rota normal e o skip usam essa mesma saída; o evento de leitura já registrado não é duplicado.

Destino/spawn ausente ou fase incompatível deixam a introdução utilizável, sem tela preta permanente, registro falso de chegada ou regressão de progresso. E/Enter/Esc permitem tentar novamente após corrigir a configuração. Remover a origem durante o fade libera a cortina e não avança a história. `open_scene()` continua atendendo menu/telas; `travel_to()` continua atendendo portas/escadas.

Executar a introdução isolada por F6 ativa `book_intro` se o estado ainda estiver inativo. Abrir um mapa por F6 continua sem ativar o roteiro. Um Novo Jogo pelo menu conserva seu reset completo. Carregar a introdução artificialmente no meio de outra fase não faz o estado regredir.

## Verificação e limites

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_book_intro.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

**14/14 testes específicos e 168/168 testes do projeto aprovados**, sem erros, warnings ou Nodes órfãos. Cobertura: assets/ordem, teclado, texto completo, avanço único, spam/echo, skip em cada etapa, chegada real/estado/spawn/câmera, materiais isolados, segundo Novo Jogo, arte/material ausente, configuração inválida, revalidação de fase e remoção da origem durante o fade. Os testes preservam o cenário e o estado externo entre casos.

Foram inspecionadas as três imagens recebidas e a composição de capa/leitura por uma prévia CPU baseada nas texturas, geometria real e fonte da cena. O layout foi verificado em 640×360, 360×640, 960×360 e 320×240. A sessão não tem acesso a um display X11/Wayland: **o desfoque, brilho e dissolução precisam de revisão gráfica no editor**. Headless não valida a aparência final desses shaders; a alternativa textual não fecha o aceite de arte final da Task 2.23.

Nenhum mapa, TileMapLayer, prop, colisão, Player ou configuração principal do projeto foi alterado nesta Task. Narração da chegada e interações narrativas da cidade serão encenadas na Task 2.7; o diário visual pertence à próxima **Task 2.5**.
