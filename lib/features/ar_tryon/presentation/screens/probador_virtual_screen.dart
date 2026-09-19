import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../cart/logic/cart_service.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../catalog/data/productos_service.dart';
import '../../../reservations/presentation/widgets/crear_reserva_dialog.dart';
import '../../data/probador_virtual_service.dart';

/// Screen for the Virtual Fitting Room with AI Fashion Assistant (CU25 / CU8).
///
/// Exclusive to Client role ('C'). Allows clients to:
/// 1. Capture or upload their photo using device camera or gallery.
/// 2. Pick any garment from the Attention catalog (with size & color).
/// 3. Run AI virtual try-on simulation with body complexion & fit estimation.
/// 4. Directly Add to Cart (CU15) or Reserve in Store (CU14).
class ProbadorVirtualScreen extends StatefulWidget {
  const ProbadorVirtualScreen({
    super.key,
    this.prendaInicial,
    this.tallaInicial,
    this.colorInicial,
  });

  final Producto? prendaInicial;
  final String? tallaInicial;
  final String? colorInicial;

  @override
  State<ProbadorVirtualScreen> createState() => _ProbadorVirtualScreenState();
}

enum _PasoProbador { foto, prenda, simulando, resultado }

class _ProbadorVirtualScreenState extends State<ProbadorVirtualScreen> {
  final ImagePicker _picker = ImagePicker();

  _PasoProbador _pasoActual = _PasoProbador.foto;

  // Step 1: Photo & Morfometry state
  Uint8List? _imageBytes;
  String? _imageDataUrl;
  int _estaturaCm = 168;
  int _pesoKg = 62;
  FotoUsuario? _fotoProcesada;
  List<FotoUsuario> _fotosPrevias = [];

  // Step 2: Garment selection state
  List<Producto> _catalogo = [];
  bool _cargandoCatalogo = false;
  Producto? _prendaSeleccionada;
  String? _tallaSeleccionada;
  String? _colorSeleccionado;
  String? _colorHexSeleccionado;

  // Step 3 & 4: AI Simulation state
  String _aiProgressMessage = 'Analizando silueta corporal con IA...';
  SimulacionProbadorResult? _resultadoSimulacion;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prendaSeleccionada = widget.prendaInicial;
    _tallaSeleccionada = widget.tallaInicial;
    _colorSeleccionado = widget.colorInicial;

    _cargarCatalogo();
    _cargarFotosPrevias();
  }

  Future<void> _cargarFotosPrevias() async {
    final res = await ProbadorVirtualService.obtenerFotosRecientes();
    if (mounted) {
      setState(() {
        if (res['success'] == true && res['fotos'] is List<FotoUsuario>) {
          _fotosPrevias = res['fotos'] as List<FotoUsuario>;
        }
      });
    }
  }

  Future<void> _cargarCatalogo() async {
    setState(() => _cargandoCatalogo = true);
    final res = await ProductosService.listar(limit: 30);
    if (mounted) {
      setState(() {
        _cargandoCatalogo = false;
        if (res['success'] == true && res['items'] is List<Producto>) {
          _catalogo = res['items'] as List<Producto>;
          // Default selection if none passed
          if (_prendaSeleccionada == null && _catalogo.isNotEmpty) {
            _seleccionarPrenda(_catalogo.first);
          } else if (_prendaSeleccionada != null) {
            _inicializarTallasColores(_prendaSeleccionada!);
          }
        }
      });
    }
  }

  void _seleccionarPrenda(Producto prod) {
    setState(() {
      _prendaSeleccionada = prod;
      _inicializarTallasColores(prod);
    });
  }

  void _inicializarTallasColores(Producto prod) {
    if (prod.tallas.isNotEmpty) {
      if (_tallaSeleccionada == null || !prod.tallas.contains(_tallaSeleccionada)) {
        _tallaSeleccionada = prod.tallas.first;
      }
    } else {
      _tallaSeleccionada = 'M';
    }

    if (prod.colores.isNotEmpty) {
      if (_colorSeleccionado == null ||
          !prod.colores.any((c) => c.nombre == _colorSeleccionado)) {
        _colorSeleccionado = prod.colores.first.nombre;
        _colorHexSeleccionado = prod.colores.first.hex;
      }
    } else {
      _colorSeleccionado = null;
      _colorHexSeleccionado = null;
    }
  }

  // --- Photo acquisition ---
  Future<void> _tomarFoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1440,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final base64Str = base64Encode(bytes);
        setState(() {
          _imageBytes = bytes;
          _imageDataUrl = 'data:image/jpeg;base64,$base64Str';
          _fotoProcesada = null; // Re-upload required for new photo
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo capturar la imagen: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Provides a clean demo silhouette in case camera access is unavailable in emulator/testing.
  void _usarFotoDemo() {
    // 1x1 transparent/neutral png base64 expanded to valid representation
    const sampleDataUrl =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    );
    setState(() {
      _imageDataUrl = sampleDataUrl;
      _imageBytes = bytes;
      _fotoProcesada = null;
      _errorMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto de demostración cargada para simulación IA.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _seleccionarFotoPrevia(FotoUsuario foto) {
    setState(() {
      _fotoProcesada = foto;
      _imageDataUrl = foto.urlImagen;
      if (foto.estaturaCm != null) _estaturaCm = foto.estaturaCm!;
      if (foto.pesoKg != null) _pesoKg = foto.pesoKg!;
      _errorMessage = null;
    });
  }

  // --- Step 3: Run AI Virtual Try-On Simulation ---
  Future<void> _ejecutarSimulacionIA() async {
    if (_imageDataUrl == null && _fotoProcesada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor toma una foto o selecciona una imagen primero.'),
        ),
      );
      return;
    }

    if (_prendaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una prenda del catálogo para probarte.'),
        ),
      );
      return;
    }

    setState(() {
      _pasoActual = _PasoProbador.simulando;
      _aiProgressMessage = 'Subiendo fotografía y analizando proporciones...';
      _errorMessage = null;
    });

    try {
      // 1. Upload photo if not yet registered in backend
      int fotoId;
      if (_fotoProcesada != null) {
        fotoId = _fotoProcesada!.idFoto;
      } else {
        final uploadRes = await ProbadorVirtualService.subirFoto(
          imagenDataUrl: _imageDataUrl!,
          estatura: _estaturaCm,
          peso: _pesoKg,
        );

        if (uploadRes['success'] != true || uploadRes['foto'] == null) {
          throw Exception(
            uploadRes['message'] ?? 'Error al procesar la foto con el motor de IA.',
          );
        }

        final foto = uploadRes['foto'] as FotoUsuario;
        _fotoProcesada = foto;
        fotoId = foto.idFoto;
      }

      if (!mounted) return;
      setState(() {
        _aiProgressMessage = 'Motor IA calculando complexión y caída de prenda...';
      });

      // Small delay to allow user to experience the AI feedback visually
      await Future<void>.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;
      setState(() {
        _aiProgressMessage = 'Ajustando talla (${_tallaSeleccionada ?? "M"}) a tu silueta...';
      });

      // 2. Perform virtual try-on simulation
      final simRes = await ProbadorVirtualService.probarPrenda(
        fotoId: fotoId,
        productoId: _prendaSeleccionada!.idProducto,
        talla: _tallaSeleccionada ?? 'M',
        colorNombre: _colorSeleccionado,
        colorHex: _colorHexSeleccionado,
      );

      if (simRes['success'] != true || simRes['simulacion'] == null) {
        throw Exception(
          simRes['message'] ?? 'Error al procesar la simulación de la prenda.',
        );
      }

      final simulacion = simRes['simulacion'] as SimulacionProbadorResult;

      if (!mounted) return;
      setState(() {
        _resultadoSimulacion = simulacion;
        _pasoActual = _PasoProbador.resultado;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pasoActual = _PasoProbador.prenda;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Ocurrió un error en la simulación.'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  // --- Step 4 Post Actions: Cart & Reservation ---
  void _agregarAlCarrito() {
    if (_prendaSeleccionada == null) return;

    final talla = _resultadoSimulacion?.tallaSeleccionada ?? _tallaSeleccionada;
    final color = _resultadoSimulacion?.colorSeleccionado ?? _colorSeleccionado;

    CartService.instance.addItem(
      idProducto: _prendaSeleccionada!.idProducto,
      nombre: _prendaSeleccionada!.nombre,
      precioUnitario: _prendaSeleccionada!.precioVenta,
      cantidad: 1,
      talla: talla,
      color: color,
      imagenUrl: _prendaSeleccionada!.imagenUrl,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡${_prendaSeleccionada!.nombre} agregada a tu carrito!'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Ver Carrito',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  void _abrirReserva() {
    if (_prendaSeleccionada == null) return;

    final talla = _resultadoSimulacion?.tallaSeleccionada ?? _tallaSeleccionada;
    final color = _resultadoSimulacion?.colorSeleccionado ?? _colorSeleccionado;

    showDialog<bool>(
      context: context,
      builder: (_) => CrearReservaDialog(
        idProducto: _prendaSeleccionada!.idProducto,
        nombreProducto: _prendaSeleccionada!.nombre,
        precioUnitario: _prendaSeleccionada!.precioVenta,
        talla: talla,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.view_in_ar_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              'Probador Virtual IA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.purple.shade700),
                const SizedBox(width: 4),
                Text(
                  'CU25 / CU8',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: switch (_pasoActual) {
                _PasoProbador.foto => _buildPasoFoto(colorScheme),
                _PasoProbador.prenda => _buildPasoPrenda(colorScheme),
                _PasoProbador.simulando => _buildPasoSimulando(colorScheme),
                _PasoProbador.resultado => _buildPasoResultado(colorScheme),
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Step Indicator Header ---
  Widget _buildStepIndicator() {
    final steps = [
      ('1. Tu Foto', _PasoProbador.foto),
      ('2. Prenda', _PasoProbador.prenda),
      ('3. Simulación IA', _PasoProbador.resultado),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: steps.map((s) {
          final isDone = _pasoActual.index > s.$2.index ||
              (_pasoActual == _PasoProbador.resultado && s.$2 == _PasoProbador.resultado);
          final isCurrent = (_pasoActual == s.$2) ||
              (_pasoActual == _PasoProbador.simulando && s.$2 == _PasoProbador.resultado);

          return Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primary
                      : (isDone ? Colors.green.shade600 : Colors.grey.shade400),
                ),
                child: Center(
                  child: isDone && !isCurrent
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          s.$1.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                s.$1.substring(3),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade700,
                ),
              ),
              if (s != steps.last) ...[
                const SizedBox(width: 10),
                Container(width: 16, height: 1.5, color: Colors.grey.shade300),
                const SizedBox(width: 10),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- Step 1 View: Photo capture / selection ---
  Widget _buildPasoFoto(ColorScheme colorScheme) {
    final hasPhoto = _imageDataUrl != null || _fotoProcesada != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asistente Inteligente de Silueta',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Captura una foto de cuerpo completo o medio torso. La IA ajustará la prenda y recomendará tu talla exacta.',
                        style: TextStyle(fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Photo Preview Area
        Center(
          child: Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasPhoto ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
                width: hasPhoto ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: hasPhoto
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        _renderPhotoWidget(),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Foto lista para IA',
                                  style: TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_enhance_rounded,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sube o toma una foto para comenzar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Usa ropa neutra para una mejor detección de silueta',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Action Buttons: Camera / Gallery / Demo
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _tomarFoto(ImageSource.camera),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Cámara'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _tomarFoto(ImageSource.gallery),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Galería'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Foto de prueba (demo)',
              icon: const Icon(Icons.science_outlined),
              onPressed: _usarFotoDemo,
            ),
          ],
        ),

        // Recent photos history (if available)
        if (_fotosPrevias.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'Tus fotos previas:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 65,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fotosPrevias.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (ctx, idx) {
                final foto = _fotosPrevias[idx];
                final isSelected = _fotoProcesada?.idFoto == foto.idFoto;
                return InkWell(
                  onTap: () => _seleccionarFotoPrevia(foto),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1,
                      ),
                      color: Colors.grey.shade200,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_pin_circle_rounded,
                            size: 24,
                            color: isSelected ? colorScheme.primary : Colors.grey.shade700,
                          ),
                          Text(
                            '#${foto.idFoto}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Anthropometric Inputs (Estatura & Peso)
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.accessibility_new_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Medidas Opcionales (Recomendación precisa)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estatura: $_estaturaCm cm', style: const TextStyle(fontSize: 12)),
                          Slider(
                            value: _estaturaCm.toDouble(),
                            min: 120,
                            max: 210,
                            divisions: 90,
                            label: '$_estaturaCm cm',
                            onChanged: (v) => setState(() => _estaturaCm = v.round()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Peso: $_pesoKg kg', style: const TextStyle(fontSize: 12)),
                          Slider(
                            value: _pesoKg.toDouble(),
                            min: 35,
                            max: 130,
                            divisions: 95,
                            label: '$_pesoKg kg',
                            onChanged: (v) => setState(() => _pesoKg = v.round()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Confirm & Proceed to Garment Selection
        FilledButton.icon(
          onPressed: hasPhoto
              ? () => setState(() => _pasoActual = _PasoProbador.prenda)
              : null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text(
            'Continuar al Selector de Prendas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _renderPhotoWidget() {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    }
    if (_imageDataUrl != null && _imageDataUrl!.startsWith('data:image/')) {
      try {
        final commaIdx = _imageDataUrl!.indexOf(',');
        if (commaIdx != -1) {
          final b64 = _imageDataUrl!.substring(commaIdx + 1);
          return Image.memory(base64Decode(b64), fit: BoxFit.cover);
        }
      } catch (_) {}
    }
    return Container(
      color: Colors.grey.shade300,
      child: const Center(child: Icon(Icons.person, size: 72, color: Colors.grey)),
    );
  }

  // --- Step 2 View: Catalog Garment & Size Selector ---
  Widget _buildPasoPrenda(ColorScheme colorScheme) {
    if (_cargandoCatalogo) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Garment selector horizontal list
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prendas del Catálogo:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '${_catalogo.length} disponibles',
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
              ),
            ],
          ),
        ),

        // Horizontal Garment Carousel
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: _catalogo.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (ctx, idx) {
              final prod = _catalogo[idx];
              final isSelected = _prendaSeleccionada?.idProducto == prod.idProducto;

              return InkWell(
                onTap: () => _seleccionarPrenda(prod),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.25),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: prod.imagenUrl != null && prod.imagenUrl!.startsWith('http')
                              ? Image.network(
                                  prod.imagenUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.checkroom_rounded, color: Colors.grey),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.checkroom_rounded, color: Colors.grey),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prod.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            Text(
                              'Bs ${prod.precioVenta.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 16),

        // Selected Garment Details & Variant Customizer
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (_prendaSeleccionada != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: _prendaSeleccionada!.imagenUrl != null &&
                                _prendaSeleccionada!.imagenUrl!.startsWith('http')
                            ? Image.network(_prendaSeleccionada!.imagenUrl!, fit: BoxFit.cover)
                            : const Icon(Icons.checkroom, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _prendaSeleccionada!.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Bs ${_prendaSeleccionada!.precioVenta.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (_prendaSeleccionada!.descripcion != null)
                            Text(
                              _prendaSeleccionada!.descripcion!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Size Selector
                const Text(
                  'Elige la Talla que deseas probarte:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: (_prendaSeleccionada!.tallas.isNotEmpty
                          ? _prendaSeleccionada!.tallas
                          : ['S', 'M', 'L'])
                      .map((talla) {
                    final isSel = _tallaSeleccionada == talla;
                    return ChoiceChip(
                      label: Text(talla),
                      selected: isSel,
                      onSelected: (selected) {
                        if (selected) setState(() => _tallaSeleccionada = talla);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Color Selector
                if (_prendaSeleccionada!.colores.isNotEmpty) ...[
                  const Text(
                    'Color de la prenda:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _prendaSeleccionada!.colores.map((color) {
                      final isSel = _colorSeleccionado == color.nombre;
                      return ChoiceChip(
                        avatar: color.hex != null
                            ? CircleAvatar(
                                backgroundColor: _parseColor(color.hex!),
                                radius: 7,
                              )
                            : null,
                        label: Text(color.nombre),
                        selected: isSel,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _colorSeleccionado = color.nombre;
                              _colorHexSeleccionado = color.hex;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ],
          ),
        ),

        // Navigation bottom bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _pasoActual = _PasoProbador.foto),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Foto'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _prendaSeleccionada != null ? _ejecutarSimulacionIA : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.purple.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text(
                    'Iniciar Prueba Virtual con IA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Step 3 View: Dynamic AI Simulation in progress ---
  Widget _buildPasoSimulando(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.shade300.withValues(alpha: 0.4),
                    Colors.purple.shade50.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Motor de Inteligencia Artificial',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _aiProgressMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology_rounded, size: 18, color: Colors.purple),
                  SizedBox(width: 8),
                  Text(
                    'Ajustando malla 3D y complexión física...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 4 View: Simulation Results & Actions ---
  Widget _buildPasoResultado(ColorScheme colorScheme) {
    final sim = _resultadoSimulacion;
    if (sim == null) {
      return Center(
        child: ElevatedButton(
          onPressed: () => setState(() => _pasoActual = _PasoProbador.prenda),
          child: const Text('Volver al selector'),
        ),
      );
    }

    final ajuste = sim.ajusteEstimado.toUpperCase();
    final (fitColor, fitIcon, fitLabel, fitDesc) = switch (ajuste) {
      'PERFECTO' => (
          Colors.green.shade700,
          Icons.verified_rounded,
          'Ajuste Perfecto',
          'La prenda armoniza exactamente con tu complexión y proporciones corporales.',
        ),
      'AJUSTADO' => (
          Colors.amber.shade800,
          Icons.warning_amber_rounded,
          'Ajuste Ceñido / Al Cuerpo',
          'La prenda quedará ceñida. Si buscas un estilo más holgado, te sugerimos una talla más.',
        ),
      'HOLGADO' => (
          Colors.blue.shade700,
          Icons.info_outline_rounded,
          'Ajuste Holgado / Relajado',
          'La prenda tendrá una caída amplia/oversized. Si prefieres entallado, prueba una talla menos.',
        ),
      _ => (
          Colors.grey.shade700,
          Icons.help_outline_rounded,
          ajuste,
          'Ajuste estimado por el motor de IA.',
        ),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Result Visualizer (Photo + Garment Overlay)
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Base User Photo
                _renderPhotoWidget(),

                // Visual AR Try-On Banner overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),

                // Top Tag: AI Virtual Fitted
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade900.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purpleAccent.shade100, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Simulación IA Completada',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Product Info Preview
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 48,
                          height: 48,
                          color: Colors.white,
                          child: sim.prendaImagenUrl != null &&
                                  sim.prendaImagenUrl!.startsWith('http')
                              ? Image.network(sim.prendaImagenUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.checkroom, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sim.productoNombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Probando Talla: ${sim.tallaSeleccionada} • ${_colorSeleccionado ?? "Color original"}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
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
        ),

        const SizedBox(height: 18),

        // AI Fit & Sizing Analysis Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: fitColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(fitIcon, color: fitColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fitLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: fitColor,
                            ),
                          ),
                          Text(
                            fitDesc,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Metrics comparison: Selected Size vs Recommended Size
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricBox(
                      label: 'Talla Probada',
                      value: sim.tallaSeleccionada,
                      isHighlighted: false,
                    ),
                    const Icon(Icons.compare_arrows_rounded, color: Colors.grey),
                    _buildMetricBox(
                      label: 'Talla Recomendada IA',
                      value: sim.tallaRecomendada,
                      isHighlighted: true,
                      color: Colors.purple.shade700,
                    ),
                    _buildMetricBox(
                      label: 'Complexión',
                      value: _fotoProcesada?.complexion ?? 'MEDIA',
                      isHighlighted: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Direct Action Buttons: Cart (CU15) & Reservation (CU14)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _abrirReserva,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.bookmark_border_rounded),
                label: const Text(
                  'Reservar Prenda',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _agregarAlCarrito,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text(
                  'Añadir al Carrito',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Try Another Garment Button (reusing same photo)
        TextButton.icon(
          onPressed: () => setState(() => _pasoActual = _PasoProbador.prenda),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Probar otra prenda con esta foto'),
        ),
        TextButton.icon(
          onPressed: () => setState(() => _pasoActual = _PasoProbador.foto),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Cambiar o actualizar fotografía'),
        ),
      ],
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required bool isHighlighted,
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isHighlighted
                ? (color ?? Colors.purple.shade700).withValues(alpha: 0.12)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHighlighted
                  ? (color ?? Colors.purple.shade700).withValues(alpha: 0.5)
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? (color ?? Colors.purple.shade700) : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    var cleanHex = hex.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    final parsed = int.tryParse(cleanHex, radix: 16);
    if (parsed == null) return Colors.grey;
    return Color(parsed);
  }
}
