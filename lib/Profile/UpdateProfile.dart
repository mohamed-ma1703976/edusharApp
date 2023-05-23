import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UpdateProfile extends StatefulWidget {
  @override
  _UpdateProfileState createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  TextEditingController displayNameController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController bioController = TextEditingController();

  File? profilePicture;
  File? coverPicture;

  String? profilePicturePreview;
  String? coverPicturePreview;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    // Fetch user data and set the initial state
  }

  void handleChange(String name, String value) {
    setState(() {
      if (name == 'displayName') {
        displayNameController.text = value;
      } else if (name == 'title') {
        titleController.text = value;
      } else if (name == 'bio') {
        bioController.text = value;
      }
    });
  }

  Future<void> handleProfilePictureChange() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profilePicture = File(pickedFile.path);
        profilePicturePreview = pickedFile.path;
      });
    }
  }

  Future<void> handleCoverPictureChange() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        coverPicture = File(pickedFile.path);
        coverPicturePreview = pickedFile.path;
      });
    }
  }

  Future<void> handleUpdateProfile() async {
    // Handle updating the profile
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Update Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16),
                    Form(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: handleCoverPictureChange,
                            child: Image.file(
                              coverPicture ?? File(''), // Use a placeholder file when coverPicture is null
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                            ),
                          ),
                          SizedBox(height: 16),
                          GestureDetector(
                            onTap: handleProfilePictureChange,
                            child: CircleAvatar(
                              backgroundImage: profilePicture != null
                                  ? FileImage(profilePicture!)
                                  : null,
                              radius: 70,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: displayNameController,
                            decoration: InputDecoration(
                              labelText: 'Display Name',
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: titleController,
                            decoration: InputDecoration(
                              labelText: 'Title',
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: bioController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Bio',
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: handleUpdateProfile,
                            child: Text('Update Profile'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
