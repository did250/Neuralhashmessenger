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
        appBar: AppBar(
          title: Text("Search", style:TextStyle(fontSize: 16, color: Theme.of(context).primaryColor)),
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor,),
          backgroundColor: Theme.of(context).canvasColor,
          elevation: 0,
        ),
        body: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  child: Container(
                      height: 70,
                      padding: EdgeInsets.only(top: 16, left: 16, right: 2),
                      child:TextField(
                        controller: myController,
                        decoration: InputDecoration(
                        hintText: "Search...",
                        hintStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        contentPadding: EdgeInsets.all(8),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade200)),
                        ),
                      )
                  ),
                flex: 8,
              ),
              Expanded(
                child: IconButton(
                  iconSize: 30,
                  icon: Icon(
                    Icons.check,
                    color: Theme.of(context).primaryColor,
                  ),
                  padding: EdgeInsets.all(5),
                  constraints: BoxConstraints(),
                  onPressed: () =>
                  {Navigator.pop(context, _searchFriend(myController.text))},
                ),
                flex: 1,
              ),
            ]
        )
    );
  }
}
