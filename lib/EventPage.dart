import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:firebase_performance/firebase_performance.dart';

class EventPage extends StatefulWidget {
  final String id;

  EventPage({Key? key, required this.id}) : super(key: key);

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final defaultImage = 'https://i.ibb.co/RN7HqQT/Edu-Share-Logo.png';
  late Future<DocumentSnapshot> futureEvent;
  bool _isLoading = true;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    futureEvent = _db.collection('Events').doc(widget.id).get();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final studentId = _auth.currentUser?.uid;
    if (studentId != null) {
      final attendees = await _db
          .collection('Events')
          .doc(widget.id)
          .collection('Attendees')
          .doc(studentId)
          .get();
      setState(() {
        _isRegistered = attendees.exists;
      });
    }
    _isLoading = false;
  }

  Future<void> _registerForEvent() async {
    final studentId = _auth.currentUser?.uid;
    if (studentId != null) {
      await _db
          .collection('Events')
          .doc(widget.id)
          .collection('Attendees')
          .doc(studentId)
          .set({
        'registered_at': DateTime.now(),
      });
      setState(() {
        _isRegistered = true;
      });
    } else {
      print('Error: user not authenticated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
        backgroundColor: Colors.greenAccent,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: futureEvent,
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (_isLoading) {
            return SpinKitCircle(
              color: Colors.greenAccent,
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return SpinKitCircle(
              color: Colors.greenAccent,
            );
          }

          final event = snapshot.data!;
          final eventData = event.data() as Map<String, dynamic>;

          final title = eventData['title'] as String? ?? 'No title';
          final description =
              eventData['description'] as String? ?? 'No description';
          final start = eventData['start'] as String? ?? 'No start time';
          final end = eventData['end'] as String? ?? 'No end time';
          final link = eventData['link'] as String? ?? 'No event link';
          final coverImage =
              eventData['coverImage'] as String? ?? defaultImage;

          return SingleChildScrollView(
            padding: EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  imageUrl: coverImage,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 10.0),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.0),
                Text('Start Time: $start'),
                SizedBox(height: 5.0),
                Text('End Time: $end'),
                SizedBox(height: 5.0),
                Text('Event Link: $link'),
                SizedBox(height: 10.0),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
                SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: _isRegistered ? null : _registerForEvent,
                  child: Text(_isRegistered ? 'Registered' : 'Register'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),

                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
