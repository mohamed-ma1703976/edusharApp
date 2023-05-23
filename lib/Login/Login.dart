import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loginError = false;

  Future<void> _signInWithEmailAndPassword() async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final String userId = userCredential.user!.uid;

      final DocumentSnapshot studentDoc = await FirebaseFirestore.instance.collection('Student').doc(userId).get();
      final DocumentSnapshot instructorDoc = await FirebaseFirestore.instance.collection('Instructor').doc(userId).get();
      final DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('Admin').doc(userId).get();

      String role;
      DocumentSnapshot userDoc;

      if (studentDoc.exists) {
        userDoc = studentDoc;
        role = 'student';
      } else if (instructorDoc.exists) {
        userDoc = instructorDoc;
        role = 'instructor';
      } else if (adminDoc.exists) {
        userDoc = adminDoc;
        role = 'admin';
      } else {
        throw Exception('User not found in any role collection.');
      }

      bool profileComplete = true;

      if (role == 'student' || role == 'instructor') {
        final userData = userDoc.data() as Map<String, dynamic>;
        profileComplete = userData['displayName'] != null && userData['bio'] != null && userData['title'] != null;
      }

      if (!profileComplete) {
        // TODO: Replace this with your actual route
        Navigator.pushNamed(context, '/createProfile');
      } else {
        // TODO: Replace this with your actual route
        Navigator.pushNamed(context, '/$role');
      }

      setState(() {
        _loginError = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _loginError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'EduShare',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 50),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signInWithEmailAndPassword,
                child: Text('Login'),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/signup/register');
                },
                child: Text(
                  'Don\'t have an account? Register',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
