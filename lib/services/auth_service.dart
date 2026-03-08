import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SIGN UP
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty) {
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        if (cred.user != null) {
          // Update Firebase Auth Display Name
          await cred.user!.updateDisplayName(username);
          
          // Save to Firestore using 'name' to stay consistent with GameProvider
          await _firestore.collection('players').doc(cred.user!.uid).set({
            'uid': cred.user!.uid,
            'name': username,
            'email': email.trim(),
            'gamesPlayed': 0,
            'wins': 0,
            'losses': 0,
            'accuracy': 0.0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          res = "success";
        }
      } else {
        res = "Please fill all the fields!";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        res = "The password provided is too weak.";
      } else if (e.code == 'email-already-in-use') {
        res = "The account already exists for that email.";
      } else {
        res = e.message ?? "Authentication failed";
      }
    } catch (err) {
      debugPrint(err.toString());
      res = err.toString();
    }
    return res;
  }

  // LOGIN USER
  Future<String> loginUser({
    required String email,
    required String password
  }) async {
    String res = "Some error occurred";
    try {
      if (email.trim().isNotEmpty && password.trim().isNotEmpty) {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim()
        );

        if (userCredential.user != null) {
          res = "success";
        }
      } else {
        res = "Please enter email and password";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        res = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        res = "Wrong password provided for that user.";
      } else {
        res = e.message ?? "Login failed";
      }
    } catch (err) {
      debugPrint(err.toString());
      res = err.toString();
    }
    return res;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}