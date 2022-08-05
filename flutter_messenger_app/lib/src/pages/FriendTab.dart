import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FriendTab extends StatefulWidget {
  @override
  _FriendTabState createState() => _FriendTabState();
}

/*
class ParsedUserData {
  String name;

}*/
class Test {
  final String name;
  final int id;
  Test(this.name, this.id);
}

Future<void> initFriend(DatabaseReference ref) async {
  final snapshot = await ref.child('User/hihi').get();
  if (snapshot.exists) {
    print(snapshot.value);
  } else {
    print('No data available.');
  }
}

Future<void> readData(DatabaseReference ref) async {
  final snapshot = await ref.child('User/hihi/Friend').get();

  var friendlist = snapshot.value;
  //int item;
  List<Object> friendList = [];
  // FriendList friends = new FriendList.fromJson(jsonResponse);
  /*
  for (item in List<int>.from(snapshot.value as List<Object?>)) {
    friendList.add(item);
  }*/
  //json.decode(snapshot.value.toString());
  if (snapshot.exists) {
    print(snapshot.value);
  } else {
    print('No data available.');
  }

  //print(friendList[0]);
}

class _FriendTabState extends State<FriendTab> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref();
  //List<Friend> _friends = [];

  /*
  @override
  void initState() {
    //super.initState();
    initFriend(ref);
  }*/

  Future<void> _addFriend() async {
    setState(() {
      DatabaseReference ref = FirebaseDatabase.instance.ref("User/hihi");

      int friendCount = 1;
      final friendData = {
        'uid': 123,
        'name': 'abc',
      };

      final newPostKey =
          FirebaseDatabase.instance.ref().child('posts').push().key;
      final Map<String, Map> updates = {};
      updates['/User/hihi/Friend/$newPostKey'] = friendData;
      //updates['/User/hihi/$uid/$newPostKey'] = postData;
      FirebaseDatabase.instance.ref().update(updates);
    });
  }

  void _read() {
    setState(() {
      final DatabaseReference ref = FirebaseDatabase.instance.ref();
      readData(ref);

      //test(ref);
      //snapshot 처리 필요
      //getfriendnum
      /*
      int friendCount = 1;
      final friendData = {
        'name': ['a', 'b', 'c'],
      };
      final newPostKey =
          FirebaseDatabase.instance.ref().child('posts').push().key;
      final Map<String, Map> updates = {};
      updates['/User/hihi/Friend/$newPostKey'] = friendData;
      //updates['/User/hihi/$uid/$newPostKey'] = postData;
      FirebaseDatabase.instance.ref().update(updates);*/
    });
  }

  //DatabaseReference ref = FirebaseDatabase.instance.ref('');

  //FirebaseDatabase database = FirebaseDatabase.instance;
  /* ex)
  DatabaseReference starCountRef =
        FirebaseDatabase.instance.ref('posts/$postId/starCount');
starCountRef.onValue.listen((DatabaseEvent event) {
    final data = event.snapshot.value;
    updateStarCount(data);
});*/

  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        TextButton(child: Text("write"), onPressed: _addFriend),
        TextButton(
          child: Text("read"),
          onPressed: _read,
        )
      ],
    ));
  }
}
