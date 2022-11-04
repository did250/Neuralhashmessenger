import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:focused_menu/modals.dart';
import 'SearchFriendTab.dart';
import 'ChatRoom.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:focused_menu/focused_menu.dart';
import 'package:http/http.dart' as http;

List<Friend> myFriendList = [];

class FriendTab extends StatefulWidget {
  @override
  _FriendTabState createState() => _FriendTabState();
}

final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
const storage = FlutterSecureStorage();

class _FriendTabState extends State<FriendTab>
    with AutomaticKeepAliveClientMixin {
  final myUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

  @override
  void initState() {
    // TODO: implement initState
    _refreshFriendList();

    super.initState();
  }

  void _refreshFriendList() async {
    myFriendList = [];
    final snapshot = await rootRef.child('UserList/$myUid/Friend').get();

    for (var element in snapshot.children) {
      myFriendList.add(Friend(
          element.child('Uid').value.toString(),
          element.child('Name').value.toString(),
          element.child('Profile').value.toString()));
      print(element.child('Uid').value);
      print(element.child("Name").value);
    }
    setState(() {});
  }

  void _addFriend(Map friend) {
    final newPostKey = rootRef.child("UserList/$myUid/Friend").push().key;
    myFriendList.add(Friend(friend['Uid'], friend['Name'], friend['Profile']));
    setState(() {});
    rootRef.child("UserList/$myUid/Friend/$newPostKey").update({
      'Uid': friend['Uid'],
      'Name': friend['Name'],
      'Profile': friend['Profile']
    });
  }

  void _deleteFriend(int index) async {
    myFriendList.removeAt(index);
    final snapshot = await rootRef.child('UserList/$myUid/Friend').get();
    var key = snapshot.children.elementAt(index).key;

    await rootRef.child('UserList/$myUid/Friend/$key').remove();

    setState(() {});
  }

  Future<String> _getProfileImgFromUid(String uid) async {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('UserList/$uid/Profile_img');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return snapshot.value.toString();
    } else {
      return "null";
    }
  }

  Widget build(BuildContext context) {
    var _tapPosition;
    return Scaffold(
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[],
                  ),
                ),
              ),
              ListView.separated(
                padding: EdgeInsets.only(top: 15),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: myFriendList.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(),
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                      onLongPress: () {},
                      /*onTap: () => newChatroom(context, myFriendList[index].name,
                        myFriendList[index].uid),*/
                      child: FocusedMenuHolder(
                          menuWidth: MediaQuery.of(context).size.width * 0.5,
                          blurSize: 5,
                          blurBackgroundColor: Colors.black,
                          openWithTap: true,
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                                backgroundImage: MemoryImage(Uint8List.fromList(
                                    base64Decode(myFriendList[index]
                                        .profile_img
                                        .toString())))),
                            title: Text(
                              myFriendList[index].name,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          onPressed: () {},
                          menuItems: <FocusedMenuItem>[
                            FocusedMenuItem(
                                title: Text('New Chat'),
                                trailingIcon: Icon(Icons.chat_bubble),
                                onPressed: () => newChatroom(
                                    context,
                                    myFriendList[index].name,
                                    myFriendList[index].uid)),
                            FocusedMenuItem(
                                title: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.white),
                                ),
                                trailingIcon:
                                    Icon(Icons.delete, color: Colors.white),
                                backgroundColor: Colors.redAccent,
                                onPressed: () => _deleteFriend(index)),
                          ]));
                },
              ),
              TextButton(
                  onPressed: () {
                    FCMController fcm = FCMController();
                    fcm.sendMessage(
                      body: 'message',
                      title: 'Title',
                      userToken:
                          'fRb2HxbOR060nWcOvEhZU2:APA91bHwKO4X4-_iX2fNqzN5sfHnXalAqV-J9N9A2IcarfUXOqnmsXPabXUjODLYZ5dw5xB7bN2LXfQCa2nGXNH6-OPY1kTDV9UfpGlk0MOkSgq4qzUd_Hw3FSfz121VF2eiDvPzQqg5',
                    );
                    print('sent message!');
                  },
                  child: Text('testbutton')),
              TextButton(
                  onPressed: () {
                    FCMController fcm = FCMController();
                    fcm.sendMessage(
                      body: 'a',
                      title: 'b',
                      userToken:
                          'fdo0VhST1qZTsXux67fDC9:APA91bHTBkZgKw9A6Rmx0gBEXR0Fb8fcCRpNWCi22JeTqfTgePoKIfWbGdo4JE6qNtOhTWtekrN0KcMXP-V00lC5ugyJqLzh5yHywe_9y77jTMz18uWYWkePHUYGfIqvNbSOO7I6oXDS',
                    );
                    print('sent message!');
                  },
                  child: Text('testbutton')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(
            Icons.add,
          ),
          backgroundColor: const Color(0xff588970),
          onPressed: () async {
            Map result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SearchFriendTab(myFriendList)));
            if (result['Uid'] == 'error') {
              print('error');
            } else {
              _addFriend(result);
            }
          },
        ));
  }
}

void newChatroom(
  BuildContext context,
  String friendName,
  String friendUid,
) async {
  final myUid = FirebaseAuth.instance.currentUser!.uid;
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  Query query = ref
      .child('UserList/$myUid/Num_Chatroom')
      .orderByChild('with')
      .equalTo(friendName);
  DataSnapshot event = await query.get();

  if (event.exists) {
    int roomnum =
        int.parse(event.children.elementAt(0).child('number').value.toString());
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => ChatRoom(friendName, roomnum)));
    print("chatroom already exists");
    return;
  }

  /* generate AES Key */
  await getAESKey(friendUid);
  /* generate new chatroom */
  final snapshotChat = await rootRef.child('ChattingRoom/next').get();
  int nextnumChatroom;
  if (snapshotChat.exists) {
    nextnumChatroom = int.parse(snapshotChat.value.toString());
  } else {
    nextnumChatroom = 0;
  }

  final snapshotLocal = await rootRef.child('UserList/$myUid').get();
  final snapshotRemote = await rootRef.child('UserList/$friendUid').get();
  String myname = snapshotLocal.child('Name').value.toString();

  /* get next number of each user's chatroom*/
  int nextnumLocal =
      int.parse(snapshotLocal.child('Next_Chatroom').value.toString());
  int nextnumRemote =
      int.parse(snapshotRemote.child('Next_Chatroom').value.toString());

  /* local userlist update */
  await rootRef.child('UserList/$myUid/Num_Chatroom').update({
    '$nextnumLocal': {
      'check': myname,
      'number': nextnumChatroom,
      'with': friendName,
    }
  });
  nextnumLocal++;
  await rootRef
      .child('UserList/$myUid')
      .update({'Next_Chatroom': nextnumLocal});

  /* remote userlist update*/
  await rootRef.child('UserList/$friendUid/Num_Chatroom').update({
    '$nextnumRemote': {
      'check': friendName,
      'number': nextnumChatroom,
      'with': myname,
    }
  });
  nextnumRemote++;
  await rootRef
      .child('UserList/$friendUid')
      .update({'Next_Chatroom': nextnumRemote});

  /* ChattingRoom update */
  rootRef.child('ChattingRoom').update({
    '$nextnumChatroom': {
      'Members': {
        '0': myname,
        '1': friendName,
      },
    }
  });
  nextnumChatroom++;
  await rootRef.child('ChattingRoom').update({'next': nextnumChatroom});

  Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChatRoom(friendName, nextnumChatroom - 1)));
}

class Friend {
  String uid;
  String name;
  String profile_img;
  Friend(this.uid, this.name, this.profile_img);
}

Future<String> getAESKey(String friendUid) async {
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  final algorithmDF = X25519();
  var sharedAESKey = await storage.read(key: friendUid);

  /*저장된 키 있을경우 secure storage에서 복원 */
  if (sharedAESKey != null) {
    print('get aes key from local storage');
    return sharedAESKey;
  }
  /* 없을경우 Diffie-Hellman으로 생성 */
  print('generate aes key from diffie-hellman');
  final password = (await storage.read(key: 'prefPassword'))!;
  final encodedPrivateKey = await getPrivateKey(password);
  print('encoded private key : ' + encodedPrivateKey);

  final myPrivateKey = base64Decode(encodedPrivateKey);

  final reomotePublicKeySnapshot =
      await rootRef.child('UserList/$friendUid/PublicKey').get();
  final myPublicKeySnapshot =
      await rootRef.child('UserList/$myUid/PublicKey').get();
  if (!reomotePublicKeySnapshot.exists || !myPublicKeySnapshot.exists) {
    //
  }
  final remotePublicKey = SimplePublicKey(
      base64Decode(reomotePublicKeySnapshot.value.toString()),
      type: KeyPairType.x25519);
  final myPublicKey = SimplePublicKey(
      base64Decode(myPublicKeySnapshot.value.toString()),
      type: KeyPairType.x25519);

  final myKeyPair = SimpleKeyPairData(myPrivateKey,
      publicKey: myPublicKey, type: KeyPairType.x25519);

  final sharedSecret = await algorithmDF.sharedSecretKey(
    keyPair: myKeyPair,
    remotePublicKey: remotePublicKey,
  );
  final sharedSecretKeyBytes = await sharedSecret.extractBytes();
  //print('sharedSecretKeyBytes : ' + sharedSecretKeyBytes.toString());
  await storage.write(
      key: friendUid, value: base64Encode(sharedSecretKeyBytes));

  return base64Encode(sharedSecretKeyBytes);
}

Future<encrypt.Key> generatePbkdf2(String password, Uint8List salt) async {
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 1000,
    bits: 256,
  );
  /* generate secretKey from password */
  final secretKeyFromPass = SecretKey(utf8.encode(password));

  /* generated pbkdf2 from password, salt */
  //int temp = DateTime.now().millisecondsSinceEpoch;
  final generatedPbkdf2 = await pbkdf2.deriveKey(
    secretKey: secretKeyFromPass,
    nonce: salt,
  );
  //print((DateTime.now().millisecondsSinceEpoch - temp));
  //print(await generatedPbkdf2.extractBytes());
  //save salt in server
  await rootRef.child('UserList/$myUid').update({
    'Salt': base64.encode(salt),
  });
  return encrypt.Key.fromBase64(
      base64Encode(await generatedPbkdf2.extractBytes()));
}

Future<void> onLogOut() async {
  await storage.deleteAll();
}

void onSignUp(String password) async {
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  final myKeyPair = await generateECDHKey();
  final myPublicKey = await myKeyPair.extractPublicKey();
  final myPrivateKey = await myKeyPair.extractPrivateKeyBytes();

  final salt = encrypt.IV.fromSecureRandom(8).bytes;

  final keyFromPass = await generatePbkdf2(password, salt);

  final encrypter = encrypt.Encrypter(encrypt.AES(keyFromPass));
  final iv = encrypt.IV.fromLength(16);

  final encrypted = encrypter.encrypt(base64Encode(myPrivateKey), iv: iv);
  await rootRef.child('UserList/$myUid').update({
    'PublicKey': base64Encode(myPublicKey.bytes),
    'PrivateKey': encrypted.base64,
    'Salt': base64Encode(salt),
  });
  await storage.write(key: 'myPrivateKey', value: base64Encode(myPrivateKey));
}

Future<String> getPrivateKey(String password) async {
  final myPrivateKey = await storage.read(key: 'myPrivateKey');

  /* secure storage에 존재할 경우 */
  if (myPrivateKey != null) {
    print('get private key from secure storage');
    return myPrivateKey;

    /* get from server and decrypt */
  } else {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    print('get encrypted private key from server');
    final myRef = await rootRef.child('UserList/$myUid').get();

    final encryptedPrivateKey = myRef.child('PrivateKey').value.toString();
    final salt = myRef.child('Salt').value.toString();
    final iv = encrypt.IV.fromLength(16);

    final keyFromPass = await generatePbkdf2(password, base64Decode(salt));

    final encrypter = encrypt.Encrypter(encrypt.AES(keyFromPass));

    final decrypted = encrypter
        .decrypt(encrypt.Encrypted.fromBase64(encryptedPrivateKey), iv: iv);

    await storage.write(key: 'myPrivateKey', value: decrypted);

    return decrypted;
  }
}

Future<SimpleKeyPair> generateECDHKey() async {
  final algorithmDF = X25519();
  final myKeyPair = await algorithmDF.newKeyPair();

  return myKeyPair;
}

Future<String> encryptData(String data, encrypt.Key aesKey) async {
  final iv = encrypt.IV.fromLength(16);

  final encrypter = encrypt.Encrypter(encrypt.AES(aesKey));

  final encrypted = encrypter.encrypt(data, iv: iv);
  encrypt.Encrypted temp = encrypt.Encrypted.fromBase64(encrypted.base64);
  final decrypted = encrypter.decrypt(temp, iv: iv);

  return encrypted.base64;
}

String decryptData(String data, encrypt.Key key) {
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

class FCMController {
  final String _serverKey =
      "AAAAjOe102k:APA91bEnTo4xCQYgiXvJJMYs85W7xrCEzwaM-aC-B8Dh9cAZ7_81Lxg5b-HaXtq4uCVNnAa2oCJlOrONFriqbsyvJ1fBPnPlJUfqKouNhP3b4DyIneYiz5QA2wg10vbqWbEiv4YQTmW9";

  Future<void> sendMessage({
    required String userToken,
    required String title,
    required String body,
  }) async {
    http.Response response;

    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    try {
      response = await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'key=$_serverKey'
          },
          body: jsonEncode({
            'notification': {'title': title, 'body': body, 'sound': 'true'},
            'ttl': '60s',
            "content_available": true,
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
              "action": '테스트',
            },
            // 상대방 토큰 값, to -> 단일, registration_ids -> 여러명
            'to': userToken
            // 'registration_ids': tokenList
          }));
    } catch (e) {
      print('error $e');
    }
  }
}
