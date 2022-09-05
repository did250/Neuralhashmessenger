import 'dart:ffi';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_messenger_app/src/pages/ChatRoom.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ntp/ntp.dart';

List<Map<String,dynamic>> room = [];

class ChatTab extends StatefulWidget {
  @override
  ChatTabState createState() => ChatTabState();
}

class ChatTabState extends State<ChatTab> {

  List<String> names = <String>[];
  List<int> numbers = <int>[];
  List<int> times = <int>[];
  List<String> messages = <String>[];
  List<bool> check = <bool>[];
  // Future<void> readChattingRoom() async {
  //   final DatabaseReference ref = FirebaseDatabase.instance.ref();
  //   final snapshot = await ref.child('UserList').child(FirebaseAuth.instance.currentUser!.uid.toString()).child('Num_Chatroom').get();
  //   if ( snapshot.exists ) {
  //     for ( var item in (snapshot.value as List<Object?>)) {
  //       Map<String, dynamic> map = Map<String, dynamic>.from(item as Map<dynamic?, dynamic?>);
  //       numbers.add(map["number"]);
  //       names.add(map["with"]);
  //     }
  //     setState(() {
  //
  //     });
  //
  //   }
  // }

  Future<void> time() async {
    DateTime current = await NTP.now();
    print(current);
  }

  Future<void> _roomcheck() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('UserList').child(FirebaseAuth.instance.currentUser!.uid.toString()).child('Num_Chatroom').get();
    if (snapshot.exists){
      names.clear();
      numbers.clear();
      check.clear();
      room.clear();
      for ( var item in (snapshot.value as List<Object?>)) {
        Map<String,dynamic> map = Map<String, dynamic>.from(item as Map<dynamic?, dynamic?>);
        room.add(map);
        numbers.add(map["number"]);
        names.add(map["with"]);
        check.add(map["check"]?.contains("yang"));
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 16, left: 16, right: 16),
                child: TextField(
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
                ),
              ),
              StreamBuilder(
                  stream: FirebaseDatabase.instance.ref().child('UserList').child(FirebaseAuth.instance.currentUser!.uid.toString()).child('Num_Chatroom').onValue,
                  builder: (BuildContext context, snapshot) {
                    if (ConnectionState.waiting == snapshot.connectionState) {
                      return Center(child: CircularProgressIndicator());
                    }
                    else if (snapshot.hasError) {
                      return Text("error");
                    }
                    else if (snapshot.data == null) {
                      return Text("no data");
                    }
                    else if (snapshot.hasData && snapshot.data != null){
                      names.clear();
                      numbers.clear();
                      check.clear();
                      room.clear();
                      for (var item in (snapshot.data as DatabaseEvent).snapshot.value as List<Object?>) {
                        Map<String, dynamic> map = Map<String, dynamic>.from(
                            item as Map<dynamic?, dynamic?>);
                        numbers.add(map["number"]);
                        names.add(map["with"]);

                        check.add(map["check"]?.contains("yang"));
                        room.add(map);
                      }
                      print(check);
                      return ListView.separated(
                        padding: EdgeInsets.only(top: 15),
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: names.length,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) =>
                                    ChatRoom(names[index], numbers[index]))),
                            child: Container(
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(child: Text(names[index][0])),
                                title: Text(names[index], style: TextStyle(fontSize: 14),),
                                subtitle: check[index] ? Text("") : Text("새로운 메시지가 있습니다.",style: TextStyle(fontSize: 12),),
                                trailing: check[index] ? null : Icon(Icons.mark_email_unread, color: Colors.red,),
                              ),
                              // child: Row(
                              //   crossAxisAlignment: CrossAxisAlignment.start,
                              //   children: <Widget>[
                              //     Container(
                              //       margin: const EdgeInsets.only(right: 16),
                              //       child: CircleAvatar(child: Text(names[index][0])),
                              //     ),
                              //     Expanded(
                              //       child: Column(
                              //         crossAxisAlignment: CrossAxisAlignment.start,
                              //         children: <Widget>[
                              //           Text(names[index]),
                              //         ],
                              //       ),
                              //     )
                              //   ],
                              // ),
                            ),
                          );
                        },
                        separatorBuilder: (BuildContext context,
                            int index) => const Divider(),
                      );
                    }
                    else {
                      return Text("no data");
                    }
                  }
              ),

            ],
          ),
        ));
  }
}
