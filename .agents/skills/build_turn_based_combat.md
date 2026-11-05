# Skill: Combate por Turnos com Resolução Moral (Undertale / Omori Style)

No jogo **Entre Lendas**, o combate não serve apenas para zerar o HP do inimigo. Ele integra o dilema central entre **Capturar/Subjugar** e **Compreender/Fazer Amizade**.

## 1. Fluxo da Máquina de Estados de Batalha (`CombatStateMachine`)
1. **`BattleStart`:** Carrega o `EncounterData` (Resource da Entidade ou Caçador) e exibe texto de abertura.
2. **`PlayerTurn`:** O jogador escolhe entre 4 ações principais:
   - **AGIR / CONFRONTAR:** Ataque físico ou tentativa de subjugação com armadilha/peneira (aumenta progresso de **Captura**).
   - **COMPREENDER (Empatia):** Ações contextuais baseadas nas pistas do Diário (ex: responder sobre a origem do Saci, acalmar a Mula, mostrar respeito ao Curupira). Aumenta o medidor de **Amizade/Afinidade**.
   - **ITEM:** Usa itens do inventário (ex: *Amuleto de Proteção*, *Ervas da Cuca*, *Pegada Falsa*).
   - **POUPAR / ALIANÇA:** Disponível quando o medidor de Amizade atinge 100%, encerrando o conflito pacificamente.
3. **`EnemyTurn`:** Executa o ataque da entidade ou um minigame de esquiva espacial top-down dentro da caixa de batalha (Layer 6: `Combat_Box`).
4. **`BattleResolution`:** Atualiza o `WorldState` com o desfecho (`CAPTURED` ou `ALLIED`), altera o `nature_balance` e retorna ao mapa de exploração.