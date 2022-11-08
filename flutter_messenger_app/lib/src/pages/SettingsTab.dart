import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_messenger_app/src/pages/MyPage.dart';

import '../../main.dart';
import 'FriendTab.dart';
import 'Login.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  _SettingsTabState createState() => _SettingsTabState();
}

var _switchValue = false;

class _SettingsTabState extends State<SettingsTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 70,
              margin: EdgeInsets.fromLTRB(3, 0, 0, 0),
              child: SwitchListTile(
                title: Text('Dark Mode',
                    style: TextStyle(
                      letterSpacing: 1.0,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    )),
                subtitle: Text(
                  _switchValue ? 'on' : 'off',
                  style: TextStyle(
                    letterSpacing: 1.0,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                value: _switchValue,
                onChanged: (bool value) {
                  setState(() {
                    _switchValue = value;
                    MyApp.themeNotifier.value =
                        MyApp.themeNotifier.value == ThemeMode.light
                            ? ThemeMode.dark
                            : ThemeMode.light;
                  });
                },
                secondary: Container(
                  width: 15,
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            Divider(),
            Container(
              height: 40,
              margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
              child: Row(
                children: [
                  Container(
                    width: 15,
                    child: Icon(
                      Icons.settings,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Container(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(30, 0, 20, 0),
                      child: Text(
                        "  Version 1.1",
                        style: TextStyle(
                          letterSpacing: 1.0,
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}
