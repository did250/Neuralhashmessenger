import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_messenger_app/src/pages/Login.dart';
import 'package:flutter_messenger_app/src/pages/FriendTab.dart';
import 'package:flutter_messenger_app/src/pages/ChatTab.dart';
import 'package:flutter_messenger_app/src/pages/MyPage.dart';

import '../../main.dart';

final notifications = FlutterLocalNotificationsPlugin();

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
            if (!snapshot.hasData) {
              //new User
              return LoginScreen();
            } else {
              //Login
              return MainPage();
            }
          },
        ),
      ),
    );
  }
}


class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPage();
}

class _MainPage extends State<MainPage> {
  int _selectedIndex = 0;

  final authentication = FirebaseAuth.instance;


  @override
  void initState() {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    final token = FirebaseMessaging.instance.getToken();
    rootRef.child('UserList/$myUid').update({'Token' : token});

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('onmessage');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      var androidNotiDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
      );
      var iOSNotiDetails = const DarwinNotificationDetails();
      var details =
      NotificationDetails(android: androidNotiDetails, iOS: iOSNotiDetails);
      if (notification != null) {
        notifications.show(1, notification.title, notification.body, details);
      }
    });


    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print(message);
    });
    super.initState();

  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getPageData() {
    if (_selectedIndex == 0) {
      return FriendTab();
    } else if (_selectedIndex == 1) {
      return ChatTab();
    } else {
      return MyPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Theme.of(context).primaryColor, //색변경
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 150,
                  height: 100,
                  alignment: Alignment.center,
                  child: Image(
                    image: AssetImage('assets/images/logo.png'),
                  )),
            ],
          ),
          backgroundColor: Theme.of(context).canvasColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                Icons.exit_to_app_sharp,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () async {
                authentication.signOut();
                await onLogOut();
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            )
          ],
        ),
        body: _getPageData(),
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Theme.of(context).primaryColor,
          type: BottomNavigationBarType.fixed,
          unselectedItemColor: Colors.grey,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.contact_page),
              label: 'Contact',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Account',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
      onWillPop: () async => false,
    );
  }
}