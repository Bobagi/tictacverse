import 'dart:ui' show Color;

/// Como a peça é desenhada.
enum PieceSkinStyle {
  /// As artes PNG originais do app.
  artwork,

  /// Traço neon fino com brilho.
  neon,

  /// Traço grosso com degradê.
  gradient,

  /// Traço bem grosso e arredondado, com reflexo, estilo bala.
  candy,

  /// Degradê com anel interno no O e brilhos em volta.
  galaxy,
}

/// Um visual de peças da loja. Só muda a aparência: nenhuma skin dá vantagem.
class PieceSkin {
  const PieceSkin({
    required this.id,
    required this.price,
    required this.style,
    required this.crossColors,
    required this.noughtColors,
  });

  final String id;

  /// Custo em moedas. Zero = o visual inicial, que todo jogador já tem.
  final int price;
  final PieceSkinStyle style;

  /// Duas cores por peça: início e fim do degradê (iguais = cor chapada).
  final List<Color> crossColors;
  final List<Color> noughtColors;

  /// Cor do brilho em volta da peça. As artes PNG têm brilho próprio e o
  /// tabuleiro sorteia azul/rosa para elas; os demais brilham na própria cor.
  Color? get crossGlow =>
      style == PieceSkinStyle.artwork ? null : crossColors.first;
  Color? get noughtGlow =>
      style == PieceSkinStyle.artwork ? null : noughtColors.first;
}

/// Catálogo da loja, na ordem de exibição (mais barato primeiro).
///
/// Preços pensados contra o ganho real: uma vitória rende ~12 moedas e o
/// bônus diário 20 a 100, então o primeiro visual sai na primeira ou segunda
/// sessão e o mais caro vira meta de algumas semanas.
const List<PieceSkin> pieceSkinCatalog = <PieceSkin>[
  PieceSkin(
    id: 'aurora',
    price: 0,
    style: PieceSkinStyle.artwork,
    crossColors: <Color>[Color(0xFFFF6BD9), Color(0xFF6B8BFF)],
    noughtColors: <Color>[Color(0xFF6BE0FF), Color(0xFFB36BFF)],
  ),
  PieceSkin(
    id: 'neon',
    price: 120,
    style: PieceSkinStyle.neon,
    crossColors: <Color>[Color(0xFF6BE0FF), Color(0xFF6BE0FF)],
    noughtColors: <Color>[Color(0xFFFF6BD9), Color(0xFFFF6BD9)],
  ),
  PieceSkin(
    id: 'fireIce',
    price: 250,
    style: PieceSkinStyle.gradient,
    crossColors: <Color>[Color(0xFFFF7A2F), Color(0xFFFFD21A)],
    noughtColors: <Color>[Color(0xFF3EC8FF), Color(0xFFE0FAFF)],
  ),
  PieceSkin(
    id: 'candy',
    price: 350,
    style: PieceSkinStyle.candy,
    crossColors: <Color>[Color(0xFF3EF0C4), Color(0xFF1FB896)],
    noughtColors: <Color>[Color(0xFFFF6B8B), Color(0xFFE0436A)],
  ),
  PieceSkin(
    id: 'gold',
    price: 500,
    style: PieceSkinStyle.gradient,
    crossColors: <Color>[Color(0xFFFFE27A), Color(0xFFE0A21A)],
    noughtColors: <Color>[Color(0xFFF2F4FF), Color(0xFF9AA3C7)],
  ),
  PieceSkin(
    id: 'galaxy',
    price: 800,
    style: PieceSkinStyle.galaxy,
    crossColors: <Color>[Color(0xFFB36BFF), Color(0xFFFF6BD9)],
    noughtColors: <Color>[Color(0xFF3EF0C4), Color(0xFF6BE0FF)],
  ),
];

PieceSkin pieceSkinById(String id) => pieceSkinCatalog.firstWhere(
      (PieceSkin skin) => skin.id == id,
      orElse: () => pieceSkinCatalog.first,
    );
