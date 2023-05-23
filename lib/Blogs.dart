import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';

import 'BlogPage.dart';

final _firestore = FirebaseFirestore.instance;

class BlogsPage extends StatefulWidget {
  @override
  _BlogsPageState createState() => _BlogsPageState();
}

class _BlogsPageState extends State<BlogsPage> {
  final Stream<QuerySnapshot> _blogsStream =
  _firestore.collection('Blog').snapshots();
  final _instructors = ValueNotifier<Map<String, DocumentSnapshot>>({});
  bool _isLoading = true;
  final _filteredBlogs = ValueNotifier<List<DocumentSnapshot>>([]);

  @override
  void initState() {
    super.initState();
    _loadImages();
    _fetchInstructors();
  }

  Future<void> _loadImages() async {
    await Future.delayed(Duration(seconds: 2)); // Simulating image loading delay
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchInstructors() async {
    final instructorDocs = await _firestore.collection('Instructor').get();
    _instructors.value = Map.fromEntries(
      instructorDocs.docs.map((doc) => MapEntry(doc.id, doc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _blogsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final blogs = snapshot.data!.docs;
        _filteredBlogs.value = blogs;

        return ValueListenableBuilder<Map<String, DocumentSnapshot>>(
          valueListenable: _instructors,
          builder: (BuildContext context, Map<String, DocumentSnapshot> instructors, Widget? child) {
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: (value) {
                      _filteredBlogs.value = blogs.where((blog) {
                        final blogData = blog.data() as Map<String, dynamic>;
                        final blogTitle = blogData['Title'] as String;
                        return blogTitle.toLowerCase().contains(value.toLowerCase());
                      }).toList();
                    },
                    decoration: InputDecoration(
                      labelText: 'Search blogs',
                      hintText: 'Search blogs',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<List<DocumentSnapshot>>(
                    valueListenable: _filteredBlogs,
                    builder: (BuildContext context, List<DocumentSnapshot> blogs, Widget? child) {
                      return AnimationLimiter(
                        child: ListView.builder(
                          itemCount: blogs.length,
                          itemBuilder: (BuildContext context, int index) {
                            final blog = blogs[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 500),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _isLoading
                                      ? _buildLoadingCard()
                                      : BlogCard(blog: blog, instructor: instructors[blog.get('AuthorId')]),
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

class BlogCard extends StatefulWidget {
  final DocumentSnapshot blog;
  final DocumentSnapshot? instructor;

  BlogCard({required this.blog, this.instructor});

  @override
  _BlogCardState createState() => _BlogCardState();
}

class _BlogCardState extends State<BlogCard> {

  @override
  Widget build(BuildContext context) {
    String instructorName = widget.instructor?.get('displayName') ?? 'Unknown';
    String blogTitle = widget.blog.get('Title') as String? ?? 'Unknown Title';
    String imageUrl = widget.blog.get('img') as String? ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogPage(blogId: widget.blog.id),
          ),
        );
      },
      child: Card(
        elevation: 5,
        margin: EdgeInsets.all(10),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                blogTitle,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 10.0),
              CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => _buildLoadingImage(),
                errorWidget: (context, url, error) => Icon(Icons.error),
                height: 200,
                width: 500,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 10.0),
              Text(
                'Instructor: $instructorName',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildLoadingImage() {
    return Container(
      height: 150,
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
