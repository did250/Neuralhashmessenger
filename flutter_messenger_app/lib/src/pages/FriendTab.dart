import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'SearchFriendTab.dart';
import 'ChatRoom.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class FriendTab extends StatefulWidget {
  @override
  _FriendTabState createState() => _FriendTabState();
}

final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
const storage = FlutterSecureStorage();

class _FriendTabState extends State<FriendTab> {
  final myUid = FirebaseAuth.instance.currentUser!.uid;
  List<Friend> myFriendList = [];

  void addtestfriend() async {
    final newPostKey = rootRef.child("UserList/$myUid/Friend").push().key;
    rootRef.child("UserList/$myUid/Friend/$newPostKey").update(
        {'Uid': '$newPostKey data', 'Name': Random().nextInt(100).toString()});
  }

  void gettestfriend() async {
    final snapshot = await rootRef.child('UserList/$myUid/Friend').get();

    for (var element in snapshot.children) {
      print(element.child('Uid').value);
      print(element.child("Name").value);
    }
  }

  Future<void> _addFriend(Map friend) async {
    final newPostKey = rootRef.child("UserList/$myUid/Friend").push().key;
    rootRef.child("UserList/$myUid/Friend/$newPostKey").update({
      'Uid': friend['Uid'],
      'Name': friend['Name'],
      'Profile': friend['Profile']
    });
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
    return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              StreamBuilder(
                  stream: FirebaseDatabase.instance
                      .ref()
                      .child('UserList/$myUid/Friend')
                      .onValue,
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.hasData) {
                      myFriendList = [];
                      for (var element in (snapshot.data as DatabaseEvent)
                          .snapshot
                          .children) {
                        final uid = element.child('Uid').value.toString();
                        final name = element.child('Name').value.toString();
                        final profile =
                            element.child('Profile').value.toString();
                        myFriendList.add(Friend(uid, name, profile));
                      }
                    }
                    return Container(
                        height: 500,
                        width: 420,
                        child: _buildListView(myFriendList));
                  }),
              TextButton(
                  onPressed: () {
                    addtestfriend();
                  },
                  child: Text('add friend test button')),
              TextButton(
                  onPressed: gettestfriend, child: Text('gettestfriend')),
              //TextButton(onPressed: temp2, child: Text('getkey')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(
            Icons.add,
          ),
          backgroundColor: Colors.deepPurpleAccent.shade200,
          onPressed: () async {
            Map result = await Navigator.push(context,
                MaterialPageRoute(builder: (context) => SearchFriendTab()));
            if (result['Uid'] == 'error') {
              print('error');
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
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return ListTile(
      leading: CircleAvatar(radius: 25.0, backgroundImage: MemoryImage(
          Uint8List.fromList(base64Decode(_friend.profile_img.toString())))),
      title: Container(
        height: 53,
        alignment: Alignment.centerLeft,
        child: Text(
          _friend.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () async {
        /*새 채팅방*/

        /* check duplicates*/
        DatabaseReference ref = FirebaseDatabase.instance.ref();
        Query query = ref
            .child('UserList/$myUid/Num_Chatroom')
            .orderByChild('with')
            .equalTo(_friend.name);
        DataSnapshot event = await query.get();

        if (event.exists) {
          int roomnum = int.parse(
              event.children.elementAt(0).child('number').value.toString());
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ChatRoom(_friend.name, roomnum)));
          print("chatroom already exists");
          return;
        }

        /* generate AES Key */
        await getAESKey(_friend.uid);

        /* generate new chatroom */
        final snapshotChat = await rootRef.child('ChattingRoom/next').get();
        int nextnumChatroom;
        if (snapshotChat.exists) {
          nextnumChatroom = int.parse(snapshotChat.value.toString());
        } else {
          nextnumChatroom = 0;
        }

        final snapshotLocal = await rootRef.child('UserList/$myUid').get();
        final snapshotRemote =
            await rootRef.child('UserList/${_friend.uid}').get();
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
            'with': _friend.name,
          }
        });
        nextnumLocal++;
        await rootRef
            .child('UserList/$myUid')
            .update({'Next_Chatroom': nextnumLocal});

        /* remote userlist update*/
        await rootRef.child('UserList/${_friend.uid}/Num_Chatroom').update({
          '$nextnumRemote': {
            'check': _friend.name,
            'number': nextnumChatroom,
            'with': myname,
          }
        });
        nextnumRemote++;
        await rootRef
            .child('UserList/${_friend.uid}')
            .update({'Next_Chatroom': nextnumRemote});

        /* ChattingRoom update */
        rootRef.child('ChattingRoom').update({
          '$nextnumChatroom': {
            'Members': {
              '0': myname,
              '1': _friend.name,
            },
            // 'Messages': {
            //   '0': {'checked': 1, 'sender': 'none', 'text': 'none'}
            // }
          }
        });
        nextnumChatroom++;
        await rootRef.child('ChattingRoom').update({'next': nextnumChatroom});

        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ChatRoom(_friend.name, nextnumChatroom - 1)));
      },
    );
  }
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
