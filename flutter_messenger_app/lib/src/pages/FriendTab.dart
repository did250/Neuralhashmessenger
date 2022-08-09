import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FriendTab extends StatefulWidget {
  @override
  _FriendTabState createState() => _FriendTabState();
}

Future<void> initFriend(DatabaseReference ref) async {
  final snapshot = await ref.child('UserList/hihi').get();
  if (snapshot.exists) {
    print(snapshot.value);
  } else {
    print('No data available.');
  }
}

Future<void> readData(DatabaseReference ref) async {
  final user = FirebaseAuth.instance.currentUser;
  final myEmail = user?.email;
  final snapshot = await ref.child('UserList/$myEmail').get();

  List<int> friendList = [];

  print(snapshot.value);

  for (int item in List<int>.from(snapshot.value as List<Object?>)) {
    friendList.add(item);
  }
  //json.decode(snapshot.value.toString());
  if (snapshot.exists) {
    print(snapshot.value);
  } else {
    print('No data available.');
  }

  //print(friendList[0]);
}

Future<void> getNameFromUid(List<int> FriendList) async {
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  for (int i = 0; i < FriendList.length; i++) {
    int uid = FriendList[i];
    ref.child('User/$uid/name');
  }
}

Future<void> writeData(DatabaseReference ref) async {
  print("start!");
  final user = FirebaseAuth.instance.currentUser;
  final myEmail = user?.email;
  print(myEmail);
  DatabaseReference ref = FirebaseDatabase.instance.ref();

  /************ */

  final snapshot = await ref.child('UserList/$myEmail').get();

  /************* */
  //추가할 친구 관련 코드 여기에

  /************* */
  if (!snapshot.exists) {
    print("snaphost null");
    ref.update({
      'Friend': [0]
    });
  } else {
    print("snapshot exist!");
    List<int> friendList = [];
    for (int item in List<int>.from(snapshot.value as List<Object?>)) {
      friendList.add(item);
    }
    print(friendList[0]);

    /* 중복체크 필요 */
    friendList.add(Random().nextInt(10000) /*추가할 친구*/);

    ref.update({'Friend': friendList});

    //final Map<String, int> updates = {};
    //updates['/User/hihi/Friend/'] = friendList;
    //updates['/User/hihi/$uid/$newPostKey'] = postData;
    //FirebaseDatabase.instance.ref().update(updates);*/
    print("haha");
  }
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
      final DatabaseReference ref = FirebaseDatabase.instance.ref();
      writeData(ref);
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
