import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Ilustración
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                    size: 60,
                    color: _emailSent ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Título
                Text(
                  _emailSent ? '¡Correo enviado!' : 'Recuperar contraseña',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Descripción
                Text(
                  _emailSent 
                    ? 'Hemos enviado un enlace de recuperación a:\n**${_emailController.text}**\n\nRevisa tu bandeja de entrada y la carpeta de spam.'
                    : 'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (!_emailSent) ...[
                  // Campo de email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Ingresa un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botón de enviar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C6BC0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Enviar enlace de recuperación',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],

                if (_emailSent) ...[
                  // Botones después del envío
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Volver al login',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _emailSent = false;
                        _emailController.clear();
                      });
                    },
                    child: const Text('Enviar a otro email'),
                  ),
                ],

                const SizedBox(height: 32),
                
                // Información
                _buildInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Información importante',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Funciona para cuentas con email/contraseña\n'
            '• También para cuentas de Google con contraseña vinculada\n'
            '• El enlace expira en 1 hora\n'
            '• Revisa la carpeta de spam si no lo encuentras',
            style: TextStyle(
              color: Colors.blue.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String email = _emailController.text.trim();
      
      print('🔄 Enviando email de recuperación a: $email');
      
      // VERIFICACIÓN: Buscar usuario en Firestore primero
      final userDoc = await _findUserInFirestore(email);
      
      if (userDoc != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final provider = userData['provider'] ?? 'email';
        final hasPassword = userData['hasPassword'] ?? true;
        
        print('📝 Usuario encontrado - Provider: $provider, HasPassword: $hasPassword');
        
        if (provider == 'google' && !hasPassword) {
          _showNoPasswordDialog();
          return;
        }
      }

      // ENVÍO SIMPLIFICADO - Sin ActionCodeSettings problemáticos
      await _auth.sendPasswordResetEmail(email: email);
      
      print('✅ Email de recuperación enviado exitosamente');
      
      setState(() => _emailSent = true);
      _showSuccessSnackBar('✅ Enlace enviado a $email');
      
    } on FirebaseAuthException catch (e) {
      print('❌ Error Firebase: ${e.code} - ${e.message}');
      _handleFirebaseError(e);
    } catch (e) {
      print('❌ Error inesperado: $e');
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String errorMessage;
    
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No existe una cuenta con este email.';
        break;
      case 'invalid-email':
        errorMessage = 'El formato del email no es válido.';
        break;
      case 'invalid-continue-uri':
      case 'unauthorized-continue-uri':
        errorMessage = 'Error de configuración. Por favor contacta al soporte.';
        break;
      case 'too-many-requests':
        errorMessage = 'Demasiados intentos. Por favor espera unos minutos.';
        break;
      default:
        errorMessage = 'Error: ${e.message}';
    }
    
    _showErrorSnackBar(errorMessage);
  }

  Future<DocumentSnapshot?> _findUserInFirestore(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    } catch (e) {
      print('Error buscando usuario: $e');
      return null;
    }
  }

  void _showNoPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sin contraseña'),
        content: const Text(
          'Esta cuenta no tiene una contraseña configurada.\n\n'
          'Inicia sesión con Google y crea una contraseña en la configuración de tu perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}