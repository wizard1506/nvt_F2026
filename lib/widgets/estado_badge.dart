import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EstadoBadge extends StatelessWidget {
  const EstadoBadge({super.key, required this.estado, this.onTap});

  final String estado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final texto = estado.trim();
    if (texto.isEmpty) return const SizedBox.shrink();
    final Color color;
    switch (texto.toUpperCase()) {
      case 'PENDIENTE':
        color = Colors.orange;
        break;
      case 'ATENDIDA':
        color = AppColors.mediumGreen;
        break;
      case 'CANCELADO':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (onTap == null) return badge;
    return Tooltip(
      message: 'Cambiar estado',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: badge,
      ),
    );
  }
}
