import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsTab extends StatefulWidget {
  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: TextButton(
            child: Text("로그아웃"),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ),
      ),
    );
  }
}
