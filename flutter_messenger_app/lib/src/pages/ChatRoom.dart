import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

String _name = "";
String _other = "";

class ChatRoom extends StatefulWidget {
  final String name;
  final int number;
  const ChatRoom(this.name, this.number);
  ChatRoomState createState() => ChatRoomState(this.name, this.number);
}

class ChatRoomState extends State<ChatRoom> with TickerProviderStateMixin{

  final List<Map<String,dynamic>> room = [];
  List<Messages> _message = <Messages>[];
  List<int> _checked = <int>[];
  String friendname = "";
  String frienduid = "";
  int number = -1;
  ChatRoomState(this.friendname, this.number);
  final TextEditingController _textController = TextEditingController();
  bool _exist = false;

  /// 사용자 이름 loading
  Future<void> Loaduser() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('UserList').child(FirebaseAuth.instance.currentUser!.uid.toString()).child('Name').get();
    if ( snapshot.exists ) {
      setState(() {
        _name = snapshot.value.toString();
      });
    }
  }

  /// 메세지 하나 보낼 때, 서버에 갱신하는 함수
  Future<void> updatemessage(String input) async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    await ref.child('ChattingRoom').child(this.number.toString()).child('Messages').child((_message.length).toString()).set({
      "checked": 1,
      "sender": _name,
      "text": input,
    });
  }

  /// 친구 uid 찾기
  Future<void> _searchFriend() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    Query query = ref.child('UserList').orderByChild('Name').equalTo(this.friendname);
    DataSnapshot event = await query.get();
    setState(() {
      this.frienduid = event.children.elementAt(0).key ?? "error";
    });
  }

  /// 채팅방 목록 불러오기
  Future<void> _roomcheck() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('UserList').child(FirebaseAuth.instance.currentUser!.uid.toString()).child('Num_Chatroom').get();
    if (snapshot.exists){
      room.clear();
      for ( var item in (snapshot.value as List<Object?>)) {
        Map<String,dynamic> map = Map<String, dynamic>.from(item as Map<dynamic?, dynamic?>);
        room.add(map);
      }
    }
  }

  /// 읽음 표시 하는 함
  Future<void> _checking() async {
    for (var item in room){
      if (item['number'] == this.number){
        int i = room.indexOf(item);
        if (!room[i]["check"].contains(_name)) {
          room[i]["check"] = [_name];
        }
      }
    }
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    await ref.child('UserList').child(FirebaseAuth.instance.currentUser!.uid.toString()).child('Num_Chatroom').set(room);
  }

  /// 메시지 보내면 현재 채팅방을 맨 위로
  Future<void> refreshmine() async {
    for (var item in room){
      if (item['number'] == this.number){
        int i = room.indexOf(item);
        room.removeAt(i);
        room.insert(0, item);
        room[0]["check"] = [_name];
      }
    }
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    await ref.child('UserList').child(FirebaseAuth.instance.currentUser!.uid.toString()).child('Num_Chatroom').set(room);

  }

  /// 메시지 보내면 친구의 채팅 목록에서 현재 채팅방을 맨 위로
  Future<void> refresh(String target) async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    List<Map<String,dynamic>> map2 = [];
    final snapshot = await ref.child('UserList').child(target).child('Num_Chatroom').get();
    if ( snapshot.exists ){
      for ( var item in (snapshot.value as List<Object?>)) {
        Map<String,dynamic> map = Map<String, dynamic>.from(item as Map<dynamic?, dynamic?>);
        if (map["number"] != this.number) {
          map2.add(map);
        }
        else {
          map2.insert(0, map);
          map2[0]["check"] = [_name];
        }
      }
    }
   await ref.child('UserList').child(target).child('Num_Chatroom').set(map2);

  }


  @override
  void initState() {
    // TODO: implement initState
    Loaduser();
    _other = this.friendname;
    _searchFriend();
    _roomcheck();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.name)
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            StreamBuilder(
              stream: FirebaseDatabase.instance.ref().child("ChattingRoom").child(this.number.toString()).child('Messages').onValue,
              builder: (BuildContext context, snapshot) {
                if (snapshot.hasData) {
                  _message.clear();
                  _checked.clear();
                  for (var item in (snapshot.data as DatabaseEvent).snapshot
                      .value as List<Object?>) {
                    bool mine = false;
                    Map<String, dynamic> map = Map<String, dynamic>.from(
                        item as Map<dynamic?, dynamic?>);
                    if (map['sender'] == _name) {
                      mine = true;
                    }
                    Messages mas = Messages(text: map['text'],
                      animationController: AnimationController(
                          duration: Duration(milliseconds: 0), vsync: this),
                      ismine: mine,);
                    _message.insert(0, mas);
                    mas.animationController.forward();
                    _checked.insert(0, map['checked']);
                  }
                  return Flexible(child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    reverse: true,
                    itemCount: _message.length,
                    itemBuilder: (_, index) => _message[index],
                  ),
                  );
                }
                else {
                  return Container();
                }
              }
            ),
            Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              child: _buildTextComposer(),
            )
          ],
        ),
      ),
    );
  }
  Widget _buildTextComposer(){
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onChanged: (text){
                  setState(() {
                    _exist = text.length > 0;
                  });
                },
                onSubmitted: _exist ? _handleSubmitted : null,
                decoration: InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: CupertinoButton(
                child: Text("보내기"),
                onPressed: _exist ? () => _handleSubmitted(_textController.text) :null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _exist = false;
      updatemessage(text);
    });
    Messages message = Messages(
      text: text,
      animationController: AnimationController(
        duration: Duration(milliseconds: 700),
        vsync: this,
      ),
      ismine: true,
    );
    setState(() {
      _message.insert(0,message);
    });
    _roomcheck();
    refresh(this.frienduid);
    refreshmine();
    message.animationController.forward();
  }

  @override
  void dispose() {
    for (Messages message in _message){
      message.animationController.dispose();
    }
    _checking();
    super.dispose();
  }

}

class Messages extends StatelessWidget {
  final String text;
  final AnimationController animationController;
  final bool ismine;
  Messages({required this.text, required this.animationController, required this.ismine});

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: Container(
        margin: ismine? const EdgeInsets.only(top: 10, bottom: 10, left: 150.0) : const EdgeInsets.only(top: 10, bottom: 10, left: 0, right: 130.0),
        child: Row(
          mainAxisAlignment: ismine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ismine ? Container(
              margin: const EdgeInsets.only(right: 10.0),
            ) : Container(
              margin: const EdgeInsets.only(right: 10.0),
              child: CircleAvatar(child: Text(_other[0])) ,
            ),
            Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.2
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(),
                ),
                alignment: ismine ? Alignment.centerRight : Alignment.centerLeft,
                padding: const EdgeInsets.all(5.0),
                child: Text(text, style: TextStyle(fontSize: 15.0))
            ),
          ],
        ),
      ),
    );
  }
}