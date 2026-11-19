# Áudio da Fase 1 — inventário e pendências

Auditoria de 19/11/2026: `assets/audio/` continha somente `.keep`; não foram encontrados WAV/OGG/MP3/FLAC/OPUS/AIFF de produção no projeto. **Os 24 sons abaixo ainda não foram fornecidos.** Não há trilha final ou mistura sonora aprovada. Nenhum áudio foi baixado, gerado ou presumido livre de direitos.

O catálogo editável é `res://core/audio/stage_01_audio.tres`. Cada `AudioCue` tem ID, categoria, `stream`, `source` e `license`. Neste momento todos os streams estão vazios; origem e licença estão pendentes para todos. Ao receber o arquivo original, guardá-lo no caminho indicado, atribuí-lo ao `stream` correspondente e registrar autor/origem e licença/permissão. O catálogo pode referenciar WAV, OGG ou MP3; os caminhos abaixo são nomes propostos para organizar a entrega, não arquivos já existentes nem carregamentos obrigatórios.

| ID no catálogo | Caminho proposto sob `assets/audio/` | Conteúdo / duração aproximada | Situação / origem / licença |
| --- | --- | --- | --- |
| `menu` | `music/menu.ogg` | Tema de abertura, loop 30–90 s | Ausente / não informada / não informada |
| `book` | `music/stage_01/book.ogg` | Leitura e suspense do livro, loop 30–60 s | Ausente / não informada / não informada |
| `city_sunset` | `music/stage_01/city_sunset.ogg` | Chegada a Santa Teresa, loop 30–90 s | Ausente / não informada / não informada |
| `house_clean` | `music/stage_01/house_clean.ogg` | Casa silenciosa e fumo, loop 30–60 s | Ausente / não informada / não informada |
| `saci_conversation` | `music/stage_01/saci_conversation.ogg` | Capoeira/berimbau e percussão na conversa, loop 30–90 s | Ausente / não informada / não informada |
| `whirlwind` | `music/stage_01/whirlwind.ogg` | Vento crescente e desmaio, loop 15–30 s | Ausente / não informada / não informada |
| `investigation` | `music/stage_01/investigation.ogg` | Investigação livre, loop 45–90 s | Ausente / não informada / não informada |
| `climax` | `music/stage_01/climax.ogg` | Subida e confronto por turnos, loop 45–90 s | Ausente / não informada / não informada |
| `epilogue_capture` | `music/stage_01/epilogue_capture.ogg` | Consequência da captura, loop 30–60 s | Ausente / não informada / não informada |
| `epilogue_friendship` | `music/stage_01/epilogue_friendship.ogg` | Amizade e pétalas, loop 30–60 s | Ausente / não informada / não informada |
| `recovery` | `music/stage_01/recovery.ogg` | Retorno recuperável à investigação, loop 30–60 s | Ausente / não informada / não informada |
| `city_wind` | `ambience/stage_01/city_wind.ogg` | Ambiente/vento da rua e quintal, loop 15–45 s | Ausente / não informada / não informada |
| `house_ambience` | `ambience/stage_01/house.ogg` | Madeira e ambiente da casa, loop 15–45 s | Ausente / não informada / não informada |
| `bamboo_wind` | `ambience/stage_01/bamboo_wind.ogg` | Vento nos gomos do bambu, loop 15–30 s | Ausente / não informada / não informada |
| `ui_move` | `sfx/ui/move.wav` | Movimento de foco, 0,03–0,15 s | Ausente / não informada / não informada |
| `ui_confirm` | `sfx/ui/confirm.wav` | Confirmação/coleta, 0,1–0,3 s | Ausente / não informada / não informada |
| `page_turn` | `sfx/stage_01/page_turn.wav` | Virada de página, 0,2–0,6 s | Ausente / não informada / não informada |
| `door_open` | `sfx/stage_01/door_open.wav` | Porta de madeira, 0,3–1 s | Ausente / não informada / não informada |
| `saci_laugh` | `sfx/stage_01/saci_laugh.wav` | Risadinha espacializada, 0,5–2 s | Ausente / não informada / não informada |
| `cork_pop` | `sfx/stage_01/cork_pop.wav` | Rolha / Pop, 0,1–0,5 s | Ausente / não informada / não informada |
| `bamboo_crack` | `sfx/stage_01/bamboo_crack.wav` | Bambu / Tec, 0,1–0,8 s | Ausente / não informada / não informada |
| `hat_pulse` | `sfx/stage_01/hat_pulse.wav` | Micro-redemoinho antes do silêncio, 0,3–1 s | Ausente / não informada / não informada |
| `furniture_move` | `sfx/stage_01/furniture_move.wav` | Objetos deslocados, 0,3–1,5 s | Ausente / não informada / não informada |
| `petals` | `sfx/stage_01/petals.wav` | Vento suave / pétalas, 0,5–2 s | Ausente / não informada / não informada |

Produção: música/ambiente em loop sem estalos; efeitos pontuais sem loop. Usar arquivos originais com taxa de amostragem consistente (44,1 ou 48 kHz); efeitos posicionais podem ser mono e músicas estéreo. Ajustar níveis na revisão auditiva com os assets reais, mantendo fala textual e pistas compreensíveis com áudio mudo. A risada pode indicar posição, mas não pode ser a única indicação de um POI.

## Integração e revisão pendente

O menu, livro, mapas e fases já selecionam os IDs corretos pelo `AudioManager`, e confirmações/portas/páginas chamam os SFX correspondentes. Os POIs, a risada posicional, o berimbau da aparição e os epílogos serão encenados nas Tasks 2.7–2.21. Não colocar os sons restantes indiscriminadamente nos mapas antes dessas cenas.

Com os arquivos finais, revisar manualmente: volumes Master/Music/SFX e mudo, loops, transições entre mapas, inteligibilidade sem som, posição da risada, pausa de três segundos do gorro e retorno mais grave, som dos epílogos e retorno ao menu. **A revisão auditiva da mistura e a aprovação gráfica no editor continuam pendentes.** A suíte headless valida o controle, não a qualidade sonora. Detalhes técnicos e testes: [core/audio/README.md](../../core/audio/README.md).
