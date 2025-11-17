import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_app/home/main_shell.dart'; // Import MainShell
import 'package:flutter/material.dart';

class CompleteProfileScreen extends StatefulWidget {
final User user;
final Map<String, dynamic>? additionalData;
const CompleteProfileScreen({
Key? key,
 required this.user,
 this.additionalData,
 }) : super(key: key);

 @override
 _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
 final _formKey = GlobalKey<FormState>();
 final _usernameController = TextEditingController();
final _passwordController = TextEditingController();
final _confirmPasswordController = TextEditingController();
bool _isLoading = false;
 bool _obscurePassword = true;
 bool _obscureConfirmPassword = true;

 final FirebaseAuth _auth = FirebaseAuth.instance;
 final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 @override
 void initState() {
  super.initState();
  // Pre-llenar el nombre de usuario si viene de Google
  if (widget.user.displayName != null && widget.user.displayName!.isNotEmpty) {
   _usernameController.text = widget.user.displayName!.replaceAll(' ', '_').toLowerCase();
  }
 }

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   appBar: AppBar(
    title: const Text('Completar Perfil'),
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Colors.black,
    leading: IconButton(
     icon: const Icon(Icons.arrow_back),
     onPressed: () => _showExitDialog(),
    ),
   ),
   body: SingleChildScrollView(
    padding: const EdgeInsets.all(24.0),
    child: Form(
     key: _formKey,
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       // Header con avatar
       Center(
        child: Container(
         width: 100,
         height: 100,
         decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade300, width: 2),
         ),
         child: widget.user.photoURL != null
           ? CircleAvatar(
             backgroundImage: NetworkImage(widget.user.photoURL!),
             radius: 50,
            )
           : const Icon(
             Icons.person,
             size: 50,
             color: Colors.grey,
            ),
        ),
       ),
       const SizedBox(height: 20),
       const Center(
        child: Text(
         '¡Ya casi terminas!',
         style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
         ),
        ),
       ),
       const SizedBox(height: 8),
       Center(
        child: Text(
         'Completa tu perfil para continuar',
style: TextStyle(
 fontSize: 16,
 color: Colors.grey.shade600,
         ),
        ),
       ),
       const SizedBox(height: 32),

       // Email (solo lectura)
       const Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.w600)),
       const SizedBox(height: 8),
       Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
         color: Colors.grey.shade100,
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
         children: [
          const Icon(Icons.email, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
           child: Text(
            widget.user.email ?? 'No email',
            style: const TextStyle(fontSize: 16),
           ),
          ),
         ],
        ),
       ),
       const SizedBox(height: 20),

       // Username
       const Text('Nombre de Usuario', style: TextStyle(fontWeight: FontWeight.w600)),
       const SizedBox(height: 8),
       TextFormField(
        controller: _usernameController,
        decoration: _inputDecoration('Ej: juan_perez'),
        validator: (value) {
         if (value == null || value.isEmpty) {
          return 'El nombre de usuario es requerido';
         }
         if (value.length < 3) {
          return 'Mínimo 3 caracteres';
         }
         // --- CAMBIO: Validar nombre, no solo username ---
         // if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
         //  return 'Solo letras, números y guiones bajos';
         // }
         return null;
        },
       ),
       const SizedBox(height: 16),

       // Contraseña (SOLO si no es Google o si queremos permitir crear contraseña)
       _buildPasswordSection(),
       const SizedBox(height: 32),

       // Botón de completar
       SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
         onPressed: _isLoading ? null : _completeProfile,
         style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C6BC0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(8),
          ),
         ),
         child: _isLoading
           ? const SizedBox(
             width: 20,
             height: 20,
             child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
             ),
            )
           : const Text(
             'Completar Registro',
             style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
             ),
            ),
        ),
       ),

       // Opción para saltar
       const SizedBox(height: 16),
       Center(
        child: TextButton(
         onPressed: _isLoading ? null : _skipForNow,
         child: const Text(
          'Completar después',
          style: TextStyle(color: Colors.grey),
         ),
        ),
       ),
      ],
     ),
    ),
   ),
  );
 }

 Widget _buildPasswordSection() {
  // Verificar si el usuario ya tiene proveedores vinculados
  final hasPasswordProvider = widget.user.providerData
    .any((userInfo) => userInfo.providerId == 'password');
  
  if (hasPasswordProvider) {
   // Si ya tiene contraseña, no mostrar la sección
   return const SizedBox();
  }

  return Column(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
    const Text('Crear Contraseña', style: TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    TextFormField(
     controller: _passwordController,
     obscureText: _obscurePassword,
     decoration: _inputDecoration(
      'Mínimo 6 caracteres',
      isPassword: true,
      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
     ),
     validator: (value) {
      // --- CAMBIO: La contraseña es opcional si el usuario es de Google ---
      if (value == null || value.isEmpty) {
       // Si el usuario es de Google, no pasa nada si está vacío
       if (widget.user.providerData.any((p) => p.providerId == 'google.com')) {
        return null; 
       }
       // Si es un usuario de Email/Pass, es requerido
       return 'La contraseña es requerida';
      }
      if (value.length < 6) {
       return 'Mínimo 6 caracteres';
      }
      return null;
     },
    ),
    const SizedBox(height: 16),

    const Text('Confirmar Contraseña', style: TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    TextFormField(
     controller: _confirmPasswordController,
     obscureText: _obscureConfirmPassword,
     decoration: _inputDecoration(
      'Repite tu contraseña',
      isPassword: true,
      onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
     ),
     validator: (value) {
      // Si la contraseña principal está vacía, esta también puede estarlo
      if (_passwordController.text.isEmpty && (value == null || value.isEmpty)) {
       return null;
      }
      if (value != _passwordController.text) {
       return 'Las contraseñas no coinciden';
      }
      return null;
     },
    ),
    const SizedBox(height: 8),
    Text(
     '🔒 Esta contraseña te permitirá iniciar sesión con email y contraseña',
     style: TextStyle(
      fontSize: 12,
      color: Colors.blue.shade700,
     ),
    ),
   ],
  );
 }

 InputDecoration _inputDecoration(String hint, {bool isPassword = false, VoidCallback? onToggle}) {
  // --- CAMBIO: Detectar cuál icono de password mostrar ---
  IconData visibilityIcon = Icons.visibility;
  if(hint.contains('Repite')) { // Si es el campo de confirmar
   visibilityIcon = _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off;
  } else { // Si es el campo de password principal
   visibilityIcon = _obscurePassword ? Icons.visibility : Icons.visibility_off;
  }

  return InputDecoration(
   hintText: hint,
   filled: true,
   fillColor: Colors.white,
   isDense: true,
   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
   border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.grey, width: 1),
   ),
   enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.grey, width: 1),
   ),
   focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Color(0xFF5C6BC0), width: 2),
   ),
   suffixIcon: isPassword
     ? IconButton(
       icon: Icon(
        // --- CAMBIO: Usar el icono determinado ---
        visibilityIcon, 
        color: Colors.grey,
       ),
       onPressed: onToggle,
      )
     : null,
  );
 }

 Future<void> _completeProfile() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
   // --- CAMBIO: 'username' ahora es el nombre de usuario (con mayúsculas) ---
   // y creamos un 'usernameLower' para la búsqueda
   final String displayName = _usernameController.text.trim();
   final String usernameLower = displayName.toLowerCase();
   final String email = widget.user.email!;
   final String password = _passwordController.text.trim();
   bool hasPassword = false;

   print('Iniciando proceso de completar perfil para: $email');

   // 1. Verificar si el username está disponible
   final usernameQuery = await _firestore
     .collection('users')
     .where('username', isEqualTo: usernameLower)
     .limit(1)
     .get();

   if (usernameQuery.docs.isNotEmpty) {
    throw 'El nombre de usuario "$displayName" ya está en uso. Por favor elige otro.';
   }

   // 2. Si el usuario escribió una contraseña, la vinculamos
   if (password.isNotEmpty) {
    print('Intentando vincular contraseña...');
    await _linkPasswordToGoogleAccount(email, password);
    hasPassword = true;
   } else {
    print('No se proporcionó contraseña, se omite el vínculo.');
    hasPassword = false;
   }

   // 3. Guardar perfil en Firestore y Auth
   await _saveUserProfile(displayName, usernameLower, hasPassword);
   
   _showSuccessSnackBar('¡Perfil completado exitosamente!');
   _navigateToHome();

  } catch (e) {
   print('Error al completar perfil: $e');
   _showErrorSnackBar('Error: $e');
  } finally {
   if (mounted) {
    setState(() => _isLoading = false);
   }
  }
 }

 Future<void> _linkPasswordToGoogleAccount(String email, String password) async { // <-- CAMBIO: 'username' removido
  try {
   // Crear credencial de email/contraseña
   final AuthCredential emailCredential = EmailAuthProvider.credential(
    email: email,
    password: password,
   );

   // Vincular la credencial a la cuenta existente
   await widget.user.linkWithCredential(emailCredential);
   
   print('✅ Contraseña vinculada exitosamente a la cuenta de Google');

  } on FirebaseAuthException catch (e) {
   print('Error de Firebase al vincular: ${e.code} - ${e.message}');
   
   switch (e.code) {
    case 'provider-already-linked':
     // Esto está bien, ya tiene contraseña.
     print('Info: El usuario ya tiene una contraseña vinculada.');
     break;
     
    case 'email-already-in-use':
     // El email ya está en uso por otra cuenta
     _showEmailAlreadyExistsDialog();
     // Lanzamos el error para detener el flujo de _completeProfile
     throw 'Este email ya está en uso por otra cuenta.'; 
     
    case 'requires-recent-login':
     // Necesita reautenticación
     _showReauthenticationRequiredDialog();
     throw 'Se requiere re-autenticación. Por favor, vuelve a iniciar sesión.';
     
    default:
     throw 'No se pudo vincular la contraseña. Error: ${e.message}';
   }
  }
 }

 // ===================================================================
 // --- INICIO DE LA CORRECCIÓN CLAVE ---
 // ===================================================================

 Future<void> _saveUserProfile(String displayName, String usernameLower, bool hasPassword) async {
  
  // --- 1. ACTUALIZAR FIREBASE AUTH ---
  try {
   if (widget.user.displayName != displayName) {
    await widget.user.updateProfile(displayName: displayName);
    // Recargamos el usuario para obtener los datos frescos
    await widget.user.reload(); 
    print('✅ Perfil de FirebaseAuth actualizado con displayName: $displayName');
   }
  } catch (e) {
   print('Error al actualizar perfil de Auth: $e');
   // No detenemos el flujo, pero es bueno saberlo.
  }

  // --- 2. GUARDAR EN FIRESTORE (Como ya lo hacías) ---
  final userData = {
   'uid': widget.user.uid,
   'email': widget.user.email,
   'username': usernameLower, // El nombre en minúsculas para búsquedas
   'displayName': displayName, // El nombre con mayúsculas para mostrar
   'photoURL': widget.user.photoURL,
   'provider': 'google', // Esto deberías ajustarlo si vienes de email/pass
   'hasPassword': hasPassword,
   'profileCompleted': true,
   'createdAt': FieldValue.serverTimestamp(),
   'updatedAt': FieldValue.serverTimestamp(),
  };

  await _firestore.collection('users').doc(widget.user.uid).set(
   userData,
   SetOptions(merge: true),
  );
  
  print('✅ Perfil guardado en Firestore');
 }

 // ===================================================================
 // --- FIN DE LA CORRECCIÓN CLAVE ---
 // ===================================================================

 void _showEmailAlreadyExistsDialog() {
  showDialog(
   context: context,
   builder: (context) => AlertDialog(
    title: const Text('Cuenta Existente'),
    content: const Text(
     'Ya existe una cuenta de email/contraseña con este correo electrónico.\n\n'
     'Puedes:\n'
     '• Usar Google Sign-In para acceder (recomendado)\n'
     '• Usar "Olvidé mi contraseña" si quieres recuperar la cuenta existente\n'
     '• Contactar soporte si necesitas ayuda',
    ),
    actions: [
     TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Usar Google Sign-In'),
     ),
    ],
   ),
  );
 }

 void _showReauthenticationRequiredDialog() {
  showDialog(
   context: context,
   builder: (context) => AlertDialog(
    title: const Text('Reautenticación Requerida'),
    content: const Text(
     'Por seguridad, necesitas volver a iniciar sesión con Google para vincular una contraseña.\n\n'
     'Puedes completar tu perfil sin contraseña por ahora y agregarla después desde Configuración.',
    ),
    actions: [
     TextButton(
      onPressed: () {
       Navigator.pop(context);
       _skipForNow();
      },
      child: const Text('Completar sin contraseña'),
     ),
     TextButton(
      onPressed: () {
       Navigator.pop(context);
       _signOutAndRetry();
      },
      child: const Text('Reiniciar sesión'),
     ),
    ],
   ),
  );
 }

 void _signOutAndRetry() async {
  try {
   await _auth.signOut();
   // --- CAMBIO: Navegar a MainShell (que maneja si está logueado o no) ---
   Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => MainShell()), // MainShell redirigirá a Login
    (Route<dynamic> route) => false,
   );
  } catch (e) {
   print('Error al cerrar sesión: $e');
  }
 }

 // --- CAMBIO: _skipForNow ahora es async y actualiza el Auth Profile ---
 void _skipForNow() async {
  setState(() => _isLoading = true);
  try {
   final String displayName = _usernameController.text.trim();
   final String usernameLower = displayName.toLowerCase();
   
   // --- AÑADIDO: Actualizar Auth Profile ---
   if (displayName.isNotEmpty && widget.user.displayName != displayName) {
    await widget.user.updateProfile(displayName: displayName);
    await widget.user.reload();
    print('✅ Perfil de FirebaseAuth actualizado (skip)');
   }

   // Guardar información básica sin contraseña
   final userData = {
    'uid': widget.user.uid,
    'email': widget.user.email,
    'username': usernameLower.isNotEmpty ? usernameLower : widget.user.email?.split('@').first ?? 'usuario',
    'displayName': displayName.isNotEmpty ? displayName : widget.user.email,
    'photoURL': widget.user.photoURL,
    'provider': 'google', // Ajustar si es necesario
    'hasPassword': false,
    'profileCompleted': true, // Marcamos como completo
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
   };

   await _firestore.collection('users').doc(widget.user.uid).set(
    userData,
    SetOptions(merge: true),
   );

   _showInfoSnackBar('Perfil completado. Puedes agregar una contraseña después.');
   _navigateToHome();
  } catch (e) {
   print('Error en skip: $e');
   _showErrorSnackBar('Error al guardar: $e');
   _navigateToHome(); // Aún así navega
  } finally {
   if (mounted) {
    setState(() => _isLoading = false);
   }
  }
 }

 void _navigateToHome() {
  // --- CAMBIO: AÑADIDO 'addPostFrameCallback' ---
  WidgetsBinding.instance.addPostFrameCallback((_) {
   if(mounted) {
    Navigator.of(context).pushAndRemoveUntil(
     MaterialPageRoute(builder: (context) => MainShell()),
     (Route<dynamic> route) => false,
    );
   }
  });
 }

 void _showErrorSnackBar(String message) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    content: Text(message),
    backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,
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

 void _showInfoSnackBar(String message) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    content: Text(message),
    backgroundColor: Colors.blue,
    behavior: SnackBarBehavior.floating,
   ),
  );
 }

 void _showExitDialog() {
  showDialog(
   context: context,
   builder: (context) => AlertDialog(
    title: const Text('¿Salir sin completar?'),
    content: const Text('Puedes completar tu perfil más tarde desde la configuración.'),
    actions: [
     TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancelar'),
     ),
     TextButton(
      onPressed: () {
       Navigator.pop(context);
       _skipForNow();
      },
      child: const Text('Salir'),
     ),
    ],
   ),
  );
 }

 @override
 void dispose() {
  _usernameController.dispose();
  _passwordController.dispose();
  _confirmPasswordController.dispose();
super.dispose();
 }
}