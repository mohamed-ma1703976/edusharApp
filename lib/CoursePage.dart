import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class CoursePage extends StatefulWidget {
  final String courseId;

  CoursePage({required this.courseId});

  @override
  _CoursePageState createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool loading = true;
  bool enrolled = false;
  late User user;

  late Map<String, dynamic> courseData;

  @override
  void initState() {
    super.initState();

    fetchCourseData();
    fetchUserData();
  }

  void fetchCourseData() async {
    DocumentSnapshot courseSnapshot = await _firestore.collection('Course').doc(widget.courseId).get();
    courseData = courseSnapshot.data() as Map<String, dynamic>;
    setState(() {
      loading = false;
    });
  }

  void fetchUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userSnapshot = await _firestore.collection('Student').doc(currentUser.uid).get();
      Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

      enrolled = userData['registeredcourses'].contains(widget.courseId);

      setState(() {
        user = currentUser;
      });
    }
  }

  void enrollCourse() async {
    await _firestore.collection('Student').doc(user.uid).update({
      'registeredcourses': FieldValue.arrayUnion([widget.courseId])
    });

    setState(() {
      enrolled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SpinKitFadingCube(
        color: Colors.greenAccent,
        size: 50.0,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(courseData['CourseTitle']),
        backgroundColor: Colors.greenAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            CachedNetworkImage(
              imageUrl: courseData['fileUrl'],
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
            SizedBox(height: 16),
            Text(
              courseData['CourseTitle'],
              style: GoogleFonts.openSans(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Instructor: ${courseData['InstructorName']}',
              style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              courseData['CourseDescription'],
              style: GoogleFonts.openSans(fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: enrolled ? null : enrollCourse,
              child: Text(enrolled ? 'Registered' : 'Enroll'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            ),
          ],
        ),
      ),
    );
  }
}
