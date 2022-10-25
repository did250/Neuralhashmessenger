import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_messenger_app/src/pages/FriendTab.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;

String _name = "";
String _other = "";
List<Map<String, dynamic>> rooms = [];
String _fuid = "";
List<Messages> _message = <Messages>[];
int len = 0;

class ChatRoom extends StatefulWidget {
  final String name;
  final int number;
  const ChatRoom(this.name, this.number);
  ChatRoomState createState() => ChatRoomState(this.name, this.number);
}

class ChatRoomState extends State<ChatRoom> with TickerProviderStateMixin {
  File? _image;
  final picker = ImagePicker();
  String imageString = "";

  List<int> _checked = <int>[];
  String friendname = "";
  String frienduid = "";
  int number = -1;
  ChatRoomState(this.friendname, this.number);
  final TextEditingController _textController = TextEditingController();
  bool _exist = false;

  Future<String> encryptData(String data, encrypt.Key aesKey) async {
    final iv = encrypt.IV.fromLength(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey));

    final encrypted = encrypter.encrypt(data, iv: iv);
    print('encrypted : ${encrypted.base64}');
    encrypt.Encrypted temp = encrypt.Encrypted.fromBase64(encrypted.base64);
    final decrypted = encrypter.decrypt(temp, iv: iv);

    print(decrypted);

    return encrypted.base64;
  }

  Future uploadimage() async {
    final uri = Uri.parse("http://10.0.2.2:5000/test");
    var request = http.MultipartRequest('POST', uri);
    request.fields['name'] = "test";
    var pic = await http.MultipartFile.fromPath('images', _image!.path);
    request.files.add(pic);
    var streamdresponse = await request.send();
    var response = await http.Response.fromStream(streamdresponse);
    print(response.body);
    if (response.body == "true") {
      _showDialogT();
    } else if (response.body == "false") {
      _showDialogF();
    }
  }

  Future getImage(ImageSource imageSource) async {
    final image = await picker.pickImage(source: imageSource);
    setState(() {
      _image = File(image!.path);
    });

    final imageBytes = await _image!.readAsBytes();

    imageString = base64Encode(imageBytes);
    imageString += "123";
    uploadimage();
  }

  // 검열 통과 못한 경우 => "true 일 때"
  void _showDialogT() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("위험한 이미지입니다. 전송할 수 없습니다."),
          // content: new Text("Alert Dialog body"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("OK"),
              onPressed: () {
                imageString = "";
                _image = null;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // 검열 통과한 경우 => "false 일 때"
  void _showDialogF() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("사진을 전송하시겠습니까?"),
          // content: new Text("Alert Dialog body"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Yes"),
              onPressed: () {
                _handleSubmitted(imageString);
                imageString = "";
                _image = null;
                Navigator.pop(context);
              },
            ),
            new FlatButton(
              child: new Text("No"),
              onPressed: () {
                _image = null;
                imageString = "";
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// 사용자 이름 loading
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

  /// 메세지 하나 보낼 때, 서버에 갱신하는 함수
  Future<void> updatemessage(String input) async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final aesKey = encrypt.Key.fromBase64(await getAESKey(frienduid));
    final encryptedMessage = await encryptData(input, aesKey);

    await ref
        .child('ChattingRoom')
        .child(this.number.toString())
        .child('Messages')
        .child((_message.length).toString())
        .set({
      "checked": 1,
      "sender": _name,
      "text": encryptedMessage,
    });
  }

  /// 친구 uid 찾기
  Future<void> _searchFriend() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    Query query =
        ref.child('UserList').orderByChild('Name').equalTo(this.friendname);
    DataSnapshot event = await query.get();
    setState(() {
      this.frienduid = event.children.elementAt(0).key ?? "error";
      _fuid = this.frienduid;
    });
  }

  /// 채팅방 목록 불러오기
  Future<void> _roomcheck() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref
        .child('UserList')
        .child(FirebaseAuth.instance.currentUser!.uid.toString())
        .child('Num_Chatroom')
        .get();
    if (snapshot.exists && snapshot.value != null) {
      rooms.clear();
      for (var item in (snapshot.value as List<Object?>)) {
        Map<String, dynamic> map =
            Map<String, dynamic>.from(item as Map<dynamic?, dynamic?>);
        rooms.add(map);
      }
    }
  }

  /// 읽음 표시 하는 함
  Future<void> _checking() async {
    for (var item in rooms) {
      if (item['number'] == this.number) {
        int i = rooms.indexOf(item);
        if (!rooms[i]["check"].contains(_name)) {
          rooms[i]["check"] = [_name];
          final DatabaseReference ref = FirebaseDatabase.instance.ref();
          await ref
              .child('UserList')
              .child(FirebaseAuth.instance.currentUser!.uid.toString())
              .child('Num_Chatroom')
              .set(rooms);
        }
        break;
      }
    }
  }

  /// 메시지 보내면 현재 채팅방을 맨 위로
  Future<void> refreshmine() async {
    for (var item in rooms) {
      if (item['number'] == this.number) {
        int i = rooms.indexOf(item);
        rooms.removeAt(i);
        rooms.insert(0, item);
        rooms[0]["check"] = [_name];
      }
    }
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    await ref
        .child('UserList')
        .child(FirebaseAuth.instance.currentUser!.uid.toString())
        .child('Num_Chatroom')
        .set(rooms);
  }

  /// 메시지 보내면 친구의 채팅 목록에서 현재 채팅방을 맨 위로
  Future<void> refresh(String target) async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    List<Map<String, dynamic>> map2 = [];
    final snapshot =
        await ref.child('UserList').child(target).child('Num_Chatroom').get();
    if (snapshot.exists) {
      for (var item in (snapshot.value as List<Object?>)) {
        Map<String, dynamic> map =
            Map<String, dynamic>.from(item as Map<dynamic?, dynamic?>);
        if (map["number"] != this.number) {
          map2.add(map);
        } else {
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
        title: Text(widget.name,
            style: TextStyle(fontSize: 16, color: Colors.black)),
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            StreamBuilder(
                //수정할곳 end to end
                stream: FirebaseDatabase.instance
                    .ref()
                    .child("ChattingRoom")
                    .child(this.number.toString())
                    .child('Messages')
                    .onValue,
                builder: (BuildContext context, snapshot) {
                  if (snapshot.hasData) {
                    _message.clear();
                    _checked.clear();
                    var noexist = true;
                    int k = 0;
                    print("cycle");
                    for (var item in (snapshot.data as DatabaseEvent)
                        .snapshot
                        .value as List<Object?>) {
                      bool mine = false;
                      Map<String, dynamic> map = Map<String, dynamic>.from(
                          item as Map<dynamic?, dynamic?>);

                      if (map['sender'] != 'none' && map['text'] != 'none') {
                        noexist = false;
                      }
                      if (!noexist) {
                        if (map['sender'] == _name) {
                          mine = true;
                        }
                        Messages mas = Messages(
                          text: map['text'],
                          animationController: AnimationController(
                              duration: Duration(milliseconds: 0), vsync: this),
                          ismine: mine,
                        );

                        if (_message.length <= k) {
                          print("in");
                          _message.insert(0, mas);
                          mas.animationController.forward();
                          _checked.insert(0, map['checked']);
                        }
                      }
                      k += 1;
                    }
                    if (noexist) {
                      return Expanded(
                        child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "친구에게 메시지를 보내보세요.",
                              style: TextStyle(fontSize: 20),
                            )),
                      );
                    }
                    return Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        reverse: true,
                        itemCount: _message.length,
                        itemBuilder: (_, index) => _message[index],
                      ),
                    );
                  } else {
                    return Container();
                  }
                }),
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

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: Colors.grey.shade400,
            )),
        child: Row(
          children: <Widget>[
            // TextButton(
            //   onPressed: null,
            //   child: Text("+"),
            // ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.add_a_photo),
              color: Colors.black,
              tooltip: 'pick Image',
              padding: EdgeInsets.all(5),
              constraints: BoxConstraints(),
              onPressed: () {
                getImage(ImageSource.camera);
              },
            ),
            IconButton(
              icon: Icon(Icons.wallpaper),
              color: Colors.black,
              tooltip: 'pick Image',
              padding: EdgeInsets.all(5),
              constraints: BoxConstraints(),
              onPressed: () {
                getImage(ImageSource.gallery);
              },
            ),
            SizedBox(width: 5),
            Flexible(
              child: TextField(
                controller: _textController,
                onChanged: (text) {
                  setState(() {
                    _exist = text.length > 0;
                  });
                },
                onSubmitted: _exist ? _handleSubmitted : null,
                decoration:
                    InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.send),
                color: Colors.black,
                onPressed: _exist
                    ? () => _handleSubmitted(_textController.text)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //수정할곳 end to end
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
      _message.insert(0, message);
    });
    _roomcheck();
    refresh(this.frienduid);
    refreshmine();
    message.animationController.forward();
  }

  @override
  void dispose() {
    for (Messages message in _message) {
      message.animationController.dispose();
    }
    print("room = ?");
    print(rooms);
    print("--------");
    _checking();
    super.dispose();
  }
}

var _aesKey = null;

class Messages extends StatelessWidget {
  final String text;
  final AnimationController animationController;
  final bool ismine;

  Messages(
      {required this.text,
      required this.animationController,
      required this.ismine});

  String _decryptData(String data, encrypt.Key key) {
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    try {
      final decrypted =
          encrypter.decrypt(encrypt.Encrypted.fromBase64(data), iv: iv);
      return decrypted;
    } catch (exception) {
      return 'error key does not match';
    }
  }

  Future<String> _temp2(String input) async {
    _aesKey = encrypt.Key.fromBase64(await getAESKey(_fuid));

    print("===========");
    if (_aesKey == null) {
      print("null입니다 ");
    } else {
      print("not null");
    }
    final decrypteddata = _decryptData(input, _aesKey);
    // print(decrypteddata.runtimeType);
    // print(decrypteddata);
    return decrypteddata;
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:
          CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: Container(
        margin: ismine
            ? const EdgeInsets.only(top: 10, bottom: 10, left: 150.0)
            : const EdgeInsets.only(top: 10, bottom: 10, left: 0, right: 130.0),
        child: Row(
          mainAxisAlignment:
              ismine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ismine
                ? Container(
                    margin: const EdgeInsets.only(right: 10.0),
                  )
                : Container(
                    margin: const EdgeInsets.only(right: 10.0),
                    child: CircleAvatar(child: Text(_other[0])),
                  ),
            Container(child: (() {
              if (text.endsWith("123")) {
                final st = text.substring(0, text.length - 3);
                final Uint8List imageBytetest = base64Decode(st);

                return Container(
                  height: MediaQuery.of(context).size.height * 0.2,
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Center(
                    child: Image.memory(Uint8List.fromList(imageBytetest)),
                  ),
                );

                //--------------------------------------------------------------------------------------------------

              } else {
                if (_aesKey == null) {
                  return FutureBuilder<String>(
                    future: _temp2(text),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      if (ConnectionState.waiting == snapshot.connectionState) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return Container(
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          alignment: ismine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          padding: const EdgeInsets.all(5.0),
                          child: Text(snapshot.data!,
                              style: TextStyle(fontSize: 15.0)));
                    },
                    // child: Container(
                    //
                    //     constraints: BoxConstraints(
                    //         maxWidth: MediaQuery.of(context).size.width * 0.2),
                    //     decoration: BoxDecoration(
                    //       color: Colors.grey.shade300,
                    //       borderRadius: BorderRadius.circular(10),
                    //       border: Border.all(
                    //         color: Colors.grey.shade300,
                    //       ),
                    //     ),
                    //     alignment:
                    //         ismine ? Alignment.centerRight : Alignment.centerLeft,
                    //     padding: const EdgeInsets.all(5.0),
                    //     child: Text("Loading", style: TextStyle(fontSize: 15.0))),
                  );
                } else {
                  return Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      alignment:
                          ismine ? Alignment.centerRight : Alignment.centerLeft,
                      padding: const EdgeInsets.all(5.0),
                      child: Text(_decryptData(text, _aesKey),
                          style: TextStyle(fontSize: 15.0)));
                }
              }
            })()),
          ],
        ),
      ),
    );
  }
}
