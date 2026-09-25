# Créditos de áudio

## Efeitos sonoros (`sfx/`)

Todos os efeitos vêm dos packs **Interface Sounds**, **Digital Audio** e
**Impact Sounds** de Kenney (www.kenney.nl), licença **CC0 1.0** (domínio
público, uso comercial liberado, crédito opcional). Foram convertidos para mono,
normalizados em loudness (-16 LUFS) e renomeados:

| Arquivo | Origem (Kenney) | Uso no jogo |
|---|---|---|
| `move_x.ogg` | Interface Sounds `pluck_001` | jogada do X |
| `move_o.ogg` | Interface Sounds `pluck_002` | jogada do O / máquina |
| `ui_click.ogg` | Interface Sounds `click_001` | toque em botão |
| `capture.ogg` | Interface Sounds `confirmation_002` | mini-tabuleiro conquistado (Ultimate) |
| `win.ogg` | Digital Audio `threeTone2` | vitória |
| `lose.ogg` | Digital Audio `lowDown` | derrota para a máquina |
| `draw.ogg` | Interface Sounds `question_002` | empate |
| `level_up.ogg` | Digital Audio `powerUp5` | subiu de nível |
| `achievement.ogg` | Interface Sounds `confirmation_004` | conquista desbloqueada |
| `xp_tick.ogg` | Interface Sounds `tick_001` | contador de XP subindo |
| `chaos.ogg` | Interface Sounds `scratch_002` | evento do Modo Caos |
| `streak.ogg` | Digital Audio `phaserUp3` | sequência de vitórias |
| `win_line.ogg` | Digital Audio `highUp` | linha vencedora sendo desenhada |

## Música (`music/`)

A playlist embaralha as faixas e toca todas antes de repetir (`music_playlist.dart`).
Todas normalizadas em loudness (-17 LUFS) e encodadas em OGG Vorbis q3 (loop sem
"gap", ao contrário do MP3).

| Arquivo | Origem | Licença |
|---|---|---|
| `background_loop.mp3` | trilha original do projeto (128 kbps; era 320 kbps / 7,9 MB) | própria |
| `junkala_level1.ogg`, `junkala_level2.ogg`, `junkala_level3.ogg` | Juhani Junkala, "5 Chiptunes (Action)" / Retro Game Music Pack (opengameart.org/content/5-chiptunes-action) | CC0 1.0 |
| `kucza_deadly_contracts.ogg`, `kucza_price_of_freedom.ogg`, `kucza_hostile_territory.ogg` | Tomasz Kucza, "Retro Synthwave Loops" (opengameart.org/content/retro-synthwave-loops) | **CC BY 4.0**: crédito obrigatório, exibido na tela de configurações do app |
