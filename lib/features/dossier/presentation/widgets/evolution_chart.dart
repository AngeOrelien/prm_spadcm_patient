import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Petit graphique d'évolution d'une constante (ex: pouls) dans le temps.
/// Volontairement simple (`CustomPainter`, aucune dépendance externe) —
/// suffisant pour visualiser une tendance ; le vrai graphe alimenté par le
/// service IA (`/ai/health-evolution`) remplacera ceci en Phase 5.
class EvolutionSparkline extends StatelessWidget {
  final List<double> valeurs;
  final Color couleur;
  final double hauteur;

  const EvolutionSparkline({
    super.key,
    required this.valeurs,
    this.couleur = AppColors.primary,
    this.hauteur = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (valeurs.length < 2) {
      return SizedBox(
        height: hauteur,
        child: Center(
          child: Text('Pas assez de données pour un graphe.', style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }
    return SizedBox(
      height: hauteur,
      width: double.infinity,
      child: CustomPaint(painter: _SparklinePainter(valeurs, couleur)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> valeurs;
  final Color couleur;

  _SparklinePainter(this.valeurs, this.couleur);

  @override
  void paint(Canvas canvas, Size size) {
    final minV = valeurs.reduce((a, b) => a < b ? a : b);
    final maxV = valeurs.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1 : (maxV - minV);

    final dx = size.width / (valeurs.length - 1);
    final points = <Offset>[
      for (var i = 0; i < valeurs.length; i++)
        Offset(dx * i, size.height - ((valeurs[i] - minV) / range) * size.height * 0.85 - size.height * 0.075),
    ];

    final linePaint = Paint()
      ..color = couleur
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, linePaint);

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = couleur.withOpacity(0.08));

    final dotPaint = Paint()..color = couleur;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.valeurs != valeurs || oldDelegate.couleur != couleur;
}
