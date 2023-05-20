import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class UpdateProfile extends StatefulWidget {
  @override
  _UpdateProfileState createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final _formKey = GlobalKey<FormBuilderState>();
  File? _profilePicture;
  File? _coverPicture;
  final picker = ImagePicker();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    Future<Map<String, dynamic>> _loadUserData() async {
      DocumentSnapshot docSnap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return docSnap.data() as Map<String, dynamic>;
    }

    Future _pickProfilePicture() async {
      final pickedFile = await picker.getImage(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          _profilePicture = File(pickedFile.path);
        }
      });
    }

    Future _pickCoverPicture() async {
      final pickedFile = await picker.getImage(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          _coverPicture = File(pickedFile.path);
        }
      });
    }

    Future<String?> _uploadImage(File image, String path) async {
      if (image != null) {
        final ref = FirebaseStorage.instance.ref(path);
        await ref.putFile(image);
        return await ref.getDownloadURL();
      } else {
        return null;
      }
    }

    Future<void> _updateProfile() async {
      setState(() {
        _isLoading = true;
      });

      final values = _formKey.currentState!.value;
      final displayName = values['displayName'];
      final title = values['title'];
      final bio = values['bio'];

      final profilePicUrl = await _uploadImage(_profilePicture!, 'users/$userId/profilePicture');
      final coverPicUrl = await _uploadImage(_coverPicture!, 'users/$userId/coverPicture');

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'displayName': displayName,
        'title': title,
        'bio': bio,
        'profilePicture': profilePicUrl,
        'coverPicture': coverPicUrl,
      });

      setState(() {
        _isLoading = false;
      });
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadUserData(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data as Map<String, dynamic>;

        return Scaffold(
          appBar: AppBar(title: Text('Update Profile')),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: FormBuilder(
                key: _formKey,
                initialValue: userData,
                child: Column(
                  children: [
                    GestureDetector(
                      child: Image.network(userData['coverPicture']),
                      onTap: _pickCoverPicture,
                    ),
                    GestureDetector(
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(userData['profilePicture']),
                      ),
                      onTap: _pickProfilePicture,
                    ),
                    FormBuilderTextField(
                      name: 'displayName',
                      decoration: InputDecoration(labelText: 'Display Name'),
                    ),
                    FormBuilderTextField(
                      name: 'title',
                      decoration: InputDecoration(labelText: 'Title'),
                    ),
                    FormBuilderTextField(
                      name: 'bio',
                      decoration: InputDecoration(labelText: 'Bio'),
                    ),
                    SizedBox(height: 10),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                      child: Text('Update Profile'),
                      onPressed: _updateProfile,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
