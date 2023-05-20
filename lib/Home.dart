import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Stream<QuerySnapshot> _coursesStream =
  FirebaseFirestore.instance.collection('Course').snapshots();
  final Stream<QuerySnapshot> _blogsStream =
  FirebaseFirestore.instance.collection('Blog').snapshots();
  final Stream<QuerySnapshot> _eventsStream =
  FirebaseFirestore.instance.collection('Events').snapshots();

  final List<Widget> _carouselItems = [];

  @override
  void initState() {
    super.initState();
    _carouselItems.addAll([
      'assets/Pencil12062003.jpg',
      'assets/Kid120920023.jpg',
      'assets/EducationKidillustrator.png',
    ].map((image) => Builder(
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.symmetric(horizontal: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              image,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Carousel
              CarouselSlider(
                options: CarouselOptions(
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  enlargeCenterPage: true,
                ),
                items: _carouselItems,
              ),

              const SizedBox(height: 16),

              // Latest Courses
              const Text(
                'Latest Courses',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildStreamBuilder(
                _coursesStream,
                'CourseTitle',
                'InstructorName',
                'fileUrl',
              ),

              const SizedBox(height: 16),

              // Latest Blogs
              const Text(
                'Latest Blogs',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildStreamBuilder(
                _blogsStream,
                'Title',
                'AuthorId',
                'img',
                prefixSubtitle: 'By: ',
              ),

              // Latest Events
              const Text(
                'Latest Events',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildStreamBuilder(
                _eventsStream,
                'title',
                'start',
                'coverImage',
                prefixSubtitle: 'Start: ',
                postfixSubtitle: ' - End: ',
                subtitleFieldName2: 'end',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamBuilder(
      Stream<QuerySnapshot> stream,
      String titleFieldName,
      String subtitleFieldName,
      String imgFieldName, {
        String prefixSubtitle = '',
        String postfixSubtitle = '',
        String? subtitleFieldName2,
      }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final item = snapshot.data!.docs[index];
              final data = item.data() as Map<String, dynamic>;

              return Container(
                width: 150,
                child: Card(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CachedNetworkImage(
                          imageUrl: data[imgFieldName],
                          placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                          width: double.infinity,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      ListTile(
                        title: Text(
                          data[titleFieldName],
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          prefixSubtitle +
                              data[subtitleFieldName] +
                              (subtitleFieldName2 != null
                                  ? postfixSubtitle + data[subtitleFieldName2]
                                  : ''),
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
