import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_app/home/home_screen.dart';
import 'package:firebase_auth_app/home/main_shell.dart';
import 'package:firebase_auth_app/login/complete_profile_screen.dart';
import 'package:firebase_auth_app/login/forgot_password_screen.dart';
import 'package:firebase_auth_app/login/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- CONFIGURACIÓN DE COLORES ---
const Color _startColor = Color(0xFF6A1B9A);
const Color _endColor = Color(0xFF42A5F5);
const Color _loginButtonColor = Color(0xFF5C6BC0);

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _checkIfUserIsLoggedIn();
  }

  Future<void> _checkIfUserIsLoggedIn() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _navigateToHome();
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      print('Intentando login con: $email');

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Login exitoso: ${userCredential.user?.email}');
      _navigateToHome();

    } on FirebaseAuthException catch (e) {
      print('Error Firebase: ${e.code} - ${e.message}');
      
      String errorMessage = 'Error al iniciar sesión';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este email.';
          _checkIfUserUsesGoogleSignIn(_emailController.text.trim());
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta.';
          _checkIfUserUsesGoogleSignIn(_emailController.text.trim());
          break;
        case 'invalid-email':
          errorMessage = 'El formato del email no es válido.';
          break;
        case 'user-disabled':
          errorMessage = 'Esta cuenta ha sido deshabilitada.';
          break;
        case 'too-many-requests':
          errorMessage = 'Demasiados intentos. Intenta más tarde.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'El inicio de sesión con email/password no está habilitado.';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      print('Error inesperado: $e');
      _showErrorSnackBar('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // MÉTODO FALTANTE - Google Sign-In para Web
  Future<UserCredential> _signInWithGoogleWeb() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
      });

      final UserCredential userCredential = 
          await _auth.signInWithPopup(googleProvider);

      return userCredential;

    } catch (e) {
      print('Error en Google Web: $e');
      
      // Si falla el popup, intentar con redirect
      try {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await _auth.signInWithRedirect(googleProvider);
        // Con redirect, la app se recargará automáticamente después del login
        throw Exception('Redirect initiated');
      } catch (e2) {
        print('Error en redirect: $e2');
        rethrow;
      }
    }
  }

  // MÉTODO FALTANTE - Google Sign-In para Móvil
  Future<UserCredential> _signInWithGoogleMobile() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('User cancelled Google sign-in');
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);

      return userCredential;

    } catch (e) {
      print('Error en Google Mobile: $e');
      rethrow;
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      UserCredential userCredential;
      
      if (kIsWeb) {
        userCredential = await _signInWithGoogleWeb();
      } else {
        userCredential = await _signInWithGoogleMobile();
      }

      if (userCredential.user != null) {
        // Verificar si es un usuario nuevo o existente
        final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser) {
          // Usuario nuevo - redirigir a completar perfil
          _navigateToCompleteProfile(userCredential.user!);
        } else {
          // Usuario existente - verificar si tiene perfil completo
          await _checkUserProfile(userCredential.user!);
        }
      }

    } catch (e) {
      print('Error en Google Sign-In: $e');
      _showErrorSnackBar('Error al iniciar sesión con Google: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkUserProfile(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists || doc.data()?['profileCompleted'] != true) {
        // Usuario existe pero no tiene perfil completo
        _navigateToCompleteProfile(user);
      } else {
        // Usuario con perfil completo - ir al home
        _navigateToHome();
      }
    } catch (e) {
      print('Error al verificar perfil: $e');
      // En caso de error, ir al home
      _navigateToHome();
    }
  }

  void _navigateToCompleteProfile(User user) {
    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => CompleteProfileScreen(user: user),
      ),
      (Route<dynamic> route) => false,
    );
  }

  void _checkIfUserUsesGoogleSignIn(String email) async {
    try {
      final List<String> methods = await _auth.fetchSignInMethodsForEmail(email);
      
      if (methods.contains('google.com')) {
        _showInfoDialog(
          '📧 Cuenta registrada con Google',
          'Este email está registrado usando Google. '
          '**Para tu seguridad, debes usar el botón "Continuar con Google".**\n\n'
          '🔒 **Por seguridad, Google no permite usar tu contraseña de Gmail en otras aplicaciones.**',
        );
      } else if (methods.isEmpty) {
        _showInfoDialog(
          'Cuenta no encontrada',
          'No existe una cuenta con este email. ¿Quieres crear una nueva cuenta?',
          showRegisterButton: true,
        );
      }
    } catch (e) {
      print('Error al verificar métodos de sign-in: $e');
    }
  }

  void _showInfoDialog(String title, String message, {bool showRegisterButton = false}) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (showRegisterButton)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: const Text('Registrarse'),
            ),
        ],
      ),
    );
  }

  // NUEVO MÉTODO - Navegar a la pantalla de recuperación de contraseña
  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  void _navigateToHome() {
    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => MainShell()),
      (Route<dynamic> route) => false,
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 600),
          decoration: BoxDecoration( 
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: isLargeScreen
              ? Row(
                  children: [
                    const Expanded(
                      flex: 1,
                      child: _BuildSignUpPanel(
                        startColor: _startColor,
                        endColor: _endColor,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _BuildLoginPanel(
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        primaryColor: _loginButtonColor,
                        isLoading: _isLoading,
                        rememberMe: _rememberMe,
                        obscurePassword: _obscurePassword,
                        onRememberMeChanged: (value) => setState(() => _rememberMe = value),
                        onObscurePasswordChanged: () => setState(() => _obscurePassword = !_obscurePassword),
                        onLogin: _login,
                        onGoogleSignIn: _signInWithGoogle,
                        onForgotPassword: _navigateToForgotPassword, // CAMBIO AQUÍ
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _BuildLoginPanel(
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        primaryColor: _loginButtonColor,
                        isLoading: _isLoading,
                        rememberMe: _rememberMe,
                        obscurePassword: _obscurePassword,
                        onRememberMeChanged: (value) => setState(() => _rememberMe = value),
                        onObscurePasswordChanged: () => setState(() => _obscurePassword = !_obscurePassword),
                        onLogin: _login,
                        onGoogleSignIn: _signInWithGoogle,
                        onForgotPassword: _navigateToForgotPassword, // CAMBIO AQUÍ
                      ),
                      const _BuildSignUpPanel(
                        startColor: _startColor,
                        endColor: _endColor,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _BuildSignUpPanel extends StatelessWidget {
  final Color startColor;
  final Color endColor;

  const _BuildSignUpPanel({
    required this.startColor,
    required this.endColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '¿Eres nuevo aquí?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Regístrate y descubre todas las funcionalidades que tenemos para ti.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 180,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Registrarse',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildLoginPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Color primaryColor;
  final bool isLoading;
  final bool rememberMe;
  final bool obscurePassword;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onObscurePasswordChanged;
  final VoidCallback onLogin;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onForgotPassword; // CAMBIO DE NOMBRE AQUÍ

  const _BuildLoginPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.primaryColor,
    required this.isLoading,
    required this.rememberMe,
    required this.obscurePassword,
    required this.onRememberMeChanged,
    required this.onObscurePasswordChanged,
    required this.onLogin,
    required this.onGoogleSignIn,
    required this.onForgotPassword, // CAMBIO DE NOMBRE AQUÍ
  });

  InputDecoration _inputDecoration(String hint, {bool isPassword = false}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: onObscurePasswordChanged,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bienvenido de vuelta',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            const Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('tu@email.com'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El email es requerido';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Ingresa un email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: _inputDecoration('Ingresa tu contraseña', isPassword: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La contraseña es requerida';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (value) => onRememberMeChanged(value ?? false),
                      activeColor: primaryColor,
                    ),
                    const Text('Recordarme'),
                  ],
                ),
                TextButton(
                  onPressed: onForgotPassword, // CAMBIO AQUÍ
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'O continúa con',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onGoogleSignIn,
                icon: Image.asset(
                  'images/google_icon.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.g_mobiledata, color: Colors.red, size: 24);
                  },
                ),
                label: const Text(
                  'Continuar con Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}