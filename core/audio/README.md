# Áudio e acessibilidade — Task 2.6

No menu, **Opções** oferece volume geral, música, efeitos sonoros, mudo por canal, velocidade do texto (15–120 caracteres/s) e redução de tremor/flashes. ↑/↓ navegam, ←/→ ajustam sliders, E/Enter alternam seleções e Esc retorna. A lista rola acompanhando o foco, inclusive em janelas pequenas. As preferências ficam em `user://preferences.cfg`, separadas do progresso e preservadas em Novo Jogo.

**Situação da entrega:** controle e integração funcionais, com catálogo de **24 arquivos ainda ausentes**. O jogo continua silencioso até esses streams serem atribuídos. Não há áudio final nem mistura aprovada nesta entrega. Caminhos, usos, duração, origem/licença e revisão pendente: [assets/audio/README.md](../../assets/audio/README.md).

## Serviço e dados

- `AudioManager` é o único Autoload de áudio, após EventBus/WorldState. `default_bus_layout.tres` expõe Master/Music/SFX também no editor; a inicialização garante canais ausentes sem duplicá-los ou renomear canais existentes.
- `MenuPreferences` continua sendo a lógica pura de preferências (`RefCounted`), agora com volumes/mudos dos três canais e acessibilidade. Carregamento valida tipos, limites e valores finitos; gravação preserva chaves futuras. `AudioManager.preferences` é a instância compartilhada de produção. O caminho customizável do menu permite testes isolados.
- `AudioCue` e `AudioCatalog` são Resources. O catálogo `stage_01_audio.tres` mantém stream, autor/origem e licença por ID. Um stream ausente não produz warning nem substituição inventada; `get_missing_cues()` expõe as pendências.
- `AudioDirector` é a lógica pura (`RefCounted`) de estado, envelope e silêncio. Recebe tempo externo; não depende de áudio ou SceneTree. `AudioManager` traduz esse estado para os players e buses reais.

## Transições e sons

Há **um único AudioStreamPlayer para BGM**. Pedir outra faixa baixa o ganho da atual, troca o stream em ganho zero e sobe o novo ganho. Pedidos rápidos mantêm somente o destino mais recente; repetir a mesma faixa não reinicia a reprodução. A transição usa envelope padrão de 0,4 s por lado, sem duas BGMs concorrentes. Ambiente usa outro player no bus SFX e não substitui a música. Loops de música/ambiente são configurados numa cópia do stream, preservando o Resource original; SFX não ficam em loop.

`set_scene_context(scene_path)` identifica menu, livro e os mapas reais. `HouseLevel` informa o mapa ao carregar; o serviço também acompanha `SceneTransition.transition_finished` e as mudanças narrativas. Mapeia casa organizada, conversa, redemoinho, investigação, clímax, recuperação e epílogos A/B para seus IDs. Falha de viagem conserva o contexto anterior. Mapas abertos por F6 funcionam com o contexto correspondente sem ativar o roteiro.

`play_sfx(id)` atende UI/coleta/portas/páginas. `play_positional(id, world, global_position)` cria um `AudioStreamPlayer2D` no mapa, bus SFX, atenuação/distância máxima de 480 px. Terminar a reprodução remove o player; trocar de mapa remove os sons posicionais junto com seu dono. A API prepara a risada da Task 2.9/POIs, sem inventar gravações. Vozes pontuais têm limite de 16; streams e canais errados são recusados silenciosamente. As etapas SOUND do `CutsceneCoordinator` também usam o bus SFX.

## Gorro e relógio

Uma concessão narrativa válida de `gorro_saci` por `Stage01State.grant_quest_item()` inicia o efeito automaticamente. O evento `hat_audio_started` é reservado antes dos sinais reentrantes; revisitar/coletar novamente não estende o efeito. O puzzle e seu texto serão ligados no mapa na Task 2.14.

`begin_hat_silence()` mantém **Music e SFX silenciados por exatamente 3.000.000 µs**, sem alterar o volume/mudo escolhido pelo jogador ou bloquear a protagonista por conta própria. `AudioDirector` armazena microssegundos inteiros. O serviço recebe tempo monotônico de `Time.get_ticks_usec()` e processa com `PROCESS_MODE_ALWAYS`, portanto a pausa do mapa não estica os três segundos. Durante a janela, o contexto pode mudar: o retorno usa a música atualmente pedida, com `pitch_scale = 0.85`, sem ressuscitar uma faixa do mapa anterior.

O sinal `hat_silence_finished` informa o término uma vez. `cancel_temporary_effect()` restaura a afinação normal e aplica os valores **atuais** das preferências. Reset/Novo Jogo e entrada no menu cancelam o efeito. Mudo do usuário nunca é desfeito pela restauração; mudar as opções durante o silêncio tampouco o encerra cedo. O pitch mais grave permanece na sessão até cancelamento/reset; não altera o tamanho da pausa nem o contador de pistas.

## Acessibilidade e continuidade

`DialogueView` usa a velocidade compartilhada e recebe alterações de opções por sinal, preservando a separação entre revelar texto e confirmar/avançar. O diário já apresenta cada trecho completo sem espera de digitação. Redução de efeitos no livro elimina brilho, borda da dissolução e letras em movimento, mantendo o fade gradual, a duração, o texto “As letras escapam das páginas…” e o destino.

`CutsceneStep.intense_effect` marca somente apresentação cosmética (tremor, animação ou flash). Quando a redução está ativa, essas animações/câmeras/fades são omitidas; duração, EFFECT, DIALOGUE, escolhas, concessões e fades de viagem continuam. Não marcar animações essenciais como cosméticas. As futuras cenas devem conservar textos e pistas visuais estáveis para todos os sons/cores usados no roteiro.

## Verificação

`tests/test_audio_and_accessibility.gd` exercita relógio, troca rápida de música, preferências, canais, mute durante/restauração após o silêncio, concessão única do gorro, pausa/viagem, players reais/posicionais, interface por teclado, velocidade do texto, livro reduzido e sequência que preserva efeitos lógicos. WAVs silenciosos criados em memória são **fixtures de teste**, não assets de produção. Os testes restauram buses, preferências, catálogo e processamento; não exigem dispositivo de áudio.

```bash
env XDG_DATA_HOME=/tmp/entre_lendas_task26/data XDG_CONFIG_HOME=/tmp/entre_lendas_task26/config godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_audio_and_accessibility.gd -gexit
env XDG_DATA_HOME=/tmp/entre_lendas_task26/data XDG_CONFIG_HOME=/tmp/entre_lendas_task26/config godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Validação funcional de 19/11/2026: **12/12 testes específicos e 196/196 testes do projeto**, 9.138 asserts, sem erros ou warnings na suíte completa, Godot 4.7.2 / GUT 9.6.1.

A revisão auditiva com assets finais e a revisão gráfica nativa não foram realizadas neste ambiente headless. O aceite sonoro final permanece pendente; a próxima implementação narrativa é **Task 2.7 — Primeira chegada a Santa Teresa**.
