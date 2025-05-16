import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';

import '../login/login_page.dart';

class ConfiguracionPage extends StatefulWidget {
  @override
  _ConfiguracionPageState createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  final List<String> _defaultProfileImages = [
    'images/Perfil1.jpg',
    'images/Perfil2.jpg',
    'images/Perfil3.jpg',
  ];

  final ImagePicker _picker = ImagePicker();
  String? _selectedImage;
  bool _isLoading = false;
  String _userName = '';
  String _email = '';

  String _appVersion = '1.0.0';

  TextEditingController _userNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadUserData();
  }

  void _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedImage = prefs.getString('profile_image') ?? 'images/Perfil1.jpg';
    });
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      setState(() {
        _userName = doc['nombre'] ?? prefs.getString('user_name') ?? 'Nombre no disponible';
        _email = user.email ?? 'Correo no disponible';

        _userNameController.text = _userName;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);

    // Permisos
    final permission = source == ImageSource.camera
        ? await Permission.camera.request()
        : await Permission.photos.request();

    if (!permission.isGranted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permiso denegado para acceder a la ${source == ImageSource.camera ? 'cámara' : 'galería'}")),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      final File file = File(image.path);
      final String targetPath = '${file.parent.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedImage = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
      );

      if (compressedImage != null) {
        await prefs.setString('profile_image', compressedImage.path);
        setState(() {
          _selectedImage = compressedImage.path;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al comprimir la imagen.")),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _showImageSelectorDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Seleccionar foto de perfil"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue),
                title: Text("Tomar foto"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_album, color: Colors.blue),
                title: Text("Galería"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const Divider(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "Imágenes predeterminadas:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Wrap(
                spacing: 10,
                children: _defaultProfileImages.map((path) {
                  return GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('profile_image', path);
                      setState(() {
                        _selectedImage = path;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedImage == path ? Colors.blue : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(radius: 30, backgroundImage: AssetImage(path)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);

    if (key == 'user_name') {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .update({'nombre': value});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al actualizar el nombre: $e")),
          );
        }
      }
    }
  }

  void _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Correo para cambiar contraseña enviado.")),
      );
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<bool> _reauthenticateUser(User user) async {
    // Mostrar diálogo para que el usuario ingrese su contraseña
    final TextEditingController passwordController = TextEditingController();
    bool reauthSuccess = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Re-autenticación requerida"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Por seguridad, ingresa tu contraseña para continuar."),
            SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              reauthSuccess = false;
            },
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              final cred = EmailAuthProvider.credential(
                  email: user.email!, password: passwordController.text.trim());
              try {
                await user.reauthenticateWithCredential(cred);
                reauthSuccess = true;
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Contraseña incorrecta o error: $e")),
                );
              }
            },
            child: Text("Confirmar"),
          ),
        ],
      ),
    );

    return reauthSuccess;
  }

  void _deleteAccount() async {
    bool confirmDelete = await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("¿Estás seguro de que quieres eliminar tu cuenta?"),
            content: Text("Esta acción no se puede deshacer."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancelar")),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Eliminar", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDelete) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No hay usuario autenticado.")),
      );
      return;
    }

    try {
      // Primero eliminar el documento en Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).delete();

      // Intentar eliminar la cuenta en Firebase Auth
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cuenta eliminada con éxito.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Necesita re-autenticación
        bool reAuthSuccess = await _reauthenticateUser(user);
        if (reAuthSuccess) {
          // Si la re-autenticación fue exitosa, volver a intentar eliminar
          _deleteAccount();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No se pudo re-autenticar al usuario.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar cuenta: ${e.message}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error inesperado: $e")),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.blue.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) => _saveChanges(key, value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración de Perfil'),
        backgroundColor: Color(0xFF1976D2),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImageSelectorDialog,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _isLoading
                        ? null
                        : (_selectedImage?.startsWith('images/') ?? false
                            ? AssetImage(_selectedImage!)
                            : (File(_selectedImage!).existsSync()
                                ? FileImage(File(_selectedImage!))
                                : null)) as ImageProvider?,
                  ),
                  if (_isLoading)
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              icon: Icon(Icons.photo_camera),
              label: Text("Cambiar foto de perfil"),
              onPressed: _showImageSelectorDialog,
            ),
            const SizedBox(height: 20),
            _buildTextField('Nombre', _userNameController, 'user_name'),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  children: [
                    TextSpan(text: 'Correo: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: _email),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.lock_outline, color: Colors.blue),
                    title: Text("Cambiar contraseña"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: _changePassword,
                  ),
                  Divider(height: 0),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.blue),
                    title: Text("Cerrar sesión"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: _logout,
                  ),
                  Divider(height: 0),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red),
                    title: Text("Eliminar cuenta", style: TextStyle(color: Colors.red)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.red),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text("Versión $_appVersion", style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
