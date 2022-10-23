import 'dart:convert';
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

class _FriendTabState extends State<FriendTab> {
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
  List<Friend> myFriendList = [];
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  final storage = const FlutterSecureStorage();
  Uint8List tempbytes = Uint8List(10);

  void initState() {
    _getFriend();
  }

  Future<void> temp1() async {
    final aesKey =
        encrypt.Key.fromBase64(await getAESKey('STnBBGCGJNOjQqtmnFAt7Al1HQM2'));
    final encryptedBase64 =
        await encryptData('this is the plain text to be encrypted', aesKey);
    rootRef.child('UserList/$myUid').update({'Test': encryptedBase64});
  }

  Future<void> temp2() async {
    await onLogout();
    final encryptedSnapshot = await rootRef.child('UserList/$myUid/Test').get();
    final encryptedBase64 = encryptedSnapshot.value.toString();
    final aesKey =
        encrypt.Key.fromBase64(await getAESKey('STnBBGCGJNOjQqtmnFAt7Al1HQM2'));
    final decrypteddata = decryptData(encryptedBase64, aesKey);
    print(decrypteddata);
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
                height: 500, width: 200, child: _buildListView(myFriendList)),
            TextButton(
                onPressed: onSignUp, child: Text('onSignUp(generate Keypair)')),
            TextButton(onPressed: temp1, child: Text('generateAESKey')),
            TextButton(onPressed: temp2, child: Text('getkey'))
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
        final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
        /*새 채팅방*/
        final myUid = FirebaseAuth.instance.currentUser?.uid;
        final storage = FlutterSecureStorage();

        /* check duplicates*/
        DatabaseReference ref = FirebaseDatabase.instance.ref();
        Query query = ref
            .child('UserList/$myUid/Num_Chatroom')
            .orderByChild('with')
            .equalTo(_friend.name);
        DataSnapshot event = await query.get();

        if (event.exists) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ChatRoom(_friend.name,
                  int.parse(event.children.elementAt(0).key.toString()))));
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
            'check': [myname],
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
            'check': [myname],
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
            'Messages': {
              '0': {'checked': 1, 'sender': myname, 'text': 'none'}
            }
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
  Friend(this.uid, this.name);
}

Future<String> getAESKey(String friendUid) async {
  final storage = FlutterSecureStorage();
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  final algorithmDF = X25519();
  var sharedAESKey = await storage.read(key: friendUid);

  /*저장된 키 있을경우 secure storage에서 복원 */
  if (sharedAESKey != null) {
    print('get aes key fromstorage');
    return sharedAESKey;
  }
  /* 없을경우 Diffie-Hellman으로 생성 */
  print('generate aes key from diffie-hellman');
  final myPrivateKey = base64Decode(await getPrivateKey());

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
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
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

Future<void> onLogout() async {
  final storage = FlutterSecureStorage();
  await storage.deleteAll();
}

Future<void> onSignUp() async {
  final storage = FlutterSecureStorage();
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  String password = 'testpassword';

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

Future<String> getPrivateKey() async {
  final storage = FlutterSecureStorage();
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  String password = 'testpassword';
  final myPrivateKey = await storage.read(key: 'myPrivateKey');

  /* secure storage에 존재할 경우 */
  if (myPrivateKey != null) {
    print('get private key from secure storage');
    return myPrivateKey;

    /* get from server and decrypt */
  } else {
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
  print('encrypted : ${encrypted.base64}');
  encrypt.Encrypted temp = encrypt.Encrypted.fromBase64(encrypted.base64);
  final decrypted = encrypter.decrypt(temp, iv: iv);

  print(decrypted);

  return encrypted.base64;
}
