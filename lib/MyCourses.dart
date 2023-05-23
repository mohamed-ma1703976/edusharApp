import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class MycoursesPage extends StatefulWidget {
  @override
  _MycoursesPageState createState() => _MycoursesPageState();
}

class _MycoursesPageState extends State<MycoursesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String userId;
  List<dynamic> courses = [];
  List<dynamic> students = [];

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    fetchStudents();
    fetchCourses();
  }
  Future<void> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    }
  }

  Future<void> fetchStudents() async {
    final studentCollection = FirebaseFirestore.instance.collection('Student');
    final studentSnapshot = await studentCollection.get();
    final studentList = studentSnapshot.docs.map((doc) => doc.data()).toList();
    setState(() {
      students = studentList;
    });
    fetchCourses(); // Call fetchCourses after setting students in the state
  }

  Future<void> fetchCourses() async {
    final coursesCollection = FirebaseFirestore.instance.collection('Course');
    final courseSnapshot = await coursesCollection.get();
    final coursesList = courseSnapshot.docs.map((doc) => doc.data()).toList();
    final currentStudentCourses = getCurrentStudentCourses();
    final registeredCourses = coursesList.where((course) => currentStudentCourses.contains(course['id'])).toList();
    setState(() {
      courses = registeredCourses;
    });
  }


  List<dynamic> getCurrentStudentCourses() {
    final currentStudent = students.firstWhere(
          (s) => s['id'] == userId,
      orElse: () => Map<String, dynamic>.from({}),
    );
    if (currentStudent.isNotEmpty) {
      return currentStudent['registerdcourses'];
    }
    return [];
  }


  List<dynamic> getRegisteredCoursesByStudent() {
    final currentStudentCourses = getCurrentStudentCourses();
    return courses.where((course) => currentStudentCourses.contains(course['id'])).toList();
  }


  Future<void> handleDropCourse(String courseId) async {
    final updatedCourses = getCurrentStudentCourses()..remove(courseId);
    final studentRef = FirebaseFirestore.instance.collection('Student').doc(userId);
    await studentRef.update({
      'attributes.registerdcourses': updatedCourses,
    });
    fetchStudents();
  }


  @override
  Widget build(BuildContext context) {
    final registeredCoursesByStudent = getRegisteredCoursesByStudent();

    return Scaffold(
      body: ListView.builder(
        itemCount: registeredCoursesByStudent.length,
        itemBuilder: (BuildContext context, int index) {
          final course = registeredCoursesByStudent[index];
          return Card(
            child: ListTile(
              title: Text(course['CourseTitle']),
              subtitle: Text(course['InstructorName']),
              trailing: ElevatedButton(
                onPressed: () => handleDropCourse(course['id']),
                child: Text('Drop course'),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoursePage(courseName: course['CourseTitle']),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class CoursePage extends StatelessWidget {
  final String courseName;

  CoursePage({required this.courseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(courseName),
      ),
      body: Center(
        child: Text('Course Details'),
      ),
    );
  }
}
