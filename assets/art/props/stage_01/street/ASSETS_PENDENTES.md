# Diferenças entre os assets e o concept_street

A cena ativa está descrita em [SANTA_TERESA.md](../../../../../stages/stage_01_saci/SANTA_TERESA.md). Banco, bonde, bambus, muro de reboco, caixas de frutas, balcão e quitandeira já foram usados. Não é necessário recriar esses assets para testar o mapa e a conversa por E.

Para uma reprodução visual idêntica a `concept_street.jpg`, estes arquivos não foram encontrados entre os assets de produção:

| Arte | Encaixe atual / diferença |
| --- | --- |
| Seis grafites do mural | `MuralWall/Panel01` a `Panel06`, centros de (644, 130) a (924, 130), com passos de 56 px. Reserva de 40 × 48 por quadro. Os marcadores estão vazios; não foram usados ícones do inventário como substitutos. |
| Muro de tijolo aparente com capeamento | O asset enviado é um muro de reboco envelhecido. A composição usa esse PNG sem modificar seus pixels. |
| Telhas curvas de terracota | Os atlas existentes são verdes ou marrons. A cena aplica modulação quente ao marrom, preservando os detalhes originais; o desenho das telhas não é o mesmo do concept. |
| Árvores com copa arredondada | As árvores fornecidas têm copa irregular. Foram usadas na posição e escala aproximadas da praça de referência. |
| Bonde com o perfil e a antena da referência | O PNG amarelo enviado já está sobre os trilhos, mas sua carroceria difere da ilustração. |

Postes, calçada e meio-fio têm peças modulares em SVG na paleta do projeto; o toldo listrado é geometria editável da cena. Não foram extraídos pixels da imagem de inspiração nem gerados PNGs para substituir as artes acima.

A entrega da peneira, as pistas do diário, os estados do mural, a interação do bambu, a subida e o furacão ainda dependem das tasks narrativas. O grande furacão e os símbolos pintáveis do mural precisarão de arte própria quando essas tasks forem implementadas.
