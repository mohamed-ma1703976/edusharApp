import 'dart:io';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Blogs.dart';
import 'Courses.dart';
import 'EventsPage.dart';
import 'Home.dart';
import 'Login/Login.dart';
import 'Messages.dart';
import 'MyCourses.dart';
import 'Profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduShare',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  User? _user;

  @override
  void initState() {
    super.initState();
    checkUserLoginStatus();
  }

  void checkUserLoginStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _user = user;
    });
  }

  void loginUser(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Sign in successful!');
      checkUserLoginStatus();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage(logoutUser: logoutUser)),
      );
    } catch (e) {
      print('Login failed: $e');
    }
  }

  void logoutUser() async {
    await FirebaseAuth.instance.signOut();
    checkUserLoginStatus();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage(logoutUser: logoutUser)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return LoginPage(
        loginUser: loginUser,
      );
    } else {
      return MyHomePage(
        logoutUser: logoutUser,
      );
    }
  }
}
class MyHomePage extends StatefulWidget {
  final VoidCallback logoutUser;

  MyHomePage({required this.logoutUser, Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _page = 0;
  GlobalKey _bottomNavigationKey = GlobalKey();
  void navigateToMessagesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Messages(userId: FirebaseAuth.instance.currentUser!.uid)),
    );
  }
  final List<Widget> _pageOptions = [
    Home(),
    MyCourses(),
    CoursesPage(),
    BlogsPage(),
    EventsPage(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        backgroundColor: Colors.white,
        title: RichText(
        text: TextSpan(
        text: 'Edu',
        style: TextStyle(color: Colors.black),
    children: <TextSpan>[
    TextSpan(text: 'Share', style: TextStyle(color: Colors.greenAccent)),
    ],
    ),
    ),
    actions: <Widget>[
      IconButton(
        icon: Icon(Icons.message, color: Colors.black),
        onPressed: navigateToMessagesPage,
      ),

      IconButton(
        icon: Icon(Icons.logout, color: Colors.black),
        onPressed: () => widget.logoutUser(),
      ),

    ],
    ),
    body: _pageOptions[_page],
    bottomNavigationBar: CurvedNavigationBar(
    key: _bottomNavigationKey,
    index: 0,
    height: 50.0,
    items: <Widget>[
    Icon(Icons.home, size: 30),
    Icon(Icons.book, size: 30),
    Icon(Icons.school, size: 30),
    Icon(Icons.article, size: 30),
    Icon(Icons.event, size: 30),
    Icon(Icons.person, size: 30),
    ],
    color: Colors.white,
      buttonBackgroundColor: Colors.white,
      backgroundColor: Colors.greenAccent,
      animationCurve: Curves.easeInOut,
      animationDuration: Duration(milliseconds: 600),
      onTap: (index) {
        setState(() {
          _page = index;
        });
      },
    ),
    );
  }
}
