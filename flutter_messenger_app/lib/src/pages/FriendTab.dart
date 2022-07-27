import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FriendTab extends StatefulWidget {
  @override
  _FriendTabState createState() => _FriendTabState();
}

class _FriendTabState extends State<FriendTab> {
  @override
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  //FirebaseDatabase database = FirebaseDatabase.instance;
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(child: Text("Friend")),
      ),
    );
  }
}
