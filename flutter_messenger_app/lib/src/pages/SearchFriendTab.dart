import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SearchFriendTab extends StatefulWidget {
  @override
  _SearchFriendTabState createState() => _SearchFriendTabState();
}

class _SearchFriendTabState extends State<SearchFriendTab> {
  final myController = TextEditingController();
  @override
  void initState() {}

  Future<String> _searchFriend(String name) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    Query query = ref.child('UserList').orderByChild('Name').equalTo(name);
    DataSnapshot event = await query.get();
    return event.children.elementAt(0).key ?? "error";
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Search")),
        body: Column(children: [
          Padding(
              padding: EdgeInsets.only(top: 16, left: 16, right: 16),
              child: TextField(
                controller: myController,
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: EdgeInsets.all(8),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade100)),
                ),
              )),
          TextButton(
              onPressed: () =>
                  {Navigator.pop(context, _searchFriend(myController.text))},
              child: Text("button"))
        ]));
  }
}
