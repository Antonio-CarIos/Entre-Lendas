# Entidade Saci

`saci.tscn` é um ator isolado, inicialmente oculto e sem colisão. O Resource `saci_visuals.tres` tem somente a forma **whirlwind**: quatro poses idle e cinco frames walk por direção, a 8 FPS, sem mudar os PNGs recebidos. A forma **one_leg** ainda não possui arte e não é substituída pelo vento.

```gdscript
var saci: SaciActor = preload("res://entities/folklore/saci/saci.tscn").instantiate() as SaciActor
add_child(saci)
if saci.show_form(&"whirlwind", Vector2.DOWN):
	saci.play_action(&"walk")
saci.set_body_solid(false) # Coreografia livre dos móveis.
```

`play_action()` mantém a direção atual se não receber outra. As quatro direções usam arquivos reais, com `flip_h = false`. `hide_actor()` para a animação/velocidade e remove a presença física. `set_body_solid(true)` só habilita a base quando uma forma válida estiver visível. `action_finished(action)` repassa término de clipes sem loop; não avança a história. Ações sem frames retornam false, ocultam o ator e emitem `visual_unavailable(form, action, direction)`; o controlador deve validar os Resources antes de iniciar a cutscene.

O redemoinho legado usa canvas lógico 64×80/offset y=-40 para preservar todo o desenho nativo; `one_leg_canvas` é 32×64/offset y=-32. AtlasTexture normaliza transparência e âncora por clipe, sem redimensionar nem recentralizar cada frame da caminhada. Recortes e fontes estão em `assets/art/characters/folklore/saci/ART_AUDIT.json`.

Prévia editável por F6: `stages/stage_01_saci/saci_visual_preview.tscn`. Catálogo de faltas, briefings, requisitos por Task e critérios para concluir 2.9: [ART_REQUIREMENTS.md](../../../stages/stage_01_saci/ART_REQUIREMENTS.md).
