import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
class CreateProfile extends StatefulWidget {
  @override
  _CreateProfileState createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  File? _profilePicture;
  File? _coverPicture;
  bool _isLoading = false;

  // Custom validator
  String? Function(String?) _validateNotEmpty = (value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }
    return null;
  };
  Future<void> _pickImage(ImageSource source, bool isProfilePicture) async {
    XFile? selected = await _picker.pickImage(
      source: source,
    );

    if (selected != null) {
      isProfilePicture
          ? _profilePicture = File(selected.path)
          : _coverPicture = File(selected.path);
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    final userId = _auth.currentUser!.uid;
    final form = _formKey.currentState;

    if (form!.validate()) {
      setState(() => _isLoading = true);

      form.save();
      final data = form.value;
      final displayName = data['displayName'];
      final bio = data['bio'];
      final title = data['title'];

      final profilePictureUrl =
      await uploadImageToFirebase('profilePictures/$userId', _profilePicture);
      final coverPictureUrl =
      await uploadImageToFirebase('coverPictures/$userId', _coverPicture);

      await _db.collection('users').doc(userId).set({
        'displayName': displayName,
        'bio': bio,
        'title': title,
        if (profilePictureUrl != null) 'profilePicture': profilePictureUrl,
        if (coverPictureUrl != null) 'coverPicture': coverPictureUrl,
      });

      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<String?> uploadImageToFirebase(String path, File? image) async {
    if (image == null) return null;
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putFile(image);
    return ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery, false),
                child: CircleAvatar(
                  radius: 100,
                  backgroundImage: _coverPicture != null
                      ? FileImage(_coverPicture!)
                      : null,
                  child: _coverPicture == null
                      ? const Icon(Icons.camera_alt, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery, true),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profilePicture != null
                      ? FileImage(_profilePicture!)
                      : null,
                  child: _profilePicture == null
                      ? const Icon(Icons.camera_alt, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              FormBuilder(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    FormBuilderTextField(
                      name: 'displayName',
                      decoration: const InputDecoration(labelText: 'Display Name'),
                      validator: _validateNotEmpty,
                    ),
                    const SizedBox(height: 10),
                    FormBuilderTextField(
                      name: 'bio',
                      decoration: const InputDecoration(labelText: 'Bio'),
                      validator: _validateNotEmpty,
                    ),
                    const SizedBox(height: 10),
                    FormBuilderTextField(
                      name: 'title',
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: _validateNotEmpty,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                child: const Text('Save'),
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}