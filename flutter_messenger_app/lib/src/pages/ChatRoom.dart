import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_messenger_app/src/pages/FriendTab.dart';
import 'package:flutter_messenger_app/src/pages/ShowImage.dart';

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';

String _name = "";
String _other = "";
List<Map<String, dynamic>> rooms = [];
String _fuid = "";
List<Messages> _message = <Messages>[];
int len = 0;
String _myimage = "";
Uint8List _myimageuint = Uint8List.fromList([0]);
String _friendimage = "";
Uint8List _friendimageuint = Uint8List.fromList([0]);

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
  int _lastmessage = 0;
  List<int> _checked = <int>[];
  String friendname = "";
  String frienduid = "";
  int number = -1;
  ChatRoomState(this.friendname, this.number);
  final TextEditingController _textController = TextEditingController();
  bool _exist = false;

  final authentication = FirebaseAuth.instance;
  User? loggedUser;

  void getCurrentUser() {
    try {
      final user = authentication.currentUser;
      if (user != null) {
        loggedUser = user;
      }
    } catch (e) {
      print(e);
    }
  }
  void sendNotification() async {
    final snapshot = await rootRef.child('UserList/${this.frienduid}/Token').get();
    String token = snapshot.value.toString();
    FCMController fcm = FCMController();
    fcm.sendMessage(
      body: 'From $_name',
      title: 'New Message',
      userToken: token,
    );
  }


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
    final uri = Uri.parse("https://10.0.2.2:5001/test");
    var request = http.MultipartRequest('POST', uri);
    request.fields['name'] = "test";
    var pic = await http.MultipartFile.fromPath('images', _image!.path);
    request.files.add(pic);
    var streamdresponse = await request.send();
    var response = await http.Response.fromStream(streamdresponse);

    if (response.body == "copyright") {
      _showDialogT("copyright");
    } else if (response.body == "dangerous") {
      _showDialogT("dangerous");
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

  void _outDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Are you sure you want to go out? If you leave, you cannot recover. The other party also leaves the chat room."),
            actions: <Widget>[
              new TextButton(
                  onPressed: ()async {
                    await roomOut(number);
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: new Text("YES")),
              new TextButton(
                child: new Text("No"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        }
    );
  }



  // 검열 통과 못한 경우 => "true 일 때"
  void _showDialogT(String reason) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text(reason + " Image. 전송할 수 없습니다."),
          // content: new Text("Alert Dialog body"),
          actions: <Widget>[
            new TextButton(
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
            new TextButton(
              child: new Text("Yes"),
              onPressed: () {
                _handleSubmitted(imageString);
                imageString = "";
                _image = null;
                Navigator.pop(context);
              },
            ),
            new TextButton(
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
    final snapshot2 = await ref
        .child('UserList')
        .child(FirebaseAuth.instance.currentUser!.uid.toString())
        .child('Profile_img')
        .get();
    if (snapshot2.exists) {
      setState(() {
        _myimage = snapshot2.value.toString();
        _myimageuint = base64Decode(_myimage);
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
        .child((_lastmessage).toString())
        .set({
      "checked": 1,
      "sender": _name,
      "text": encryptedMessage,
    });
    sendNotification();
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
    final snapshot =
    await ref.child('UserList').child(_fuid).child('Profile_img').get();
    if (snapshot.exists && snapshot.value != null) {
      setState(() {
        _friendimage = snapshot.value.toString();
        _friendimageuint = base64Decode(_friendimage);
      });
    }
  }

  /// 친구 프로필 사진
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

  Future<void> _friendprofile() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final snapshot =
    await ref.child('UserList').child(_fuid).child('Profile_img').get();
    if (snapshot.exists && snapshot.value != null) {
      setState(() {
        _friendimage = snapshot.value.toString();
        _friendimageuint = base64Decode(_friendimage);
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState

    Loaduser();
    _other = this.friendname;
    _searchFriend();
    // _friendprofile();
    _roomcheck();
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name,
            style:
            TextStyle(fontSize: 16, color: Theme.of(context).primaryColor)),
        automaticallyImplyLeading: true,
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            }),
        iconTheme: IconThemeData(
          color: Theme.of(context).primaryColor,
        ),
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
      ),
      endDrawer: Drawer(
          child: ListView(padding: EdgeInsets.zero, children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                _name,
                style: TextStyle(
                  letterSpacing: 1.0,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              accountEmail: Text(
                loggedUser!.email.toString(),
                style: TextStyle(
                  letterSpacing: 1.0,
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade500,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
            ),
            ListTile(
              title: Text("Member",style: TextStyle(fontSize: 20.0),),
            ),

            ListTile(
              title: Text(_name),
              leading: CircleAvatar(
                backgroundImage: MemoryImage(_myimageuint),
              ),
            ),

            ListTile(
              title: Text(friendname),
              leading : CircleAvatar(
                  backgroundImage: MemoryImage(_friendimageuint)
              ),
            ),
            Divider(),
            Container(
              height: 50,
              child : ListTile(
                  title: Text('Export data'),
                  onTap: () {
                    exportData(this.number, frienduid);
                  }),
            ),
            Container(
              height: 50,
              child: ListTile(
                title: Text('EXIT'),
                onTap: ()async {
                  _outDialog();
                },
              ),
            ),
          ])),
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
                    _lastmessage = 0;

                    if ( (snapshot.data as DatabaseEvent).snapshot.value == null) {
                      return Expanded(
                        child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "Send a new message!",
                              style: TextStyle(fontSize: 20),
                            )),
                      );
                    }
                    for (var item in (snapshot.data as DatabaseEvent)
                        .snapshot
                        .value as List<Object?>) {
                      if (item != null) {
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
                                duration: Duration(milliseconds: 0),
                                vsync: this),
                            ismine: mine,
                          );

                          if (_message.length <= k) {
                            _message.insert(0, mas);
                            mas.animationController.forward();
                            _checked.insert(0, map['checked']);
                            k += 1;
                          }
                        }
                      } else {
                        print("null");
                      }
                      _lastmessage += 1;
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
              color: Theme.of(context).primaryColor,
              tooltip: 'pick Image',
              padding: EdgeInsets.all(5),
              constraints: BoxConstraints(),
              onPressed: () {
                getImage(ImageSource.camera);
              },
            ),
            IconButton(
              icon: Icon(Icons.wallpaper),
              color: Theme.of(context).primaryColor,
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
                color: Theme.of(context).primaryColor,
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
    //print(key.bytes);
    try {
      final decrypted =
      encrypter.decrypt(encrypt.Encrypted.fromBase64(data), iv: iv);
      return decrypted;
    } catch (exception) {
      return 'error key does not match';
    }
  }

  Future<String> _getAes(String input) async {
    _aesKey = encrypt.Key.fromBase64(await getAESKey(_fuid));
    //
    // print("===========");
    // if (_aesKey == null) {
    //   print("null입니다 ");
    // } else {
    //   print("not null");
    // }
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
            ? const EdgeInsets.only(top: 10, bottom: 10, right: 5.0)
            : const EdgeInsets.only(top: 10, bottom: 10, left: 10.0),
        child: Row(
          mainAxisAlignment:
          ismine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ismine ? Container(
              margin: const EdgeInsets.only(right: 10.0),
            )
                : Container(
              margin: const EdgeInsets.only(right: 10.0),

              child: IconButton(

                padding: EdgeInsets.zero,
                icon: CircleAvatar(
                    backgroundImage: MemoryImage(_friendimageuint)
                ),
                onPressed: () {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ShowImageScreen(_friendimageuint)),);
                },
              ),

            ),
            Container(child: (() {
              return FutureBuilder<String>(
                future: _getAes(text),
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (ConnectionState.waiting == snapshot.connectionState) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.endsWith("123")) {
                    final st =
                    snapshot.data!.substring(0, snapshot.data!.length - 3);
                    final Uint8List imageBytetest = base64Decode(st);
                    // return SizedBox(
                    //   height: MediaQuery.of(context).size.height * 0.2,
                    //   width: MediaQuery.of(context).size.width * 0.5,
                    //   child: Center(
                    //     child: Image.memory(Uint8List.fromList(imageBytetest)),
                    //   ),
                    // );
                    return SizedBox(
                      // height: MediaQuery.of(context).size.height ,
                      // width: MediaQuery.of(context).size.width ,
                      child: Center(
                        child: IconButton(
                          padding: EdgeInsets.zero,

                          icon: Image.memory(Uint8List.fromList(imageBytetest)),
                          iconSize: MediaQuery.of(context).size.width * 0.4,
                          onPressed: () {
                            Navigator.push(context,
                              MaterialPageRoute(builder: (context) => ShowImageScreen(imageBytetest)),
                            );
                          },
                        ),
                      ),
                    );
                    //--------------------------------------------------------------------------------------------------
                  }
                  if (MediaQuery.of(context).size.width / 15 <
                      snapshot.data!.length) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        color: ismine
                            ? Colors.grey.shade500
                            : const Color(0xff588970),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade400,
                        ),
                      ),
                      alignment:
                      ismine ? Alignment.centerRight : Alignment.centerLeft,
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        snapshot.data!,
                        style: TextStyle(fontSize: 15.0),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        maxLines: 100,
                      ),
                    );
                  } else {
                    return Container(
                      decoration: BoxDecoration(
                        color: ismine
                            ? Colors.grey.shade500
                            : const Color(0xff588970),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade400,
                        ),
                      ),
                      alignment:
                      ismine ? Alignment.centerRight : Alignment.centerLeft,
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        snapshot.data!,
                        style: TextStyle(fontSize: 15.0),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        maxLines: 100,
                      ),
                    );
                  }
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
            })()),
          ],
        ),
      ),
    );
  }
}

Future<void> roomOut(int roomnumber) async {
  int idx = 0;

  for ( var item in rooms) {
    if (item["number"] == roomnumber) {
      rooms[idx]["number"] = -1;
      rooms[idx]["with"] = "removed";
      rooms[idx]["check"] = "removed";
      break;
    }
    idx += 1;
  }

  final DatabaseReference ref = FirebaseDatabase.instance.ref();
  await ref
      .child('UserList')
      .child(FirebaseAuth.instance.currentUser!.uid.toString())
      .child('Num_Chatroom')
      .set(rooms);

  List<Map<String, dynamic>> map2 = [];

  final snapshot = await ref.child('UserList').child(_fuid).child('Num_Chatroom').get();

  if (snapshot.exists) {
    int idx = 0;
    for (var item in (snapshot.value as List<Object?>)) {
      Map<String, dynamic> map =
      Map<String, dynamic>.from(item as Map<dynamic?, dynamic?>);
      if (map["number"] != roomnumber) {
        map2.add(map);
      } else {
        map["number"] = -1;
        map["with"] = "removed";
        map["check"] = "removed";
        map2.add(map);
      }
    }
  }

  await ref.child('UserList').child(_fuid).child('Num_Chatroom').set(map2);
}


void exportData(int roomNumber, String uid) async {
  //채팅방 메시지 복호화해서 텍스트파일로 저장

  final DatabaseReference ref = FirebaseDatabase.instance.ref();
  final snapshot = await ref.child('ChattingRoom/$roomNumber/Messages').get();
  final aeskeyforexport = encrypt.Key.fromBase64(await getAESKey(uid));
  List<List<dynamic>> temp = [];
  Directory directory = await getApplicationDocumentsDirectory();
  try {
    if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists())
        directory = (await getExternalStorageDirectory())!;
    }
  } catch (err, stack) {
    print("Cannot get download folder path");
  }

  if (snapshot.exists && snapshot.value != '') {
    for (Map<dynamic, dynamic> item
    in List<dynamic>.from(snapshot.value as List<Object?>)) {
      List<dynamic> tmp = [];

      var message = decryptData(item['text'], aeskeyforexport);
      tmp.add(item['sender']);
      tmp.add(message);
      temp.add(tmp);
    }

    String csv = const ListToCsvConverter().convert(temp);
    final pathOfTheFileToWrite = directory.path + "/exportedMessage.csv";
    File file = File(pathOfTheFileToWrite);
    await file.writeAsString(csv);
    print('export complete');
  } else {
    print('export error');
  }
}