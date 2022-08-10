import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FriendTab extends StatefulWidget {
  @override
  _FriendTabState createState() => _FriendTabState();
}

Future<void> initFriend(DatabaseReference ref) async {
  /* 첫 실행시 친구목록 로딩 */
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  final snapshot = await ref.child('UserList/$myUid/Friend').get();
  if (snapshot.exists) {
    print(snapshot.value);
  } else {
    print('No data available.');
  }
}

Future<void> readData(DatabaseReference ref) async {
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  final snapshot = await ref.child('User/$myUid').get();

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
  /* todo.. */
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  for (int i = 0; i < FriendList.length; i++) {
    int uid = FriendList[i];
    ref.child('User/$uid/Name');
  }
}

Future<String> searchFriend() async {
  var name = "Yoon";
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  Query query = ref.child('UserList').orderByChild('Name').equalTo(name);
  DataSnapshot event = await query.get();
  /* 검색실패 구현필요 */

  return event.children.elementAt(0).key ?? "error";
}

Future<void> writeData(DatabaseReference ref) async {
  final user = FirebaseAuth.instance.currentUser;
  final myUid = user?.uid;
  DatabaseReference ref = FirebaseDatabase.instance.ref('UserList/$myUid');

  /************ */

  final snapshot = await ref.child('Friend').get();

  /************* */
  //추가할 친구 관련 코드 여기에

  /************* */
  if (!snapshot.exists) {
    print("snaphost null");
    ref.update({
      'Friend': [0]
    });
  } else {
    List<int> myFriendList = [];
    for (int item in List<int>.from(snapshot.value as List<Object?>)) {
      myFriendList.add(item);
    }
    //print(myFriendList[0]);

    /* 중복체크 필요 */
    myFriendList.add(Random().nextInt(10000) /*추가할 친구*/);

    ref.update({'Friend': myFriendList});
    //ref.update({'Name': 'Kangmin Lee', 'Email': 'seyrinn@g.skku.edu'});
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
        ),
        TextButton(child: Text("search"), onPressed: searchFriend),
      ],
    ));
  }
}
