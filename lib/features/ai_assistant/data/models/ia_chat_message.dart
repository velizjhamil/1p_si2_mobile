import 'producto_resumen_ia.dart';

enum IAChatRole {
  usuario,
  asistente,
}

/// Represents a message in the AI assistant conversation thread.
class IAChatMessage {
  IAChatMessage({
    required this.rol,
    required this.contenido,
    this.productosRecomendados = const [],
    this.productosDetalle = const [],
    this.sugerencias = const [],
    DateTime? timestamp,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory IAChatMessage.user(String text) {
    return IAChatMessage(
      rol: IAChatRole.usuario,
      contenido: text.trim(),
    );
  }

  factory IAChatMessage.assistant({
    required String contenido,
    List<int> productosRecomendados = const [],
    List<ProductoResumenIA> productosDetalle = const [],
    List<String> sugerencias = const [],
    bool isError = false,
  }) {
    return IAChatMessage(
      rol: IAChatRole.asistente,
      contenido: contenido,
      productosRecomendados: productosRecomendados,
      productosDetalle: productosDetalle,
      sugerencias: sugerencias,
      isError: isError,
    );
  }

  final IAChatRole rol;
  final String contenido;
  final List<int> productosRecomendados;
  final List<ProductoResumenIA> productosDetalle;
  final List<String> sugerencias;
  final DateTime timestamp;
  final bool isError;

  bool get isUser => rol == IAChatRole.usuario;
  bool get isAssistant => rol == IAChatRole.asistente;

  /// Formats the message for the `historial` parameter in `/api/v1/ia/chat`.
  Map<String, String> toHistorialMap() {
    return {
      'rol': isUser ? 'usuario' : 'asistente',
      'contenido': contenido,
    };
  }
}
