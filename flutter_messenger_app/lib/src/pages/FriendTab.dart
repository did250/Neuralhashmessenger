import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'SearchFriendTab.dart';

class FriendTab extends StatefulWidget {
  @override
  _FriendTabState createState() => _FriendTabState();
}

class _FriendTabState extends State<FriendTab> {
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
  List<Friend> myFriendList = [];
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _addFriend(String friendUid) async {
    DatabaseReference myRef = FirebaseDatabase.instance.ref('UserList/$myUid');
    final snapshot = await myRef.child('Friend').get();

    List<Map<String, String>> tempFriendList = [];
    if (snapshot.exists && snapshot.value != '') {
      for (var item in List<Object>.from(snapshot.value as List<Object?>)) {
        Map<String, String> map =
            Map<String, String>.from(item as Map<dynamic, dynamic>);
        tempFriendList.add(map);
      }
      /* 중복체크 필요 */
    }
    Future<String> name = _getNameFromUid(friendUid);
    name.then(
      (value) => {
        tempFriendList.add({'Name': value, 'Uid': friendUid}),
        myRef.update({'Friend': tempFriendList}),
      },
    );
  }

  Future<String> _getNameFromUid(String uid) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('UserList/$uid/Name');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return snapshot.value.toString();
    } else {
      return "null";
    }
  }

  _refreshState() {
    setState(() {});
  }

  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: [
            StreamBuilder(
                stream: FirebaseDatabase.instance
                    .ref()
                    .child('UserList')
                    .child(FirebaseAuth.instance.currentUser!.uid.toString())
                    .child('Friend')
                    .onValue,
                builder: (BuildContext context, snapshot) {
                  if (snapshot.hasData) {
                    myFriendList.clear();
                    for (var item in (snapshot.data as DatabaseEvent)
                        .snapshot
                        .value as List<Object?>) {
                      if (item == null) {
                        continue;
                      }
                      Map<String, dynamic> map = Map<String, dynamic>.from(
                          item as Map<dynamic, dynamic>);
                      myFriendList.add(Friend(map['Uid']!, map['Name']!));
                    }
                    return Container(
                        height: 500,
                        width: 200,
                        child: _buildListView(myFriendList));
                  } else {
                    return Container();
                  }
                }),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (context) => SearchFriendTab()));
            if (result == 'error') {
              //추가필요
            } else {
              _addFriend(result);
            }
          },
        ));
  }
}

Widget _buildListView(List<Friend> friendlist) {
  return ListView.builder(
      itemCount: friendlist.length,
      itemBuilder: (BuildContext context, int index) {
        return FriendTile(friendlist[index]);
      });
}

class FriendTile extends StatelessWidget {
  final Friend _friend;
  FriendTile(this._friend);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.person),
      title: Text(_friend.name),
      onTap: () => null,
    );
  }
}

class Friend {
  String uid;
  String name;
  Friend(this.uid, this.name);
}
