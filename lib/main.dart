import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'Blogs.dart';
import 'Courses.dart';
import 'EventsPage.dart';
import 'Home.dart';
import 'Login/Login.dart';
import 'MyCourses.dart';
import 'Profile.dart';
import 'Provider/DataCacheProvider.dart';
import 'Messages.dart'; // Add this import statement
import 'SplashPage.dart'; // Import the SplashPage file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => DataCacheProvider(),
      child: MyApp(),
    ),
  );
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
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

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

  Future<void> loginUser(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!_isDisposed && mounted) {
        setState(() {
          print('Sign in successful!');
          checkUserLoginStatus();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage(logoutUser: logoutUser)),
                (route) => false, // Remove all previous routes from the stack
          );
        });
      }
    } catch (e) {
      print('Login failed: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Login Failed'),
            content: Text('Invalid email or password. Please try again.'),
            actions: <Widget>[
              ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void logoutUser() async {
    await FirebaseAuth.instance.signOut();
    checkUserLoginStatus();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false, // Remove all previous routes from the stack
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return LoginPage();
    } else {
      return FutureBuilder(
        future: Future.delayed(Duration(seconds: 3)), // Add a delay to show the SplashPage for 3 seconds
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return MyHomePage(logoutUser: logoutUser);
          } else {
            return SplashPage(); // Show the SplashPage while loading
          }
        },
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
  User? _currentUser = FirebaseAuth.instance.currentUser;


  final List<Widget> _pageOptions = [
    Home(),
    MycoursesPage(),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Messages(userId: _currentUser?.uid ?? ''),
                ),
              );
            },
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
