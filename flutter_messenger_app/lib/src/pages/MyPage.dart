import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_messenger_app/src/pages/Login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'dart:io';

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final authentication = FirebaseAuth.instance;
  User? loggedUser;

  String userName = '';
  String userEmail = '';
  bool userNameChecked = false;

  String origin_userName = '';

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  File? _image;
  final picker = ImagePicker();
  String image64String= "";

  CollectionReference CollectRef = FirebaseFirestore.instance.collection('users');

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    Loaduser();
  }

  void getCurrentUser() {
    try {
      final user = authentication.currentUser;
      if (user != null) {
        loggedUser = user;
      }
    } catch(e){
      print(e);
    }
  }

  Future<void> Loaduser() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child("UserList").child(loggedUser!.uid.toString()).child("Profile_img").get();
    final namesnapshot = await ref.child("UserList").child(loggedUser!.uid.toString()).child("Name").get();
    if (snapshot.exists) {
      setState(() {
        image64String = snapshot.value.toString();
        origin_userName = namesnapshot.value.toString();
      });
    }
  }

  Future<void> Delete_FireStore(String DocId) async{
    await CollectRef.doc(DocId).delete();
  }

  Future getImage(ImageSource imageSource) async {
    final image = await picker.pickImage(source: imageSource);
    setState(() {
      _image = File(image!.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: this.formKey,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 25.0, ),
                showProfileImage(),
                SizedBox(height: 10.0, ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FloatingActionButton.small(
                      child: Icon(Icons.add_a_photo),
                      tooltip: 'pick Image',
                      onPressed: () {
                        getImage(ImageSource.camera);
                      },
                    ),

                    FloatingActionButton.small(
                      child: Icon(Icons.wallpaper),
                      tooltip: 'pick Image',
                      onPressed: () {
                        getImage(ImageSource.gallery);
                      },
                    ),

                    FloatingActionButton.small(
                      child: Icon(Icons.add),
                      onPressed: () async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Color(0xff161619),
                              title: Text(
                                  'Do you want to change your profile image?',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                              actions: [
                                TextButton(
                                  child: Text('Save'),
                                  onPressed: () async {
                                    if (_image == null) { //not choose profile image
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Choose your profile image'),
                                            duration: Duration(seconds: 5),)
                                      );
                                      Navigator.pop(context);
                                    }
                                    else {
                                      final imageBytes = await _image!.readAsBytesSync();
                                      image64String = base64Encode(imageBytes);
                                      DatabaseReference ref = FirebaseDatabase
                                          .instance.ref("UserList");
                                      ref.child(loggedUser!.uid.toString())
                                          .update({
                                        "Profile_img": image64String,
                                      });
                                      Navigator.pop(context);
                                    }},
                                ),
                                TextButton(
                                  child: Text('No'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          });
                      },
                    ),
                  ],
                ),

                SizedBox(height: 25.0, ),
                Container(
                  child: Text(origin_userName,
                    style: TextStyle(
                      letterSpacing: 1.0,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black38,
                    ),
                  ),
                ),

                SizedBox(height: 25.0, ),
                ChangeLine(),
                SizedBox(height: 25.0, ),
                ButtonLine(),
              ]
          )
        )
      )
    );
  }

  Widget showProfileImage() {
    final Uint8List Img8List = base64Decode(image64String);
    return Container(
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.2,
        child: Container(
            child: Center(
              child: Container(
                  child: Img8List.isEmpty
                    ? Center(child: Text('No Profile Image.'))
                    : _image == null
                      ? Image.memory(Uint8List.fromList(Img8List))
                      : Image.file(File(_image!.path))))));
  }

  Widget showUserNameInput() {
    return Column(
      children: [
        SizedBox(
          width: 270,
          height: 50,
          child: TextFormField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person),
              hintText: 'Username to change',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: Color(0XFFA7BCC7)),
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
              ),
            ),
            validator: (value) {
              if (value!.isEmpty || value.length < 4) {
                userNameChecked = false;
                return 'Please enter at least 4 characters';
              }
              userNameChecked = true;
              return null;
              },
            onSaved: (value) { userName = value!; },
            onChanged: (value) { userName = value; },
          ),
        ),
      ],
    );
  }

  Widget ChangeUserNameBtn() {
    return ElevatedButton(
          style: ElevatedButton.styleFrom(
            //primary: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3.0)
            ),
            minimumSize: const Size(50, 50),
          ),
          child: Text('change', style: TextStyle(fontSize: 16)),
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              formKey.currentState!.save();

              final DatabaseReference ref = FirebaseDatabase.instance.ref("UserList");
              ref.child(loggedUser!.uid.toString()).update({
                "Name": userName,
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Username is changed!'),
                  duration: Duration(seconds: 5),)
              );
            }
          },
        );
  }

  Widget ChangeLine() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 20.0, ),
        showUserNameInput(),
        ChangeUserNameBtn(),
        SizedBox(width: 5.0, ),
      ],
    );
  }

  Widget ChangePasswordBtn() {
      return InkWell(
          child: Text('Change Password',
            style: TextStyle(
              letterSpacing: 1.0,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black45,
              decoration: TextDecoration.underline,
            ),
          ),
          onTap: () async {
            return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Color(0xff161619),
                    title: Text(
                      'Do you want to change your password? You can change your password via a message sent by email.',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () async {
                            await authentication.sendPasswordResetEmail(email: loggedUser!.email.toString());
                            authentication.signOut();
                            Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()),);
                          },
                          child: Text('Yes')),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('No')),
                    ],
                  );
                });
            },
        );
  }

  Widget WithdrawalAccountBtn() {
    return StreamBuilder(
        stream: CollectRef.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return InkWell(
              child: Text('Withdrawal', style: TextStyle(
                letterSpacing: 1.0,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
                decoration: TextDecoration.underline,
              ),),
              onTap: () async {
                return await showDialog(context: context, builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Color(0xff161619),
                    title: Text('Do you want to withdrawal your account?',
                      style: TextStyle(fontSize: 16, color: Colors.white),),
                    actions: [
                      TextButton(
                          onPressed: () async {
                            await authentication.currentUser?.delete();
                            final DatabaseReference ref = FirebaseDatabase.instance.ref("UserList");
                            ref.child(loggedUser!.uid.toString()).remove();

                            int count = streamSnapshot.data!.docs.length;
                            for (int i = 0; i < count; i++) {
                              final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[i];
                              if (documentSnapshot['uid'] == loggedUser!.uid.toString()) {
                                Delete_FireStore(documentSnapshot.id);
                                break;
                              }
                            }

                            Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()),);},
                          child: Text('Yes')),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);},
                          child: Text('No')),
                    ],
                  );
                });
              },
            );
          }
          else {
            return Center(child: CircularProgressIndicator());
          }
        }
    );
  }

  Widget ButtonLine() {
    return Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ChangePasswordBtn(),
          WithdrawalAccountBtn(),
        ],
      )
    );
  }
}