# Game Design Document (GDD) — Entre Lendas

## 1. Visão Geral e Especificações Técnicas
- **Título:** Entre Lendas
- **Gênero:** Aventura 2D Top-Down, Puzzle, RPG Narrativo com Combate por Turnos.
- **Inspirações:** *Undertale*, *EarthBound*, *Mother 3*, *Omori*.
- **Arte e Proporções:** Pixel Art. Grid e tiles de `32x32` px; personagens com proporção `32x64` px.
- **Premissa:** O jogador é inserido em um universo onde as lendas do folclore brasileiro são reais e físicas. Estruturado como uma **antologia em 4 fases**, o objetivo é compreender a essência e o propósito desses seres como guardiões da natureza e encontrar um meio de voltar ao seu próprio mundo.

## 2. Sistema Central: Captura vs. Amizade (Afinidade e Estado do Mundo)
Em cada encontro ou conflito, o jogador decide entre **Capturar** a entidade ou **Fazer Amizade (Aliança)**.
- **Caminho da Captura:**
  - *Efeito Imediato:* Concede itens ou recursos rápidos.
  - *Consequências:* Perda de auxílio futuro, bloqueio de rotas alternativas, redução de recompensas a longo prazo, aumento na dificuldade de desafios posteriores e degradação ambiental (árvores secas, poluição, rios sujos, escassez de fauna).
- **Caminho da Amizade:**
  - *Efeito Imediato:* Exige compreensão da história da lenda, resolução de puzzles empáticos ou minigames.
  - *Consequências:* Desbloqueia novas habilidades, informações, rotas secretas, auxílio direto das entidades e restauração ambiental (vegetação exuberante, rios limpos, presença de animais).
- **Impacto Geral:** Um sistema de afinidade registra a trajetória do jogador, alterando visualmente os cenários, o comportamento de NPCs, os diálogos e os finais disponíveis na Fase 4.

## 3. Personagens / Entidades Folclóricas
1. **Saci-Pererê:** Ser de uma perna só, veloz, transforma-se em redemoinho e fica invisível com seu gorro vermelho. Guardião da natureza que usa o caos e travessuras para ensinar ordem. Outorga uma visão multicultural de sua origem.
2. **Mula sem Cabeça:** Mula de pelagem escura com uma tocha/bola de fogo no lugar da cabeça. Representa uma maldição trágica que assombra um vilarejo à noite.
3. **Curupira:** Protetor implacável da floresta, impaciente e agressivo contra caçadores. Cabelos de fogo e pés virados para trás (usados para criar rastros falsos).
4. **Caipora:** Protetora dos animais, cautelosa e focada na restauração da fauna e flora. Monta um porco selvagem e comunica-se por assobios.
5. **Boitatá:** Cobra de fogo gigantesca e ancestral. Abriga-se em uma caverna com pinturas rupestres, alimenta-se da vitalidade da mata e desperta apenas em perigo extremo para erradicar invasores.
6. **Cuca:** Bruxa ancestral com cabeça de jacaré, mestre das ilusões, poções e enigmas psicológicos. Detém a chave para o retorno do jogador ao seu mundo.

## 4. Estrutura de Fases, Cenários e Mecânicas Específicas
*Nota Técnica:* Menções a "parkour" ou "plataforma" do conceito original são traduzidas em **desafios espaciais Top-Down** (esquiva cronometrada, travessia de obstáculos com timing, pontes, vento e puzzles de movimento em grid).

### Fase 1 — O Saci-Pererê
- **Cenário:** Ruazinhas brasileiras (urbanas e rurais) e interior de casas típicas. Detalhes culturais ricos: pichações, artes nos muros, gorro vermelho em varais de quintal e móveis revirados pelas travessuras.
- **Mecânicas:**
  - *Exploração:* Organizar a bagunça nas casas e investigar a origem do Saci.
  - *Rota de Captura:* Usar uma **peneira** para prender os redemoinhos do Saci, seguido de uma sequência de desafio de movimento/obstáculos (*parkour top-down*) para recuperar o gorro escondido.
  - *Rota de Amizade:* Jogo da memória sobre a história, origem e características do Saci, seguido de puzzles de travessia colaborativa usando os poderes do Saci para acessar áreas bloqueadas.

### Fase 2 — A Mula sem Cabeça
- **Cenário:** Pequeno vilarejo interiorano com transição gradual de **Dia para Noite**. De dia, moradores circulam; à noite (quinta-feira), as ruas ficam desertas, escuras e sombrias.
- **Mecânicas:**
  - *Investigação Diurna (Detetive/Diário):* Conversar com moradores, coletar pistas e reconstruir a história para descobrir a identidade da mulher por trás da maldição.
  - *Furtividade Noturna (Fuga da Mula):* Evitar ataques da Mula escondendo-se em pontos do cenário e seguindo seus rastros. O áudio dos **relinchos** funciona como radar de proximidade e tensão.
  - *Desfecho:* Compreender a situação da mulher/Mula permite que ela ajude o jogador a viajar para a próxima fase.

### Fase 3 — Os Guardiões da Floresta (Curupira, Caipora e Boitatá)
- **Cenário:** Floresta Amazônica. Contraste severo entre mata viva/preservada e áreas devastadas (clareiras queimadas, poços de fumaça, troncos cortados e acampamentos de caçadores), além da caverna ancestral com pinturas rupestres do Boitatá.
- **Mecânicas:**
  - *Missões dos Guardiões:* Furtividade para libertar animais de gaiolas, minigame de plantio e cuidado de mudas (altera o cenário), combate/confronto contra caçadores e uso de armadilhas.
  - *Rastros Falsos:* Uso de pegadas invertidas do Curupira para enganar a IA dos caçadores.
  - *Clímax (Despertar do Boitatá):* Após restaurar áreas da mata, o jogador deve atrair e conduzir os invasores (usando fuga e rastros falsos) até a caverna ancestral, despertando o Boitatá para expulsá-los.

### Fase 4 — A Cuca
- **Cenário:** Floresta densa e isolada que transiciona do dia para uma noite escura com **neblina densa**, objetos abandonados e marcas nas árvores.
- **Mecânicas:**
  - *Desafios da Cuca:* Enigmas, exploração e testes morais baseados nas decisões das Fases 1 a 3. Geometria mutável (caminhos que mudam de lugar).
  - *Confronto com Ilusões:* A Cuca projeta versões distorcidas de eventos passados. O jogador usa pistas do seu diário e itens para discernir o real do ilusório.
  - *Conversa Final:* Diálogo ramificado com a Cuca. O histórico de Captura vs. Amizade determina o desfecho, a revelação de como o jogador chegou àquele mundo e se/como ele retorna para casa.

## 5. Inventário e Itens Especiais
O inventário divide-se em **Itens Usáveis/Equipáveis** e **Itens de Consulta** (Diários, anotações de lore, pistas de investigação).

| Item | Fase / Origem | Função Mecânica |
| :--- | :--- | :--- |
| **Gorro do Saci** | Fase 1 | Acessa áreas especiais e ativa mecanismos ligados aos poderes de vento/invisibilidade do Saci. |
| **Ferradura da Mula** | Fase 2 | Identifica rastros invisíveis da Mula e revela pistas escondidas no vilarejo. |
| **Assobio da Caipora** | Fase 3 | Chama a Caipora para auxílio ou revela a localização de animais enjaulados e segredos na mata. |
| **Pegada Falsa** | Fase 3 | Cria rastros falsos no mapa para atrair ou despistar caçadores e criaturas. |
| **Brasa do Boitatá** | Fase 3 | Ilumina áreas escuras, afasta inimigos específicos e abre passagem em áreas protegidas pelo fogo ancestral. |
| **Espelho da Cuca** | Fase 4 | Revela a verdade através das ilusões da Cuca, diferenciando objetos/caminhos reais de falsos. |
| **Ervas da Cuca** | Fase 4 | Coletáveis de exploração usados em puzzles de poções e enigmas mágicos. |
| **Amuleto de Proteção** | Global | Reduz dano/efeitos de ataques de entidades em combates por turno e protege em desafios. |

## 6. Direção de Áudio e Sonoplastia Dinâmica
- **Fase 1 (Saci):** Ritmos vibrantes de capoeira (berimbau e percussão). SFX posicional da risada do Saci indicando travessuras.
- **Fase 2 (Mula):** Transição evolutiva — música calma de vilarejo durante o dia que se transforma em um coral sombrio de procissão de almas à noite. SFX de relinchos com atenuação por distância (mecânica de alerta).
- **Fase 3 (Guardiões):** Trilha urgente e tensa. SFX de assobios da Caipora e gritos do Curupira pontuando ações.
- **Fase 4 (Cuca):** Atmosfera sombria com sussurros, risadas distantes e graves pesados. Intensifica-se nos puzzles de ilusão e silencia/suaviza na conversa final.