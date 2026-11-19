# Interface do inventário

- `ui_inventory_background.png` é o fundo original. `ui/inventory_panel.tscn` usa a região `(32, 18, 280, 154)` para levar a moldura até as bordas da tela, sem alterar o PNG.
- `ui_scrollbar.png` é a arte original da barra. O puxador usa a região `(117, 116, 22, 32)` diretamente no tema `ui/themes/gameplay_theme.tres`.
- `ui_scrollbar_track.png` é o trilho separado dessa mesma arte: recorte `(119, 68, 18, 132)`, com o puxador fixo removido pela repetição da linha original `(119, 100, 18, 1)` entre as linhas locais 47 e 80. Assim o puxador móvel não fica duplicado no fundo. As cores e as extremidades do trilho vêm do original.

As barras da lista de slots e dos textos compartilham esse tema. A rolagem segue as setas do teclado; os slots não têm um painel externo. A descrição aparece após confirmar **Examinar**; **Ler** abre o texto de leitura. A confirmação e o resultado da combinação usam um painel central independente.
