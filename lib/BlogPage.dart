import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_performance/firebase_performance.dart';

class BlogPage extends StatelessWidget {
  final String blogId;
  BlogPage({required this.blogId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot>(
      future: firestore.collection('Blog').doc(blogId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SpinKitCircle(color: Colors.blue);
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Text('No Blog Found');
        } else {
          final blog = snapshot.data!.data() as Map<String, dynamic>;

          final instructorName = blog['InstructorName'] ?? 'Unknown';
          final blogTitle = blog['Title'];
          final blogBody = blog['Body'];
          final blogImage = blog['img'] ??
              'https://i.ibb.co/RN7HqQT/Edu-Share-Logo.png';  // Default image if 'img' field is null

          return Scaffold(
            appBar: AppBar(
              title: Text(blogTitle),
              backgroundColor: Colors.greenAccent,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: blogImage,
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            Icon(Icons.error),
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      blogTitle,
                      style: GoogleFonts.getFont('Roboto',
                          fontSize: 24,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'By: $instructorName',
                      style: GoogleFonts.getFont('Roboto',
                          fontSize: 18,
                          fontWeight: FontWeight.w500
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      blogBody,
                      style: GoogleFonts.getFont('Roboto',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
