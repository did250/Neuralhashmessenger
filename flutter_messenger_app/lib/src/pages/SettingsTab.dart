import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_messenger_app/src/pages/MyPage.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final authentication = FirebaseAuth.instance;
  User? loggedUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = authentication.currentUser;
      if (user != null) {
        loggedUser = user;
      }
    }catch(e){
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loggedUser!.email.toString()),
        actions: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app_sharp,
              color: Colors.white,
            ),
            onPressed: () {
              authentication.signOut();
            },
          )
        ],
      ),
      body: ListView(
          children: <Widget>[
            ListTile(
              title: Text('MyPage'),
              leading: Icon(Icons.settings),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) { return MyPage(); },),),
            ),
            ListTile(
              title: Text('example'),
            ),
        ],
      ),
    );
  }
}
