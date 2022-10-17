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

  Future<void> _firstTime() async {
    final algorithmDF = X25519();

    var myPrivateKey = await storage.read(key: 'private_$myUid');
    final myPublicKeySnapshot =
        await rootRef.child('UserList/$myUid/PublicKey').get();

    if (myPrivateKey == null || !myPublicKeySnapshot.exists) {
      final myKeyPair = await algorithmDF.newKeyPair();
      final myPublicKey = await myKeyPair.extractPublicKey();
      final myPrivateKey = await myKeyPair.extractPrivateKeyBytes();
      // secure storage에 private key 저장, firebase에 public key 저장
      await storage.write(
          key: 'private_${myUid!}', value: base64Encode(myPrivateKey));
      await rootRef
          .child('UserList/$myUid')
          .update({'PublicKey': base64Encode(myPublicKey.bytes)});
    } else {
      print(myPrivateKey);
    }
  }

  Future<void> _generateAESKey() async {
    final algorithmDF = X25519();
    final myPrivateKey =
        base64Decode((await storage.read(key: 'private_${myUid!}'))!);
    /* 임시 */
    var friendUid = myUid;
    final reomotePublicKeySnapshot =
        await rootRef.child('UserList/$friendUid/PublicKey').get();
    final myPublicKeySnapshot =
        await rootRef.child('UserList/$myUid/PublicKey').get();
    if (!reomotePublicKeySnapshot.exists || !myPublicKeySnapshot.exists) {
      return;
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
    print('sharedSecretKeyBytes : ' + sharedSecretKeyBytes.toString());
    await storage.write(
        key: '$friendUid', value: base64Encode(sharedSecretKeyBytes));
  }

  Future<void> _sendMessage() async {
    var friendUid = '임시uid';
    // Choose the cipher
    final message = utf8.encode('message');
    final algorithmAes = AesCtr.with256bits(macAlgorithm: Hmac.sha256());
    var storageData = await storage.read(key: friendUid) ?? 'null';
    var tempSecretKey = await algorithmAes.newSecretKey();

    /* This is for test */
    if (storageData == 'null') {
      tempSecretKey = await algorithmAes.newSecretKey();

      final encryptedBox = await algorithmAes.encrypt(
        message,
        secretKey: tempSecretKey,
      );
      var newString = base64Encode(encryptedBox.nonce) +
          " " +
          base64Encode(encryptedBox.cipherText) +
          " " +
          base64Encode(encryptedBox.mac.bytes);
      print(newString);

      var strings = newString.split(' ');
      print(strings[0]);
      print(strings[1]);
      print(strings[2]);
    } else {
      storageData = (await storage.read(key: friendUid))!;
      final savedKeyBytes = base64Decode(storageData);

      final encryptedBox = await algorithmAes.encrypt(
        message,
        secretKey: SecretKey(savedKeyBytes),
      );
      var newString = base64Encode(encryptedBox.nonce) +
          " " +
          base64Encode(encryptedBox.cipherText) +
          " " +
          base64Encode(encryptedBox.mac.bytes);
      print(newString);
    }
  }

  Future<void> _encryptTest() async {
    var friendUid = myUid; //임시 제거필요
    /*****암호화 통신***** */
    // Choose the cipher
    final message = utf8.encode('Hello encryption!');
    final algorithmAes = AesCtr.with256bits(macAlgorithm: Hmac.sha256());
    final testkey = algorithmAes.newSecretKey();

    final storageData = await storage.read(key: friendUid!);

    final SecretKey secretKey;
    if (storageData == null) {
      secretKey = await algorithmAes.newSecretKey();
    } else {
      secretKey = SecretKey(base64Decode(storageData)); //채팅방 번호로?

    }

    /******** Encrypt **********/
    final secretBox = await algorithmAes.encrypt(
      message,
      secretKey: secretKey,
    );

    print('Nonce: ${secretBox.nonce}');
    print('Ciphertext: ${secretBox.cipherText}');
    print('MAC: ${secretBox.mac.bytes}');

    /******** Decrypt **********/
  }

  Future<void> _decrypt() async {
    String encryptedString = 'a b c';
    var strings = encryptedString.split(' ');
    final algorithmAes = AesCtr.with256bits(macAlgorithm: Hmac.sha256());

    final remoteSecretBox = SecretBox(base64Decode(strings[1]),
        nonce: base64Decode(strings[0]), mac: Mac(base64Decode(strings[2])));
    final clearText = await algorithmAes.decrypt(
      remoteSecretBox,
      secretKey: SecretKey(base64Decode((await storage.read(key: '친구 uid'))!)),
    );

    remoteSecretBox.toString();
    print('Cleartext: ${utf8.decode(clearText)}');
    print(remoteSecretBox.toString());
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
                height: 500, width: 200, child: _buildListView(myFriendList))
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            /*
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (context) => SearchFriendTab()));
            if (result == 'error') {
              print('error');
            } else {
              print(result);
              await _addFriend(result);
              _getFriend();
            }*/
            _firstTime();
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
        final algorithmDF = X25519();
        final myPrivateKey =
            base64Decode((await storage.read(key: 'private_${myUid!}'))!);
        final reomotePublicKeySnapshot =
            await rootRef.child('UserList/${_friend.uid}/PublicKey').get();
        final myPublicKeySnapshot =
            await rootRef.child('UserList/$myUid/PublicKey').get();
        if (!reomotePublicKeySnapshot.exists || !myPublicKeySnapshot.exists) {
          print('error remotepublic key or my public key does not exist');
          return;
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
            key: _friend.uid, value: base64Encode(sharedSecretKeyBytes));

        print(await storage.read(key: _friend.uid));

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
