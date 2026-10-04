import 'dart:ui' show Color;

/// Tema do tabuleiro da loja: as cores da grade neon e da moldura. Só muda a
/// aparência, como os visuais das peças.
class BoardTheme {
  const BoardTheme({
    required this.id,
    required this.price,
    required this.gridA,
    required this.gridB,
    required this.frame,
  });

  final String id;

  /// Custo em moedas. Zero = o tema inicial.
  final int price;

  /// As duas cores que a grade neon alterna (o brilho "respira" entre elas).
  final Color gridA;
  final Color gridB;

  /// Moldura e destaque do mini-tabuleiro jogável no Super Jogo da Velha.
  final Color frame;
}

const String defaultBoardThemeId = 'neonGrid';

/// Catálogo na ordem da loja (do mais barato ao mais caro). Preços abaixo dos
/// visuais de peça: o tema é o segundo desejo, não o primeiro.
const List<BoardTheme> boardThemeCatalog = <BoardTheme>[
  BoardTheme(
    id: defaultBoardThemeId,
    price: 0,
    gridA: Color(0xFF6BE0FF),
    gridB: Color(0xFFFF6BD9),
    frame: Color(0xFF18FFFF),
  ),
  BoardTheme(
    id: 'sunset',
    price: 200,
    gridA: Color(0xFFFF9A3C),
    gridB: Color(0xFFFF4F8B),
    frame: Color(0xFFFFB938),
  ),
  BoardTheme(
    id: 'ocean',
    price: 300,
    gridA: Color(0xFF3EC8FF),
    gridB: Color(0xFF3EF0C4),
    frame: Color(0xFF3EC8FF),
  ),
  BoardTheme(
    id: 'emerald',
    price: 400,
    gridA: Color(0xFF5BE38A),
    gridB: Color(0xFFC8F25B),
    frame: Color(0xFF5BE38A),
  ),
  BoardTheme(
    id: 'royal',
    price: 600,
    gridA: Color(0xFFFFD21A),
    gridB: Color(0xFFB36BFF),
    frame: Color(0xFFFFD21A),
  ),
];

BoardTheme boardThemeById(String id) => boardThemeCatalog.firstWhere(
      (BoardTheme t) => t.id == id,
      orElse: () => boardThemeCatalog.first,
    );
