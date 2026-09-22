import 'package:flutter/material.dart';

import '../../../catalog/presentation/screens/home_screen.dart';
import '../../data/auth_service.dart';

/// Screen that allows a new client (Rol C) to register in the Attention platform.
///
/// Implements with client-side validation in Spanish, password matching,
/// loading feedback, and automatic login redirection upon success.
class RegisterScreen extends StatefulWidget {
 const RegisterScreen({super.key});

 @override
 State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
 final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
 final TextEditingController _nombreController = TextEditingController();
 final TextEditingController _apellidoController = TextEditingController();
 final TextEditingController _emailController = TextEditingController();
 final TextEditingController _passwordController = TextEditingController();
 final TextEditingController _confirmPasswordController =
 TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar =>
      _passwordController.text.contains(RegExp(r'[@$!%*?&._#\-+=~^<>/\\|]'));
  bool get _isPasswordSecure =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecialChar;

  Widget _buildRequisitoItem(String texto, bool cumplido) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            cumplido
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: cumplido ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                color: cumplido ? Colors.green.shade800 : Colors.grey.shade700,
                fontWeight: cumplido ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

 /// Validates the form and invokes [AuthService.register].
 Future<void> _handleRegister() async {
 FocusScope.of(context).unfocus();

 if (!_formKey.currentState!.validate()) {
 return;
 }

 setState(() => _isLoading = true);

 try {
 final email = _emailController.text.trim();
 final password = _passwordController.text;

 final result = await AuthService.register(
 nombre: _nombreController.text.trim(),
 apellido: _apellidoController.text.trim().isEmpty
 ? null
 : _apellidoController.text.trim(),
 email: email,
 password: password,
 );

 if (!mounted) return;

 if (result['success'] == true) {
 // Automatic login after successful registration for a frictionless client UX.
 final loginResult = await AuthService.login(email, password);

 if (!mounted) return;

 if (loginResult['success'] == true) {
 Navigator.of(context).pushAndRemoveUntil(
 MaterialPageRoute(builder: (_) => const HomeScreen()),
 (route) => false,
 );
 } else {
 // Registration was created but auto-login had an issue; take to LoginScreen.
 Navigator.of(context).pop();
 ScaffoldMessenger.of(context)
 ..clearSnackBars()
 ..showSnackBar(
 const SnackBar(
 content: Text('¡Cuenta creada exitosamente! Inicia sesión.'),
 backgroundColor: Colors.green,
 behavior: SnackBarBehavior.floating,
 duration: Duration(seconds: 2),
 ),
 );
 }
 } else {
 ScaffoldMessenger.of(context)
 ..clearSnackBars()
 ..showSnackBar(
 SnackBar(
 content: Text(result['message'] as String),
 backgroundColor: Colors.redAccent,
 behavior: SnackBarBehavior.floating,
 duration: const Duration(seconds: 2),
 ),
 );
 }
 } catch (e) {
 if (mounted) {
 ScaffoldMessenger.of(context)
 ..clearSnackBars()
 ..showSnackBar(
 SnackBar(
 content: Text('Error inesperado al registrar cuenta: $e'),
 backgroundColor: Colors.redAccent,
 behavior: SnackBarBehavior.floating,
 duration: const Duration(seconds: 2),
 ),
 );
 }
 } finally {
 if (mounted) {
 setState(() => _isLoading = false);
 }
 }
 }

 @override
 Widget build(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;

 return Scaffold(
 appBar: AppBar(title: const Text('Crear Cuenta')),
 body: Center(
 child: SingleChildScrollView(
 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
 child: ConstrainedBox(
 constraints: const BoxConstraints(maxWidth: 420),
 child: Form(
 key: _formKey,
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 Icon(
 Icons.person_add_outlined,
 size: 56,
 color: colorScheme.primary,
 ),
 const SizedBox(height: 12),
 Text(
 'Únete a Attention',
 textAlign: TextAlign.center,
 style: Theme.of(context)
 .textTheme
 .headlineMedium
 ?.copyWith(fontWeight: FontWeight.bold),
 ),
 const SizedBox(height: 4),
 Text(
 'Crea tu cuenta de cliente para comprar y usar el probador virtual',
 textAlign: TextAlign.center,
 style: Theme.of(context).textTheme.bodyMedium,
 ),
 const SizedBox(height: 24),
 TextFormField(
 controller: _nombreController,
 decoration: const InputDecoration(
 labelText: 'Nombre *',
 hintText: 'Ej. Juan',
 prefixIcon: Icon(Icons.badge_outlined),
 ),
 textCapitalization: TextCapitalization.words,
 validator: (value) {
 if (value == null || value.trim().isEmpty) {
 return 'El nombre es requerido.';
 }
 return null;
 },
 ),
 const SizedBox(height: 16),
 TextFormField(
 controller: _apellidoController,
 decoration: const InputDecoration(
 labelText: 'Apellido (opcional)',
 hintText: 'Ej. Pérez',
 prefixIcon: Icon(Icons.person_outline),
 ),
 textCapitalization: TextCapitalization.words,
 ),
 const SizedBox(height: 16),
 TextFormField(
 controller: _emailController,
 decoration: const InputDecoration(
 labelText: 'Correo electrónico *',
 hintText: 'correo@ejemplo.com',
 prefixIcon: Icon(Icons.email_outlined),
 ),
 keyboardType: TextInputType.emailAddress,
 autofillHints: const [AutofillHints.email],
 validator: (value) {
 if (value == null || value.trim().isEmpty) {
 return 'El correo es requerido.';
 }
 final email = value.trim();
 final at = email.indexOf('@');
 if (at <= 0 || at != email.lastIndexOf('@')) {
 return 'Ingresa un correo válido.';
 }
 final domain = email.substring(at + 1);
 if (!domain.contains('.') || domain.startsWith('.')) {
 return 'Ingresa un correo válido.';
 }
 return null;
 },
 ),
 const SizedBox(height: 16),
 TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  helperText: 'Mínimo 8 caracteres (A-Z, a-z, 0-9 y especial)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    tooltip: _obscurePassword
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es requerida.';
                  }
                  if (value.length < 8) {
                    return 'Debe tener al menos 8 caracteres.';
                  }
                  if (!value.contains(RegExp(r'[A-Z]'))) {
                    return 'Debe incluir al menos una letra mayúscula (A-Z).';
                  }
                  if (!value.contains(RegExp(r'[a-z]'))) {
                    return 'Debe incluir al menos una letra minúscula (a-z).';
                  }
                  if (!value.contains(RegExp(r'[0-9]'))) {
                    return 'Debe incluir al menos un número (0-9).';
                  }
                  if (!value.contains(RegExp(r'[@$!%*?&._#\-+=~^<>/\\|]'))) {
                    return 'Debe incluir al menos un carácter especial (@\$!%*?&).';
                  }
                  return null;
                },
              ),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isPasswordSecure
                          ? Colors.green.shade400
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requisitos de seguridad:',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      _buildRequisitoItem('Mínimo 8 caracteres', _hasMinLength),
                      _buildRequisitoItem(
                          'Una letra mayúscula (A-Z)', _hasUppercase),
                      _buildRequisitoItem(
                          'Una letra minúscula (a-z)', _hasLowercase),
                      _buildRequisitoItem('Un número (0-9)', _hasNumber),
                      _buildRequisitoItem(
                          'Un carácter especial (@\$!%*?&)', _hasSpecialChar),
                    ],
                  ),
                ),
              ],
 const SizedBox(height: 16),
 TextFormField(
 controller: _confirmPasswordController,
 decoration: InputDecoration(
 labelText: 'Confirmar contraseña *',
 prefixIcon: const Icon(Icons.lock_reset_outlined),
 suffixIcon: IconButton(
 icon: Icon(
 _obscureConfirmPassword
 ? Icons.visibility_outlined
 : Icons.visibility_off_outlined,
 ),
 tooltip: _obscureConfirmPassword
 ? 'Mostrar contraseña'
 : 'Ocultar contraseña',
 onPressed: () {
 setState(() => _obscureConfirmPassword =
 !_obscureConfirmPassword);
 },
 ),
 ),
 obscureText: _obscureConfirmPassword,
 validator: (value) {
 if (value == null || value.isEmpty) {
 return 'Por favor confirma tu contraseña.';
 }
 if (value != _passwordController.text) {
 return 'Las contraseñas no coinciden.';
 }
 return null;
 },
 ),
 const SizedBox(height: 24),
 ElevatedButton(
 onPressed: _isLoading ? null : _handleRegister,
 style: ElevatedButton.styleFrom(
 minimumSize: const Size.fromHeight(48),
 ),
 child: _isLoading
 ? const SizedBox(
 width: 20,
 height: 20,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : const Text('Crear Cuenta'),
 ),
 const SizedBox(height: 16),
 Wrap(
 alignment: WrapAlignment.center,
 crossAxisAlignment: WrapCrossAlignment.center,
 children: [
 const Text('¿Ya tienes una cuenta?'),
 TextButton(
 onPressed: _isLoading
 ? null
 : () => Navigator.of(context).pop(),
 child: const Text('Inicia sesión'),
 ),
 ],
 ),
 ],
 ),
 ),
 ),
 ),
 ),
 );
 }
}
