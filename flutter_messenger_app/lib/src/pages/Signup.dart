import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_messenger_app/src/pages/Home.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final authentication = FirebaseAuth.instance;

  User? loggedUser;

  bool userNameChecked = false;

  final formKey = GlobalKey<FormState>();
  String userName = '';
  String userEmail = '';
  String userPassword = '';

  CollectionReference CollectRef = FirebaseFirestore.instance.collection('users');

  final storage = FlutterSecureStorage();
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _firstTime() async {
    final algorithmDF = X25519();
    final myKeyPair = await algorithmDF.newKeyPair();
    final myPublicKey = await myKeyPair.extractPublicKey();
    final myPrivateKey = await myKeyPair.extractPrivateKeyBytes();
    // secure storage에 private key 저장, firebase에 public key 저장
    await storage.write(key: 'myPrivateKey', value: base64Encode(myPrivateKey));
    rootRef
        .child('UserList/$myUid')
        .update({'PublicKey': base64Encode(myPublicKey.bytes)});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(top: 200),
          padding: EdgeInsets.all(30),
          child: Form(
          key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 50,
                  width: 400,
                  alignment: Alignment.topCenter,
                  child: Text("SIGNUP",
                    style: TextStyle(
                      letterSpacing: 1.0,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black38,
                    ),
                  ),
                ),

                TextFormField(
                  key: ValueKey(1),
                  validator: (value) {
                    if (value!.isEmpty || value.length < 4) {
                      userNameChecked = false;
                      return 'Please enter at least 4 characters';
                    }
                    userNameChecked = true;
                    return null;
                  },
                  onSaved: (value) {
                    userName = value!;
                  },
                  onChanged: (value) {
                    userName = value;
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.account_circle,
                      color: Color(0xFFB6C7D1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color(0XFFA7BCC7)),
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    hintText: 'User name',
                    hintStyle: TextStyle(
                        fontSize: 14,
                        color: Color(0XFFA7BCC7)),
                    contentPadding: EdgeInsets.all(10)),
              ),

              SizedBox(height: 8,),

              TextFormField(
                keyboardType: TextInputType.emailAddress,
                key: ValueKey(2),
                validator: (value) {
                  if (value!.isEmpty ||
                      !value.contains('@')) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
                onSaved: (value) {
                  userEmail = value!;
                },
                onChanged: (value) {
                  userEmail = value;
                },
                decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.email,
                      color: Color(0xFFB6C7D1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color(0XFFA7BCC7)),
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    hintText: 'email',
                    hintStyle: TextStyle(
                        fontSize: 14,
                        color: Color(0XFFA7BCC7)),
                    contentPadding: EdgeInsets.all(10)),
              ),

              SizedBox(height: 8,),

                TextFormField(
                  obscureText: true,
                  key: ValueKey(3),
                  validator: (value) {
                    if (value!.isEmpty || value.length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    userPassword = value!;
                  },
                  onChanged: (value) {
                    userPassword = value;
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.lock,
                      color: Color(0xFFB6C7D1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color(0XFFA7BCC7)),
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    hintText: 'password',
                    hintStyle: TextStyle(
                        fontSize: 14,
                        color: Color(0XFFA7BCC7)),
                    contentPadding: EdgeInsets.all(10)),
                ),

                SizedBox(height: 8,),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white24,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.0)
                    ),
                    minimumSize: const Size.fromHeight(50),
                    ),

                    child: Text('Welcome', style: TextStyle(fontSize: 20)),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();

                        if (userNameChecked) {
                          try {
                            final newUser = await authentication.createUserWithEmailAndPassword(
                              email: userEmail,
                              password: userPassword,
                            );

                            if (newUser.user != null) { //SIGNUP SUCCESS
                              try {
                                final user = authentication.currentUser;
                                if (user != null) {
                                  loggedUser = user;
                                }
                              } catch (e) {
                                print(e);
                              }

                              DatabaseReference ref = FirebaseDatabase.instance.ref("UserList/" + loggedUser!.uid.toString());

                              await ref.set({
                                "Email": userEmail,
                                "Name": userName,
                                "Friend": "",
                                "Num_Chatroom": "",
                                "Profile_img": "",
                              });

                              await CollectRef.add({'uid': loggedUser!.uid.toString(), 'Email': userEmail, 'Name': userName, 'Friend': ""});

                              Navigator.push(context, MaterialPageRoute(builder: (context) {
                                  return Home(); },
                              ),);

                              _firstTime();
                            }
                          } catch (e) {//SIGNUP FAILED
                            print(e);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
                                  'Please check your email and password'),
                                  backgroundColor: Colors.blue,),
                            );
                          }
                        }
                      }
                    },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}