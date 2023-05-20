import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';

import 'CoursePage.dart';

final _firestore = FirebaseFirestore.instance;

class CoursesPage extends StatefulWidget {
  @override
  _CoursesPageState createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final Stream<QuerySnapshot> _coursesStream =
  FirebaseFirestore.instance.collection('Course').snapshots();

  bool _isLoading = true;
  ValueNotifier<List<DocumentSnapshot>> _filteredCourses = ValueNotifier<List<DocumentSnapshot>>([]);

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    await Future.delayed(Duration(seconds: 2)); // Simulating image loading delay
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _coursesStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final courses = snapshot.data!.docs;
        _filteredCourses.value = courses;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  _filteredCourses.value = courses.where((course) {
                    final courseData = course.data() as Map<String, dynamic>;
                    final courseTitle = courseData['CourseTitle'] as String;                    return courseTitle.toLowerCase().contains(value.toLowerCase());
                  }).toList();
                },
                decoration: InputDecoration(
                  labelText: 'Search courses',
                  hintText: 'Search courses',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<DocumentSnapshot>>(
                valueListenable: _filteredCourses,
                builder: (BuildContext context, List<DocumentSnapshot> courses, Widget? child) {
                  return AnimationLimiter(
                    child: ListView.builder(
                      itemCount: courses.length,
                      itemBuilder: (BuildContext context, int index) {
                        final course = courses[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _isLoading
                                  ? _buildLoadingCard()
                                  : CourseCard(course: course),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      child: Container(
        height: 200,
        color: Colors.grey[300],
        child: Center(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[400]!,
            highlightColor: Colors.grey[300]!,
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class CourseCard extends StatefulWidget {
  final DocumentSnapshot course;

  CourseCard({required this.course});

  @override
  _CourseCardState createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  @override
  Widget build(BuildContext context) {
    final data = widget.course.data() as Map<String, dynamic>;
    final rates = List<Map<String, dynamic>>.from(data['rates'] as List);
    final totalRating = rates.fold<num>(0, (previousValue, element) => previousValue + element['rating']);
    final averageRating = totalRating / rates.length;

    return GestureDetector( // or InkWell
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CoursePage(courseId: widget.course.id)),
        );
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                height: 200,
                width: 600,
                child: CachedNetworkImage(
                  imageUrl: data['fileUrl'],
                  placeholder: (context, url) => _buildLoadingImage(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            ListTile(
              title: Text(
                data['CourseTitle'],
                style: GoogleFonts.openSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                data['InstructorName'],
                style: GoogleFonts.openSans(
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Rating: $averageRating',
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              data['CourseDescription'],
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[400]!,
          highlightColor: Colors.grey[300]!,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
