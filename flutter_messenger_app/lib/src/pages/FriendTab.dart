import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FriendTab extends StatefulWidget {
  @override
  _FriendTabState createState() => _FriendTabState();
}

Future<void> initFriend() async {
  final DatabaseReference ref = FirebaseDatabase.instance.ref();
  final snapshot = await ref.child('ChattingRoom').get();
  if (snapshot.exists) {
    print(snapshot.value);
  } else {
    print('No data available.');
  }
}

class _FriendTabState extends State<FriendTab> {
  //List<Friend> _friends = [];
  @override
  void initState() {
    //super.initState();
    initFriend();
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
      body: Center(child: Text("Test")),
    );
  }
}
