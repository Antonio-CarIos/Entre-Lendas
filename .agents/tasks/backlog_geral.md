# Backlog Geral — Roadmap "Entre Lendas"

## Épico 1: Sistemas Transversais (Core Engine)
- [ ] Sistema de Diálogo Ramificado com suporte a escolhas morais e verificação de itens/pistas.
- [ ] UI de Inventário dividida em abas: "Itens Usáveis", "Artefatos" e "Diário de Investigação".
- [ ] Sistema de Combate por Turnos (Caixa de Batalha + Menu de Ações: Confrontar, Compreender, Item, Aliança).
- [ ] Componente de Mundo Reativo (`NatureStateResponder`) que troca sprites de árvores/rios com base no `WorldState.nature_balance`.

## Épico 2: Fase 1 — O Saci-Pererê
- [ ] Mapa urbano/rural brasileiro (Tileset 32x32 derivado de `_templates/tileset_base/`) e interiores de casas com objetos revirados interagíveis.
- [ ] Customização do sprite do Saci (`32x64`) no PixelLab a partir de `_templates/character_base/`.
- [ ] Mecânica de Redemoinho e captura com a Peneira + desafio de obstáculos top-down pelo Gorro.
- [ ] Minigame de Jogo da Memória cultural do Saci + puzzles cooperativos.

## Épico 3: Fase 2 — A Mula sem Cabeça
- [ ] Vilarejo com sistema de ciclo/transição Dia -> Noite (`CanvasModulate` + `PointLight2D` + crossfade de áudio).
- [ ] Investigação diurna: coleta de pistas para o Diário e dedução da identidade da Mula.
- [ ] Furtividade noturna: IA de patrulha da Mula, pontos de esconderijo, rastros revelados pela `Ferradura da Mula` e áudio posicional (`AudioStreamPlayer2D`) de relinchos.

## Épico 4: Fase 3 — Os Guardiões da Floresta
- [ ] Floresta Amazônica com zonas devastadas e zonas preservadas + Caverna Ancestral do Boitatá.
- [ ] Customização dos sprites de Curupira, Caipora e Caçadores (`32x64`) a partir de `_templates/character_base/`.
- [ ] IA de Caçadores com cone de visão (`RayCast2D`) e reação ao item `Pegada Falsa`.
- [ ] Libertação de animais enjaulados, uso do `Assobio da Caipora` e minigame de plantio de mudas.
- [ ] Sequência de clímax: condução furtiva dos caçadores até a caverna e despertar do Boitatá.

## Épico 5: Fase 4 — A Cuca e Desfechos
- [ ] Floresta com shader/overlay de neblina densa e geometria de teleporte (labirinto de ilusão).
- [ ] Mecânica do `Espelho da Cuca` (revela colisões/sprites ocultos ou desfaz ilusões de fases passadas) e puzzle de poções com `Ervas da Cuca`.
- [ ] Confronto dialógico final com a Cuca avaliando o histórico completo do `WorldState` para múltiplos finais.