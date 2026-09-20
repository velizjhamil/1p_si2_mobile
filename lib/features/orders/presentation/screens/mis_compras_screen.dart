import 'package:flutter/material.dart';

import 'historial_compras_screen.dart';

/// Pantalla que lista el historial de compras del cliente (CU11 / CU13 / CU21).
///
/// Redirige a [HistorialComprasScreen] para unificar la experiencia del cliente
/// manteniendo compatibilidad hacia atrás con rutas y botones existentes.
class MisComprasScreen extends StatelessWidget {
  const MisComprasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HistorialComprasScreen();
  }
}
