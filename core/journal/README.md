# Diário de Lendas do Brasil — Task 2.5

No mapa, **Tab** abre a mochila. **J** alterna Mochila/Diário; também é possível usar **↑ na primeira linha → ←/→ → E/Enter** para escolher uma seção. No diário, ↑/↓ escolhem a página, E/Enter abre as opções e ←/→ escolhem **Examinar** ou **Ler**. Esc volta um nível; Tab/I fecha a tela e devolve o controle ao Player. Esses atalhos pertencem à interface e preservam o Input Map existente.

As páginas aparecem conforme a investigação as desbloqueia. O inventário e o diário começam vazios em Novo Jogo. A ligação dos POIs aos desbloqueios será encenada nas Tasks 2.8 e 2.12–2.17; a Task 2.5 não antecipa essas recompensas. Examinar mostra origem e ilustração disponível. Ler apresenta o texto integral em trechos medidos com a fonte pixel; **E/Enter após a última página** confirma a leitura. Esc, Tab, troca de seção ou saída da cena durante a leitura não a concluem. Não é necessário usar o mouse.

## Conteúdo e estado

`JournalEntry` é um Resource: `id`, `title`, `text`, `origin`, `illustration`, `dialogue_id`, `bonus`. As oito páginas estão em `pages/stage_01/`; seus textos completos correspondem às entradas revisadas do catálogo narrativo, com teste de consistência. Cachimbo e gorro usam as texturas originais limpas como ilustração. As demais páginas são textuais enquanto não houver ilustrações próprias; nenhum concept foi recortado nem imagem nova gerada.

| ID | Origem | Entrada do roteiro |
| --- | --- | --- |
| `clue_origem_saci` | Memória do cachimbo, casa ou praça | `journal.origin` |
| `clue_poder_gorro_parede` | Grafite da casa caótica | `journal.wall_power` |
| `clue_gorro_vermelho` | Varal do quintal | `journal.cap` |
| `clue_mural_origens` | Cinco quadros informativos | `journal.mural` |
| `clue_inquerito_1917` | Jornais no bonde | `journal.inquiry` |
| `clue_crina_cavalo` | Cavalo do quintal | `journal.horse` |
| `clue_bambu_rachado` | Bambuzal | `journal.bamboo` |
| `clue_dia_do_saci_bonus` | Sete pistas-base lidas | `journal.bonus` |

`WorldState.journal` é uma fachada pura (`RefCounted`) sobre o **mesmo** `WorldState.stage01`, sem Autoload adicional ou cópia de progresso. `get_entries()` retorna somente páginas desbloqueadas, em ordem estável; `get_new_count()` e `is_read(id)` distinguem NOVA/LIDA. Receber/reabrir/examinar uma página não altera o contador. As páginas não ocupam slots de objetos nem alteram quantidades/receitas. As duas páginas genéricas de teste do inventário continuam independentes das sete pistas.

`JournalSystem.make_dialogue(id)` cria um catálogo transitório para `DialogueSession`, condicionado ao desbloqueio e com efeito `read_clue:id` ao confirmar o último trecho. Cancelar/abortar antes disso não aplica o efeito. O roteiro original recebeu a mesma condição/efeito em suas oito entradas `journal.*` correspondentes, permitindo concluir a leitura em diálogo ou no diário com **um único registro de ID**. Os Resources compartilhados não armazenam o estado de leitura.

As falas `mural.panel_1`…`mural.panel_6` usam `read_mural_panel:N` somente depois de concluir todo o texto do quadro. O adaptador registra os painéis; terminar 1–5 em qualquer ordem desbloqueia e registra como lida **uma** pista agregada. O quadro 6 não acrescenta uma pista-base. Cancelar/reler quadros não antecipa nem duplica a contagem. Isso prepara a integração dos componentes de mapa da Task 2.16.

Ler as sete pistas-base libera a página **Dia do Saci — 31 de outubro** como NOVA. Sua leitura não eleva `pistas_saci_lidas` para oito. A quantidade continua derivada dos IDs únicos no `Stage01State`. Trocar de cena/recriar o HUD mantém o estado na sessão; Novo Jogo limpa esse mesmo objeto. Salvamento em disco pertence à Task 2.22.

## Interface e validação

`ui/journal_panel.tscn/.gd` reutiliza o fundo full-screen, o tema/fonte pixel e o scrollbar existente do inventário. A lista fica à esquerda, as opções à direita no alto, e o painel informativo aparece ao Examinar/Ler. O inventário de objetos mantém seus slots sem painel atrás, brilho exclusivo do mapa, insights, opções por categoria e receita confirmada fita + peneira. O diário não interfere nos modais prioritários de diálogo, cutscene e viagem.

`tests/test_journal_system.gd` cobre conteúdo, leitura incompleta/única, diálogo versus diário, agregação do mural, bônus, estado entre instâncias, Novo Jogo, teclado real, foco, rolagem, atualização da UI, interrupções e geometria em 640×360, 360×640, 960×360 e 320×240. Também foram inspecionadas prévias CPU com texturas e fonte reais em 640×360. A revisão gráfica nativa no Godot permanece no acabamento da Task 2.23: esta sessão não tem acesso a uma tela X11/Wayland.

```bash
env XDG_DATA_HOME=/tmp/entre_lendas_task25/data XDG_CONFIG_HOME=/tmp/entre_lendas_task25/config godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_journal_system.gd -gexit
env XDG_DATA_HOME=/tmp/entre_lendas_task25/data XDG_CONFIG_HOME=/tmp/entre_lendas_task25/config godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Validação de 19/11/2026: **16/16 testes do diário e 184/184 testes do projeto**, 8.972 asserts, sem erros ou warnings na suíte completa. A verificação de sintaxe do sistema puro e a abertura da cena inicial por CLI também passaram.

A próxima entrega é **Task 2.6 — Áudio, apresentação e opções acessíveis**.
