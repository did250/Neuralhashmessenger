import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_messenger_app/src/pages/ChatRoom.dart';
import 'package:firebase_database/firebase_database.dart';

String _name = "";
List<Map<String, dynamic>> room = [];

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

  List<String> temp_names = <String>[];
  List<int> temp_numbers = <int>[];
  List<bool> temp_check = <bool>[];

  void clearall() {
    names.clear();
    numbers.clear();
    check.clear();
    room.clear();
  }

  Future<void> Loaduser() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref
        .child('UserList')
        .child(FirebaseAuth.instance.currentUser!.uid.toString())
        .child('Name')
        .get();
    if (snapshot.exists) {
      setState(() {
        _name = snapshot.value.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Loaduser();
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
                hintStyle: TextStyle(
                    color: Colors.grey.shade600, fontWeight: FontWeight.bold),
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
            ),
          ),
          StreamBuilder(
              stream: FirebaseDatabase.instance
                  .ref()
                  .child('UserList')
                  .child(FirebaseAuth.instance.currentUser!.uid.toString())
                  .child('Num_Chatroom')
                  .onValue,
              builder: (BuildContext context, snapshot) {
                if (ConnectionState.waiting == snapshot.connectionState) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text("error");
                } else if (snapshot.data == null) {
                  return Text("no data");
                } else if ((snapshot.data as DatabaseEvent).snapshot.value ==
                    null) {
                  numbers = temp_numbers;
                  check = temp_check;
                  names = temp_names;
                  print(temp_names);
                  print(names);
                  return ListView.separated(
                    padding: EdgeInsets.only(top: 15),
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: names.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) =>
                                    ChatRoom(names[index], numbers[index]))),
                        child: Container(
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(child: Text(names[index][0])),
                            title: Text(
                              names[index],
                              style: TextStyle(fontSize: 14),
                            ),
                            subtitle: check[index]
                                ? Text("")
                                : Text(
                                    "새로운 메시지가 있습니다.",
                                    style: TextStyle(fontSize: 12),
                                  ),
                            trailing: check[index]
                                ? null
                                : Icon(
                                    Icons.mark_email_unread,
                                    color: Colors.red,
                                  ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                  );
                } else if (snapshot.hasData && snapshot.data != null) {
                  //print("sss");
                  names.clear();
                  numbers.clear();
                  check.clear();
                  room.clear();
                  for (var item in (snapshot.data as DatabaseEvent)
                      .snapshot
                      .value as List<Object?>) {
                    Map<String, dynamic> map = Map<String, dynamic>.from(
                        item as Map<dynamic, dynamic>);

                    numbers.add(map["number"]);
                    names.add(map["with"]);
                    check.add(map["check"]?.contains(_name));
                    room.add(map);
                  }
                  temp_check = check;
                  temp_names = names;
                  temp_numbers = numbers;
                  return ListView.separated(
                    padding: EdgeInsets.only(top: 15),
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: names.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) =>
                                    ChatRoom(names[index], numbers[index]))),
                        child: Container(
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(child: Text(names[index][0])),
                            title: Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                names[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            subtitle: check[index]
                                ? Text("")
                                : Text(
                                    "새로운 메시지가 있습니다.",
                                    style: TextStyle(fontSize: 12),
                                  ),
                            trailing: check[index]
                                ? null
                                : Icon(
                                    Icons.mark_email_unread,
                                    color: Colors.red,
                                  ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                  );
                } else {
                  return Text("no data");
                }
              }),
        ],
      ),
    ));
  }
}
