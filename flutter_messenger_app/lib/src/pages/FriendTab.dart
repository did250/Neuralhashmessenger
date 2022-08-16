import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'SearchFriendTab.dart';

class FriendTab extends StatefulWidget {
  @override
  _FriendTabState createState() => _FriendTabState();
}

class Friend {
  String uid;
  String name;
  Friend(this.uid, this.name);
}

class FriendTile extends StatelessWidget {
  final Friend _friend;
  FriendTile(this._friend);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.person),
      title: Text(_friend.name),
    );
  }
}

Future<String> getNameFromUid(String uid) async {
  DatabaseReference ref = FirebaseDatabase.instance.ref('UserList/$uid/Name');
  final snapshot = await ref.get();
  if (snapshot.exists) {
    return snapshot.value.toString();
  } else {
    return "null";
  }
}

class _FriendTabState extends State<FriendTab> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref();
  List<Friend> myFriendList = [];

  @override
  void initState() {
    _getFriends();
  }

  Future<void> _addFriend(String friendUid) async {
    final user = FirebaseAuth.instance.currentUser;
    final myUid = user?.uid;
    DatabaseReference ref = FirebaseDatabase.instance.ref('UserList/$myUid');
    final snapshot = await ref.child('Friend').get();
    List<String> tempFriendList = [];
    if (snapshot.exists) {
      for (String item in List<String>.from(snapshot.value as List<Object?>)) {
        tempFriendList.add(item);
      }
      tempFriendList.add(friendUid);

      /* 중복체크 필요 */
      ref.update({'Friend': tempFriendList});
    } else {
      print("snaphost null");
      ref.update({
        'Friend': [friendUid]
      });
    }
    setState(() {
      //로컬 친구목록 갱신..
    });
  }

  Future<void> _getFriends() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await ref.child('UserList/$myUid/Friend').get();

    myFriendList = [];
    if (snapshot.exists) {
      for (String item in List<String>.from(snapshot.value as List<Object?>)) {
        myFriendList.add(Friend(item, await getNameFromUid(item)));
      }
    } else {
      print("friendlist null!");
    }
    //print(friendList);
    setState(() {});
  }

  _refresh() {
    setState(() {});
  }

  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: [
            //TextButton(child: Text("addfriend"), onPressed: _addFriend),
            TextButton(
              child: Text("getFriends"),
              onPressed: _getFriends,
            ),
            TextButton(onPressed: _refresh, child: Text('refresh')),
            Container(
                height: 500, width: 200, child: _buildListView(myFriendList)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (context) => SearchFriendTab()));
            if (result == 'error') {
            } else {
              _addFriend(result);
              _getFriends();
            }
          },
        ));
  }
}

Widget _buildListView(List<Friend> friendlist) {
  return ListView.builder(
      itemCount: friendlist.length,
      itemBuilder: (BuildContext context, int index) {
        //if (index == 0) return Text("builder index == 0");
        return FriendTile(friendlist[index]);
      });
}
