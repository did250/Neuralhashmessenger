import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_messenger_app/src/pages/ChatTab.dart';
import 'package:flutter_messenger_app/src/pages/Login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'FriendTab.dart';
import 'Home.dart';

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

  int friend_count = 0;
  int chatroom_count = 0;

  TextEditingController userNameController = TextEditingController(text: '');

  String profile_img_base64 = "/9j/4QAYRXhpZgAASUkqAAgAAAAAAAAAAAAAAP/sABFEdWNreQABAAQAAAA8AAD/4QN8aHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJBZG9iZSBYTVAgQ29yZSA2LjAtYzAwMiA3OS4xNjQ0ODgsIDIwMjAvMDcvMTAtMjI6MDY6NTMgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlUmVmIyIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9IjAxOTAwOUNBMUYwNTNEODAxOEUwOEZERTU0OTM4MEJBIiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOjBENzNGRTFDMUI2OTExRUI4MDdCREFDMEFFQTkwNkJCIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjBENzNGRTFCMUI2OTExRUI4MDdCREFDMEFFQTkwNkJCIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCAyMDIxIFdpbmRvd3MiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo4YTYwZmZhMS05ZjBjLWZkNGItODI2ZS03MzU4MzFlMDM4YmQiIHN0UmVmOmRvY3VtZW50SUQ9ImFkb2JlOmRvY2lkOnBob3Rvc2hvcDo5YjI0MDFiYS1lMmE3LWEyNGItYmNiYi0wNTM3NWQyNWFiZWYiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz7/7gAOQWRvYmUAZMAAAAAB/9sAhAAGBAQEBQQGBQUGCQYFBgkLCAYGCAsMCgoLCgoMEAwMDAwMDBAMDg8QDw4MExMUFBMTHBsbGxwfHx8fHx8fHx8fAQcHBw0MDRgQEBgaFREVGh8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx//wAARCAMgAyADAREAAhEBAxEB/8QApwABAAIDAQEAAAAAAAAAAAAAAAYHAgQFAwEBAQADAQEBAAAAAAAAAAAAAAACAwQFAQYQAQACAQICBAgJCgQGAwEAAAABAgMEBREGITESB0FRYXGBkbE2oSIyQrITI4N0wVJicpKiwjNDFNGCU7Njc8MkFibwoxXjEQEAAgEDAgQFBAICAwAAAAAAAQIDETEEIYFBURIzYSIyEwVxQmIVkaEjFNHhUv/aAAwDAQACEQMRAD8A5T7NzwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA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";


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

    final friendshot = await ref.child("UserList").child(loggedUser!.uid.toString()).child("Friend").get();
    final chatroomshot = await ref.child("UserList").child(loggedUser!.uid.toString()).child("Num_Chatroom").get();

    if (snapshot.exists) {
      setState(() {
        image64String = snapshot.value.toString();
        origin_userName = namesnapshot.value.toString();
        userNameController = TextEditingController(text: origin_userName);
      });
    }

    if (friendshot.exists && friendshot.value != '') {
      for (String? item in List<String?>.from(friendshot.value as List<Object?>)) {
        if (item == null) {
          continue;
        }
        friend_count++;
      }
    }

    if (chatroomshot.value == '') {
      chatroom_count = 0;
    }
    else if (chatroomshot.value != '') {
      final chatnumshot = await ref.child("UserList").child(loggedUser!.uid.toString()).child("Next_Chatroom").get();
      chatroom_count = int.parse(chatnumshot.value.toString());
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
      body: StreamBuilder(
          stream: FirebaseDatabase.instance.ref().child("UserList").child(loggedUser!.uid.toString()).onValue,
          builder: (BuildContext context, snapshot) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                  child: Form(
                      key: this.formKey,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 25.0, ),

                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 7, ),
                                  Column(
                                      children: [
                                        showProfileImage(),
                                        Profile_img_opt(),
                                      ]),

                                  SizedBox(width: 30, ),
                                  Column(
                                      children: [
                                        ChangeLine(),
                                        showUserInfo(),
                                      ]
                                  )
                                ]
                            ),

                            SizedBox(height: 450.0, ),
                            ButtonLine(),
                          ]
                      )
                  )
              );}
            else {
              return Center(child: CircularProgressIndicator());
            }}),
    );
  }

  Widget showProfileImage() {
    final Uint8List Img8List = base64Decode(image64String);
    return Container(
        width: MediaQuery.of(context).size.width * 0.3,
        height: MediaQuery.of(context).size.height * 0.15,
        child: Container(
            child: Center(
                child: Container(
                  //child: Img8List.isEmpty
                  //? Image(image: AssetImage('assets/images/profile_img.jpg'),)
                    child: _image == null
                        ? Image.memory(Uint8List.fromList(Img8List))
                        : Image.file(File(_image!.path))))));
  }

  Widget showUserInfo() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                        child: Column(
                            children: [
                              Text(friend_count.toString(),
                                style: TextStyle(
                                  letterSpacing: 1.0,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),

                              SizedBox(height: 10),

                              Text("FRIEND",
                                  style: TextStyle(
                                    letterSpacing: 1.0,
                                    fontSize: 10,
                                    color: Colors.black,
                                  )
                              ),
                            ])),

                    SizedBox(width: 30),

                    Container(
                        child: Column(
                            children: [
                              Text(chatroom_count.toString(),
                                style: TextStyle(
                                  letterSpacing: 1.0,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),

                              SizedBox(height: 10),

                              Text("CHATROOM",
                                  style: TextStyle(
                                    letterSpacing: 1.0,
                                    fontSize: 10,
                                    color: Colors.black,
                                  )
                              ),
                            ])),
                  ]
              )
          ),
        ]
    );
  }

  Widget showUserNameInput() {
    return Column(
      children: [
        Container(
          width: 150,
          height: 30,
          child: TextFormField(
            controller: userNameController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Username to change',
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
    return IconButton(
      icon: Icon(
        Icons.check,
        color: Colors.black,
      ),
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          formKey.currentState!.save();

          final DatabaseReference ref = FirebaseDatabase.instance.ref("UserList");
          ref.child(loggedUser!.uid.toString()).update({
            "Name": userName,
          });

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
        showUserNameInput(),
        ChangeUserNameBtn(),
      ],
    );
  }

  Widget Profile_img_opt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.add_a_photo),
          tooltip: 'pick Image',
          padding: EdgeInsets.all(3),
          constraints: BoxConstraints(),
          onPressed: () {
            getImage(ImageSource.camera);
          },
        ),

        IconButton(
          icon: Icon(Icons.wallpaper),
          tooltip: 'pick Image',
          padding: EdgeInsets.all(3),
          constraints: BoxConstraints(),
          onPressed: () {
            getImage(ImageSource.gallery);
          },
        ),

        IconButton(
            icon: Icon(Icons.account_circle_rounded),
            tooltip: 'pick Image',
            padding: EdgeInsets.all(3),
            constraints: BoxConstraints(),
            onPressed: () async {
              return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Color(0xff161619),
                      title: Text(
                        'Do you want to change to the default image?',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      actions: [
                        TextButton(
                            child: Text('Save'),
                            onPressed: () async {
                              DatabaseReference ref = FirebaseDatabase.instance.ref("UserList");
                              ref.child(loggedUser!.uid.toString()).update({
                                "Profile_img": profile_img_base64,
                              });
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return Home();
                                },),);
                            }
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
            }
        ),

        IconButton(
          icon: Icon(Icons.add),
          padding: EdgeInsets.all(3),
          constraints: BoxConstraints(),
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

                        SharedPreferences pref = await SharedPreferences.getInstance();
                        pref.clear();

                        onLogOut();

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

                            SharedPreferences pref = await SharedPreferences.getInstance();
                            pref.clear();

                            onLogOut();

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