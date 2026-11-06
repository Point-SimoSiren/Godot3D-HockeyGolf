# Godot-opiskelu: ensimmäinen 3D-peli

Pelissä on viisi vaaleansinertävää kenttää punaisine reunoineen. Työnnä musta
kiekko neljän ensimmäisen kentän aukkoon. Viidennen kentän kultainen maali
päättää pelin. Ajanotto alkaa heti pelin käynnistyessä, ja paras aika tallentuu.

Pelaajaa liikutetaan W-, A-, S- ja D-näppäimillä tai pitämällä hiiren vasenta
painiketta pohjassa. Hiirellä pelaaja liikkuu osoittimen kohdalle kentällä;
WASD saa etusijan, jos molempia käytetään samaan aikaan. **R** aloittaa pelin
alusta ja nollaa nykyisen ajan.

## Käynnistäminen

1. Avaa Godot 4.6.
2. Valitse **Import** ja avaa tämän kansion `project.godot`.
3. Paina editorin oikeasta yläkulmasta **Run Project** tai näppäintä **F6/F5**.

## Mistä osista peli koostuu?

- `scenes/main.tscn` sisältää pelimaailman nodet: kentän, reunat, kiekon, pelaajan,
  valon ja kameran.
- `scripts/player.gd` lukee WASD-näppäimet ja hiiren sekä liikuttaa pelaajaa.
- `scripts/main.gd` rakentaa kenttien aukot ja maalin sekä hoitaa ajanoton.
- `project.godot` kertoo Godotille aloitusscenen sekä Input Map -näppäimet.

Hyvä ensimmäinen kokeilu on muuttaa `player.gd`-tiedoston `speed`-arvoa tai
pelaajan väriä Godot-editorin Inspectorissa.
