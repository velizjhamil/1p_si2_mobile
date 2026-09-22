import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../branches/data/sucursales_service.dart';
import '../../data/asistente_ia_service.dart';
import '../../data/models/ia_chat_message.dart';
import '../widgets/ia_product_carousel.dart';
import '../widgets/rich_markdown_text.dart';
import '../widgets/typing_indicator.dart';

/// Full conversational AI assistant screen with Unified System Prompt,
/// mandatory Gender Pre-Filtering, and Real-Time Branch Stock Grounding.
class AsistenteIAScreen extends StatefulWidget {
  const AsistenteIAScreen({super.key, this.promptInicial});

  /// Optional initial prompt to immediately send upon screen opening.
  final String? promptInicial;

  @override
  State<AsistenteIAScreen> createState() => _AsistenteIAScreenState();
}

class _AsistenteIAScreenState extends State<AsistenteIAScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<IAChatMessage> _messages = [];
  bool _isLoading = false;
  String? _lastUserQuery;

  // Contexto de cliente y sucursal para grounding
  String _generoSeleccionado = 'Hombre';
  String? _nombreUsuario;
  int? _idSucursalSeleccionada;
  String? _nombreSucursalSeleccionada;
  List<Sucursal> _sucursales = [];

  List<String> get _sugerenciasActuales {
    final suc = _nombreSucursalSeleccionada ?? 'mi sucursal';
    if (_generoSeleccionado == 'Hombre') {
      return [
        '¿Qué camisas y poleras para hombre tienen disponibles?',
        'Muéstrame pantalones y bermudas en stock',
        '¿Tienen trajes o sacos elegantes para hombre?',
        'Consultar disponibilidad y stock en $suc',
        '¿Cómo funciona el probador virtual?',
      ];
    } else {
      return [
        '¿Qué vestidos elegantes tienen para una fiesta?',
        'Muéstrame blusas de moda en talla M',
        '¿Qué faldas y pantalones para mujer tienen disponibles?',
        'Consultar disponibilidad y stock en $suc',
        '¿Cómo funciona el probador virtual?',
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarPerfilYSucursales();
    if (widget.promptInicial != null && widget.promptInicial!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _enviar(widget.promptInicial!);
      });
    }
  }

  Future<void> _cargarPerfilYSucursales() async {
    try {
      // 1. Cargar nombre de usuario desde la sesión persistida
      final session = await SecureStorageService.getUserSession();
      if (session != null && session['nombre'] != null) {
        _nombreUsuario = session['nombre'].toString();
      }

      // 2. Cargar género preferido
      final generoGuardado = await SecureStorageService.getGenero();
      _generoSeleccionado = generoGuardado;

      // 3. Cargar sucursal preferida
      final sucursalIdGuardada = await SecureStorageService.getSucursalPreferidaId();
      final sucursalNombreGuardada = await SecureStorageService.getSucursalPreferidaNombre();

      // 4. Cargar sucursales en tiempo real desde la API
      final resSucursales = await SucursalesService.listar();
      if (resSucursales['success'] == true && resSucursales['sucursales'] is List<Sucursal>) {
        _sucursales = resSucursales['sucursales'] as List<Sucursal>;
      }

      if (_sucursales.isNotEmpty) {
        if (sucursalIdGuardada != null &&
            _sucursales.any((s) => s.codigoSucursal == sucursalIdGuardada)) {
          _idSucursalSeleccionada = sucursalIdGuardada;
          _nombreSucursalSeleccionada = sucursalNombreGuardada ??
              _sucursales.firstWhere((s) => s.codigoSucursal == sucursalIdGuardada).nombre;
        } else {
          _idSucursalSeleccionada = _sucursales.first.codigoSucursal;
          _nombreSucursalSeleccionada = _sucursales.first.nombre;
        }
      }
    } catch (_) {
      // Fallback silencioso con defaults
    } finally {
      if (mounted) setState(() {});
    }
  }

  void _cambiarGenero(String nuevoGenero) {
    if (_generoSeleccionado == nuevoGenero) return;
    setState(() {
      _generoSeleccionado = nuevoGenero;
    });
    SecureStorageService.saveGenero(nuevoGenero);
  }

  void _mostrarSelectorSucursal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.storefront_rounded, color: Color(0xFF3B82F6)),
                      SizedBox(width: 8),
                      Text(
                        'Selecciona tu sucursal de preferencia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _sucursales.length,
                    itemBuilder: (context, index) {
                      final suc = _sucursales[index];
                      final isSelected = suc.codigoSucursal == _idSucursalSeleccionada;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFE2E8F0),
                          child: Icon(
                            Icons.location_on,
                            size: 18,
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                        ),
                        title: Text(
                          suc.nombre,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${suc.ciudad.nombre} • ${suc.direccion ?? ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                            : null,
                        onTap: () {
                          setState(() {
                            _idSucursalSeleccionada = suc.codigoSucursal;
                            _nombreSucursalSeleccionada = suc.nombre;
                          });
                          SecureStorageService.saveSucursalPreferida(
                            id: suc.codigoSucursal,
                            nombre: suc.nombre,
                          );
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar(String texto) async {
    final clean = texto.trim();
    if (clean.isEmpty || _isLoading) return;

    _textController.clear();
    _lastUserQuery = clean;

    setState(() {
      _messages.add(IAChatMessage.user(clean));
      _isLoading = true;
    });

    _scrollToBottom();

    final result = await AsistenteIAService.enviarMensaje(
      mensaje: clean,
      historial: _messages,
      idSucursal: _idSucursalSeleccionada,
      nombreSucursal: _nombreSucursalSeleccionada,
      generoUsuario: _generoSeleccionado,
      nombreUsuario: _nombreUsuario,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _messages.add(
          IAChatMessage.assistant(
            contenido: result.respuesta,
            productosRecomendados: result.productosRecomendados,
            productosDetalle: result.productosDetalle,
            sugerencias: result.sugerencias,
          ),
        );
      } else {
        _messages.add(
          IAChatMessage.assistant(
            contenido: result.mensajeError ??
                'No pude obtener una respuesta en este momento. Por favor, reintenta.',
            isError: true,
          ),
        );
      }
    });

    _scrollToBottom();
  }

  void _reintentarUltimo() {
    if (_lastUserQuery != null && _lastUserQuery!.isNotEmpty) {
      _enviar(_lastUserQuery!);
    }
  }

  void _limpiarConversacion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar conversación'),
        content: const Text(
          '¿Deseas reiniciar la conversación con el asistente? Se borrarán los mensajes actuales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _messages.clear();
                _lastUserQuery = null;
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Attention AI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Asistente de moda en línea',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Limpiar chat',
              onPressed: _limpiarConversacion,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Context Bar: Filtro de Género y Sucursal Activa
            _buildContextBar(isDark),

            // Messages List / Initial Greeting
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isLoading) {
                          return const TypingIndicator();
                        }

                        final message = _messages[index];
                        return _buildMessageRow(message, isDark);
                      },
                    ),
            ),

            // Bottom Message Input Bar
            _buildInputBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildContextBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Selector de Género Obligatorio
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGenderPill(
                  label: 'Hombre',
                  icon: Icons.man_rounded,
                  isSelected: _generoSeleccionado == 'Hombre',
                  onTap: () => _cambiarGenero('Hombre'),
                  isDark: isDark,
                ),
                _buildGenderPill(
                  label: 'Mujer',
                  icon: Icons.woman_rounded,
                  isSelected: _generoSeleccionado == 'Mujer',
                  onTap: () => _cambiarGenero('Mujer'),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Selector de Sucursal Activa para Stock en Tiempo Real
          Expanded(
            child: InkWell(
              onTap: _sucursales.isEmpty ? null : _mostrarSelectorSucursal,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      size: 16,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _nombreSucursalSeleccionada ?? 'Sucursal Central',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final saludo = _nombreUsuario != null && _nombreUsuario!.isNotEmpty
        ? '¡Hola $_nombreUsuario! Soy tu asistente'
        : '¡Hola! Soy tu asistente de moda';

    final suc = _nombreSucursalSeleccionada ?? 'Sucursal Central';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            saludo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Asesoría personalizada en moda para $_generoSeleccionado con stock verificado en tiempo real en $suc.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Suggestion pills title
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  size: 16,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(width: 6),
                Text(
                  'Preguntas sugeridas para ti ($_generoSeleccionado):',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Initial suggestion chips list
          Column(
            children: _sugerenciasActuales.map((sug) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _enviar(sug),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sug,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(IAChatMessage message, bool isDark) {
    if (message.isUser) {
      return _buildUserBubble(message, isDark);
    } else {
      return _buildAssistantBubble(message, isDark);
    }
  }

  Widget _buildUserBubble(IAChatMessage message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 48),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F2937), Color(0xFF111827)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.contenido,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(IAChatMessage message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: message.isError
                      ? const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  message.isError ? Icons.error_outline : Icons.auto_awesome,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),

              // Bubble Content
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: message.isError
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichMarkdownText(
                        text: message.contenido,
                        isUser: false,
                      ),
                      if (message.isError) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _reintentarUltimo,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 14,
                                  color: Color(0xFFEF4444),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Reintentar consulta',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Horizontal Product Recommendation Carousel
          if (message.productosDetalle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Prendas recomendadas:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                  IAProductCarousel(productos: message.productosDetalle),
                ],
              ),
            ),

          // Follow-up Suggestion Chips
          if (message.sugerencias.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: message.sugerencias.map((sug) {
                  return ActionChip(
                    avatar: const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: Color(0xFF7C3AED),
                    ),
                    label: Text(
                      sug,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      ),
                    ),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    side: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onPressed: () => _enviar(sug),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                maxLines: 4,
                minLines: 1,
                onSubmitted: (_) => _enviar(_textController.text),
                decoration: InputDecoration(
                  hintText: 'Pregunta sobre prendas, tallas, precios...',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
              onPressed: _isLoading ? null : () => _enviar(_textController.text),
              tooltip: 'Enviar mensaje',
            ),
          ),
        ],
      ),
    );
  }
}
