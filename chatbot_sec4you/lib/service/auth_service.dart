import 'package:chatbot_sec4you/auth_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? usuario;
  bool isLoading = true;

  AuthService() {
    _authCheck();
  }

  void _authCheck() {
    _auth.authStateChanges().listen((User? user) {
      usuario = user;
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> registrar(String email, String senha, String nome, String sobrenome) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      // Salva no Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(userCredential.user!.uid).set({
        'nome': nome,
        'sobrenome': sobrenome,
        'email': email,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      // Atualiza o displayName do usuário autenticado
      await userCredential.user?.updateDisplayName(nome);

      // (Opcional) Atualiza o usuário localmente
      await userCredential.user?.reload();
      usuario = _auth.currentUser;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw AuthException('A senha é muito fraca!');
      } else if (e.code == 'email-already-in-use') {
        throw AuthException('Este email já está cadastrado');
      } else {
        throw AuthException('Erro ao registrar: ${e.message}');
      }
    }
  }

  Future<void> login(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw AuthException('Email não encontrado. Cadastre-se.');
      } else if (e.code == 'wrong-password') {
        throw AuthException('Senha incorreta. Tente novamente');
      } else {
        throw AuthException('Erro ao logar: ${e.message}');
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}