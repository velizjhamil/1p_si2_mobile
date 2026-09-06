# CLAUDE.md — Attention Mobile (Flutter)

## Proyecto
**Attention** — Plataforma inteligente de e-commerce para tienda de ropa con vestidor virtual vía Realidad Aumentada.
Universidad Autónoma Gabriel René Moreno (UAGRM) · FICCT · Sistemas de Información II · Gestión 2-2026

---

## Stack técnico
| Capa | Tecnología |
|---|---|
| Framework | Flutter 3.x (Dart) |
| Estado | Provider o Riverpod |
| HTTP | Dio |
| Auth | JWT en FlutterSecureStorage |
| Navegación | GoRouter |
| AR (Ciclo 2) | ARCore/ARKit via flutter_ar |

---

## Estructura de carpetas (NO modificar)
```
lib/
├── core/
│   ├── constants/       # URLs, colores, strings
│   ├── models/          # Clases Dart (entidades)
│   ├── services/        # AuthService, ApiService
│   └── utils/           # Helpers, validadores
├── features/
│   ├── auth/            # Login, logout — CU1, CU2
│   │   ├── data/        # repositories, datasources
│   │   ├── domain/      # entities, usecases
│   │   └── presentation/# screens, widgets, providers
│   ├── catalogo/        # CU7 — ver productos
│   ├── probador/        # CU8 — vestidor virtual AR
│   ├── reservas/        # CU14 — reservar prendas
│   ├── carrito/         # CU15 — carrito de compras
│   └── perfil/          # Datos del cliente
├── shared/
│   ├── widgets/         # Widgets reutilizables
│   └── themes/          # ThemeData del app
└── main.dart
```

---

## Paleta de colores (marca Attention)
```dart
class AppColors {
  static const primary   = Color(0xFF000000); // Negro
  static const secondary = Color(0xFF1F2937); // Gris oscuro
  static const background= Color(0xFFF9FAFB); // Gris claro
  static const surface   = Color(0xFFFFFFFF); // Blanco
  static const success   = Color(0xFF16A34A); // Verde
  static const error     = Color(0xFFDC2626); // Rojo
  static const accent    = Color(0xFF6B7280); // Gris medio
}
```

---

## Actores en mobile
- **Cliente (C)**: app principal — catálogo, vestidor AR, reservas, carrito, compra
- **Vendedor (V)**: vistas reducidas — registro de venta presencial, consulta inventario
- El rol se determina al login y condiciona la navegación

---

## Convenciones de código

### Modelos
```dart
class Usuario {
  final String idUsuario; // UUID
  final String nombre;
  final String correo;
  final String estado;
  final Rol rol;

  const Usuario({...});

  factory Usuario.fromJson(Map<String, dynamic> json) => ...
  Map<String, dynamic> toJson() => ...
}
```

### API Service base
```dart
// Base URL desde constants
const String baseUrl = 'http://tu-api.com/api/v1';
// Dio con interceptor que agrega JWT en header Authorization
```

### Widgets reutilizables a crear (shared/widgets/)
- `AttentionButton` — botón primario con loading state
- `AttentionTextField` — input con validación
- `AttentionCard` — card con sombra y bordes redondeados
- `LoadingOverlay` — overlay de carga
- `ConfirmDialog` — diálogo de confirmación

---

## Reglas para el agente

### Al generar una pantalla:
1. Separar lógica de UI — la pantalla solo muestra, el provider/notifier maneja estado.
2. Manejar tres estados: `loading`, `data`, `error`.
3. Usar `AppColors` para todos los colores — nunca hardcodear.
4. Los textos de error y labels siempre en español.
5. Usar `FlutterSecureStorage` para el token JWT — nunca SharedPreferences para datos sensibles.

### Orden de generación por feature:
1. `core/models/{entidad}.dart` — clase Dart con fromJson/toJson
2. `features/{feature}/data/{feature}_service.dart` — llamadas Dio
3. `features/{feature}/presentation/providers/{feature}_provider.dart` — estado
4. `features/{feature}/presentation/screens/{feature}_screen.dart` — UI
5. Agregar ruta en GoRouter

### Casos de uso mobile (Ciclo 1 y 2 prioritarios):
- CU1/CU2: Login / Logout — **PRIMERO**
- CU7: Ver catálogo con filtros
- CU8: Vestidor virtual (AR) — **diferenciador clave**
- CU14: Reservar prendas
- CU15: Carrito
- CU21: Compra con Libélula