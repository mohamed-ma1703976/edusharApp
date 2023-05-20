import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Messages extends StatefulWidget {
  final String userId;

  Messages({required this.userId});

  @override
  _MessagesState createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  late User? _currentUser;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream;
  List<dynamic> _messages = [];
  bool _open = false;
  String _replyMessage = '';
  String? _selectedMessageId;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchStudents();
    _subscribeToMessages();
  }

  Future<void> _fetchStudents() async {
    final studentCollection = FirebaseFirestore.instance.collection('Student');
    final studentSnapshot = await studentCollection.get();
    final studentList = studentSnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'attributes': doc.data(),
      };
    }).toList();

    setState(() {
      _students = studentList;
    });
  }

  void _subscribeToMessages() {
    final messagesCollection = FirebaseFirestore.instance.collection('Message');
    final messagesQuery = messagesCollection.where('toId', isEqualTo: widget.userId);
    _messagesStream = messagesQuery.snapshots();
  }

  Future<void> _handleSendReply() async {
    try {
      final messageRef = FirebaseFirestore.instance.collection('Message').doc(_selectedMessageId);
      final messageDoc = await messageRef.get();

      // Get the previous replies
      final previousReplies = messageDoc.data()?['replays'] ?? [];

      // Merge the previous replies with the new reply
      final newReplies = [...previousReplies, _replyMessage];

      // Update the message document with the new replies
      await messageRef.update({'replays': newReplies});

      // Clear the reply input and close the dialog
      setState(() {
        _replyMessage = '';
        _open = false;
      });
      _reloadPage();
    } catch (err) {
      print(err);
    }
  }

  Future<void> _reloadPage() async {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => Messages(userId: widget.userId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _messagesStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final messagesList = snapshot.data!.docs.map((doc) {
                return {
                  'id': doc.id,
                  'data': doc.data(),
                };
              }).toList();

              _messages = messagesList;

              return _messages.length > 0
                  ? ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isEven = index % 2 == 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isEven ? Colors.teal : Colors.grey,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: const EdgeInsets.all(8.0),
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'From Instructor: ${message['data']['fromName']}',
                                      style: TextStyle(fontSize: 14.0, color: Colors.white),
                                    ),
                                    Text(
                                      message['data']['message'],
                                      style: TextStyle(fontSize: 16.0, color: Colors.white),
                                    ),
                                    if (message['data']['InstructorReplays'] != null)
                                      ...message['data']['InstructorReplays'].map<Widget>((m) {
                                        return Text(
                                          m,
                                          style: TextStyle(fontSize: 16.0, color: Colors.white),
                                        );
                                      }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (message['data']['replays'] != null)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isEven ? Colors.grey : Colors.teal,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Replies from: ${_students.firstWhere((s) => s['id'] == widget.userId)['attributes']['displayName']}',
                                        style: TextStyle(fontSize: 14.0, color: Colors.white),
                                      ),
                                      Column(
                                        children: message['data']['replays'].map<Widget>((reply) {
                                          return Text(
                                            reply,
                                            style: TextStyle(fontSize: 16.0, color: Colors.white),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              )
                  : Center(
                child: Text('No messages found.', style: TextStyle(fontSize: 16.0, color: Colors.black)),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}', style: TextStyle(fontSize: 16.0, color: Colors.black)),
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
      bottomNavigationBar: _open
          ? BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Reply Here ...',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 4,
                  onChanged: (value) {
                    setState(() {
                      _replyMessage = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 8.0),
              ElevatedButton(
                onPressed: _replyMessage.isNotEmpty ? _handleSendReply : null,
                child: Text('Send'),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }
}
