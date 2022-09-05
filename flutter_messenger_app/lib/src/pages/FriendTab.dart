import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'SearchFriendTab.dart';
import 'ChatRoom.dart';

class FriendTab extends StatefulWidget {
  @override
  _FriendTabState createState() => _FriendTabState();
}

class _FriendTabState extends State<FriendTab> {
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
  List<Friend> myFriendList = [];
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  void initState() {
    _getFriend();
  }

  Future<void> _getFriend() async {
    DatabaseReference myFriendRef = rootRef.child("UserList/$myUid/Friend");
    final snapshot = await myFriendRef.get();
    myFriendList = [];
    if (snapshot.exists && snapshot.value != '') {
      for (String? item
          in List<String?>.from(snapshot.value as List<Object?>)) {
        if (item == null) {
          continue;
        }
        myFriendList.add(Friend(item, await _getNameFromUid(item)));
      }
    }

    print(myFriendList);

    setState(() {});
  }

  Future<void> _addFriend(String friendUid) async {
    DatabaseReference myFriendRef = rootRef.child("UserList/$myUid/Friend");

    final snapshot = await myFriendRef.get();

    List<String> tempFriendList = [];
    if (snapshot.exists && snapshot.value != '') {
      for (String? item
          in List<String?>.from(snapshot.value as List<Object?>)) {
        if (item == null) {
          continue;
        }
        tempFriendList.add(item);
      }
    }
    tempFriendList.add(friendUid);
    rootRef.child('UserList/$myUid').update({'Friend': tempFriendList});
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
            Container(
                height: 500, width: 200, child: _buildListView(myFriendList))
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (context) => SearchFriendTab()));
            if (result == 'error') {
              print('error');
            } else {
              print(result);
              await _addFriend(result);
              _getFriend();
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
      onTap: () async {
        /*새 채팅방*/
        final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
        final snapshot = await rootRef.child('ChattingRoom/next').get();

        int nextnumChatroom;
        if (snapshot.exists) {
          nextnumChatroom = int.parse(snapshot.value.toString());
        } else {
          nextnumChatroom = 0;
        }
        var myUid = FirebaseAuth.instance.currentUser?.uid;
        final snapshot2 = await rootRef.child('UserList/$myUid/Name').get();
        String myname = snapshot2.value.toString();
        rootRef.child('ChattingRoom').update({
          '$nextnumChatroom': {
            'Members': {
              '0': myname,
              '1': _friend.name,
            },
            'Messages': {}
          }
        });
        final snapshot3 =
            await rootRef.child('UserList/$myUid/Next_Chatroom').get();

        int nextnumPerUser;
        if (snapshot3.exists) {
          nextnumPerUser = int.parse(snapshot3.value.toString());
        } else {
          nextnumPerUser = 0;
        }

        rootRef.child('UserList/$myUid/Num_Chatroom').update({
          '$nextnumPerUser': {
            'number': nextnumChatroom,
            'with': _friend.name,
          }
        });
        nextnumChatroom++;
        nextnumPerUser++;
        rootRef.child('ChattingRoom').update({'next': nextnumChatroom});
        rootRef
            .child('UserList/$myUid')
            .update({'Next_Chatroom': nextnumPerUser});
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ChatRoom(_friend.name, nextnumChatroom - 1)));
      },
    );
  }
}

class Friend {
  String uid;
  String name;
  Friend(this.uid, this.name);
}
