import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../ai_assistant/presentation/screens/asistente_ia_screen.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../notifications/data/notificaciones_service.dart';
import '../../../notifications/presentation/screens/notificaciones_screen.dart';
import '../../../orders/presentation/screens/historial_compras_screen.dart';
import '../../../reservations/presentation/screens/reservas_screen.dart';
import '../../../shipping/presentation/screens/seguimiento_envio_screen.dart';
import '../../../tallas/presentation/screens/tallas_screen.dart';

/// Pantalla de Perfil de Usuario y Ajustes Personales de la Tienda Attention.
///
/// Diseñada con estética de comercio electrónico de moda premium:
/// - Cabecera visual del cliente con avatar e indicador de membresía.
/// - Preferencias de visualización (Modo Claro / Modo Oscuro).
/// - Gestión de compras, pedidos, reservas y envíos en curso.
/// - Guía de tallas y asistencia de moda inteligente con Attention AI.
/// - Cierre de sesión seguro con diálogo de confirmación.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({
    super.key,
    this.onNavigateToCatalog,
  });

  final VoidCallback? onNavigateToCatalog;

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _session;
  int _notificacionesNoLeidas = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final session = await SecureStorageService.getUserSession();
    final count = await NotificacionesService.obtenerContadorNoLeidas();

    if (mounted) {
      setState(() {
        _session = session;
        _notificacionesNoLeidas = count;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text('Cerrar sesión', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas salir de tu cuenta en este dispositivo?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _navigateToCompras() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HistorialComprasScreen()),
    );
  }

  void _navigateToReservas() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReservasScreen()),
    );
  }

  void _navigateToNotificaciones() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
    );
    _loadProfileData();
  }

  void _navigateToEnvios() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SeguimientoEnvioScreen()),
    );
  }

  void _navigateToTallas() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TallasScreen()),
    );
  }

  void _navigateToAsistenteIA() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AsistenteIAScreen()),
    );
  }

  void _mostrarAyudaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.support_agent_rounded, color: Color(0xFF7C3AED), size: 24),
            SizedBox(width: 10),
            Text('Atención y Soporte', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estamos disponibles para ayudarte con tus pedidos, reservas y consultas de moda.',
              style: TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildContactRow(Icons.schedule_rounded, 'Horario de Atención:', 'Lunes a Sábado: 09:00 - 20:00'),
            const SizedBox(height: 10),
            _buildContactRow(Icons.chat_bubble_outline_rounded, 'Atención WhatsApp:', '+591 700-12345'),
            const SizedBox(height: 10),
            _buildContactRow(Icons.email_outlined, 'Correo de Contacto:', 'soporte@attention.com'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1F2937),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final nombre = (_session?['nombre'] as String?) ?? 'Cliente';
    final correo = (_session?['correo'] as String?) ?? 'cliente@attention.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil y Ajustes',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar perfil',
            onPressed: _loadProfileData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Cabecera Elegante del Cliente (Fashion Card)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFF1F2937), const Color(0xFF111827)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar circular con inicial estilizada
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Identidad del usuario
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          correo,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Badge de Cliente Attention
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 13,
                                color: Color(0xFFA5B4FC),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Cliente de la Tienda',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 2. Sección: Preferencias y Apariencia
            _buildSectionHeader('PREFERENCIAS Y APARIENCIA'),
            Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListenableBuilder(
                  listenable: ThemeController.instance,
                  builder: (context, _) {
                    final darkActive = ThemeController.instance.isDarkMode;
                    return SwitchListTile.adaptive(
                      value: darkActive,
                      onChanged: (val) => ThemeController.instance.toggleDarkMode(val),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: darkActive
                              ? const Color(0xFF312E81)
                              : const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          darkActive ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: darkActive
                              ? const Color(0xFFA5B4FC)
                              : const Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Modo Oscuro',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                      ),
                      subtitle: Text(
                        darkActive
                            ? 'Tema visual oscuro para confort nocturno'
                            : 'Tema visual claro para alta luminosidad',
                        style: textTheme.bodySmall?.copyWith(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Sección: Mis Pedidos y Gestión
            _buildSectionHeader('MIS PEDIDOS Y GESTIÓN'),
            Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: _buildIconContainer(
                      Icons.receipt_long_rounded,
                      const Color(0xFF2563EB),
                    ),
                    title: const Text(
                      'Mis Compras y Pedidos',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Historial de compras y comprobantes emitidos',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: _navigateToCompras,
                  ),
                  const Divider(height: 1, indent: 60),
                  ListTile(
                    leading: _buildIconContainer(
                      Icons.bookmark_border_rounded,
                      const Color(0xFF059669),
                    ),
                    title: const Text(
                      'Mis Reservas de Prendas',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Prendas apartadas para retirar en sucursal física',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: _navigateToReservas,
                  ),
                  const Divider(height: 1, indent: 60),
                  ListTile(
                    leading: _buildIconContainer(
                      Icons.local_shipping_outlined,
                      const Color(0xFFD97706),
                    ),
                    title: const Text(
                      'Seguimiento de Envíos',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Rastreo y etapas de entrega de tus compras',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: _navigateToEnvios,
                  ),
                  const Divider(height: 1, indent: 60),
                  ListTile(
                    leading: _buildIconContainer(
                      Icons.notifications_none_rounded,
                      const Color(0xFF7C3AED),
                    ),
                    title: const Text(
                      'Bandeja de Notificaciones',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      _notificacionesNoLeidas > 0
                          ? '$_notificacionesNoLeidas alerta(s) pendiente(s) de lectura'
                          : 'Avisos de compras, reservas y entregas',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: _notificacionesNoLeidas > 0
                        ? Badge(
                            label: Text('$_notificacionesNoLeidas'),
                            child: const Icon(Icons.chevron_right_rounded, size: 20),
                          )
                        : const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: _navigateToNotificaciones,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Sección: Servicios y Soporte de Moda
            _buildSectionHeader('SERVICIOS Y SOPORTE'),
            Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: _buildIconContainer(
                      Icons.auto_awesome_rounded,
                      const Color(0xFF8B5CF6),
                    ),
                    title: const Text(
                      'Asistente de Moda Attention AI',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Recomendaciones de outfits, prendas y combinaciones',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: _navigateToAsistenteIA,
                  ),
                  const Divider(height: 1, indent: 60),
                  ListTile(
                    leading: _buildIconContainer(
                      Icons.straighten_rounded,
                      const Color(0xFF0284C7),
                    ),
                    title: const Text(
                      'Guía de Tallas y Medidas',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Tabla de equivalencias corporales por categoría',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: _navigateToTallas,
                  ),
                  const Divider(height: 1, indent: 60),
                  ListTile(
                    leading: _buildIconContainer(
                      Icons.support_agent_rounded,
                      const Color(0xFF10B981),
                    ),
                    title: const Text(
                      'Atención al Cliente y Ayuda',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Canales de soporte, horarios y preguntas frecuentes',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: _mostrarAyudaDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 5. Botón Elegante de Cerrar Sesión
            OutlinedButton.icon(
              onPressed: _handleLogout,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: const Color(0xFFEF4444),
                side: BorderSide(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.1,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.9,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}
