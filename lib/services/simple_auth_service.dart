import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SimpleAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentAdminId;
  Map<String, dynamic>? _currentAdminData;

  String? get currentAdminId => _currentAdminId;
  Map<String, dynamic>? get currentAdminData => _currentAdminData;
  bool get isLoggedIn => _currentAdminId != null;

  // Simple password hashing
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register admin and automatically log them in
  Future<bool> registerAdmin(String email, String password, String name) async {
    try {
      // Check if admin already exists
      QuerySnapshot existing = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .get();
      
      if (existing.docs.isNotEmpty) {
        return false; // Admin already exists
      }

      // Create new admin
      DocumentReference adminRef = await _firestore.collection('admins').add({
        'email': email,
        'password': _hashPassword(password),
        'name': name,
        'createdAt': Timestamp.now(),
        'isActive': true,
      });

      // Update with the document ID
      await adminRef.update({'id': adminRef.id});

      // Automatically log in the newly registered admin
      DocumentSnapshot adminDoc = await adminRef.get();
      _currentAdminId = adminDoc.id;
      _currentAdminData = adminDoc.data() as Map<String, dynamic>;

      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  // Login admin
  Future<bool> loginAdmin(String email, String password) async {
    try {
      QuerySnapshot result = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: _hashPassword(password))
          .get();

      if (result.docs.isNotEmpty) {
        DocumentSnapshot adminDoc = result.docs.first;
        _currentAdminId = adminDoc.id;
        _currentAdminData = adminDoc.data() as Map<String, dynamic>;
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Logout
  void logout() {
    _currentAdminId = null;
    _currentAdminData = null;
  }
} 