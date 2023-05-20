import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';

import 'EventPage.dart';

final _firestore = FirebaseFirestore.instance;

class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final Stream<QuerySnapshot> _eventsStream =
  FirebaseFirestore.instance.collection('Events').snapshots();

  bool _isLoading = true;
  final _filteredEvents = ValueNotifier<List<DocumentSnapshot>>([]);

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
      stream: _eventsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data!.docs;
        _filteredEvents.value = events;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  _filteredEvents.value = events.where((event) {
                    final eventData = event.data() as Map<String, dynamic>;
                    final eventTitle = eventData['title'] as String;
                    return eventTitle.toLowerCase().contains(value.toLowerCase());
                  }).toList();
                },
                decoration: InputDecoration(
                  labelText: 'Search events',
                  hintText: 'Search events',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<DocumentSnapshot>>(
                valueListenable: _filteredEvents,
                builder: (BuildContext context, List<DocumentSnapshot> events, Widget? child) {
                  return AnimationLimiter(
                    child: ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (BuildContext context, int index) {
                        final event = events[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _isLoading
                                  ? _buildLoadingCard()
                                  : EventCard(event: event),
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

class EventCard extends StatefulWidget {
  final DocumentSnapshot event;

  EventCard({required this.event});

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  @override
  Widget build(BuildContext context) {
    final data = widget.event.data() as Map<String, dynamic>;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EventPage(id: widget.event.id),
          ),
        );
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                height: 150, // Reduced from 200 to 150
                width: 600,
                child: CachedNetworkImage(
                  imageUrl: data['coverImage'],
                  placeholder: (context, url) => _buildLoadingImage(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0), // Adjusted padding
              title: Text(
                data['title'],
                style: GoogleFonts.openSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Start Time: ${data['start']} - End Time: ${data['end']}',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0), // Reduced from 8.0 to 4.0
              child: Text(
                'Description: ${data['description']}',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
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
