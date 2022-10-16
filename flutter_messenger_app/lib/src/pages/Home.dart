import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_messenger_app/src/pages/Login.dart';
import 'package:flutter_messenger_app/src/pages/FriendTab.dart';
import 'package:flutter_messenger_app/src/pages/ChatTab.dart';
import 'package:flutter_messenger_app/src/pages/MyPage.dart';
import 'package:flutter_messenger_app/src/pages/SettingsTab.dart';
import 'package:flutter_messenger_app/src/pages/Signup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
            if (!snapshot.hasData) { //new User
              return LoginScreen();
            } else { //Login
              return MainPage();
              /*return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("${snapshot.data?.displayName}님 반갑습니다."),
                  ],
                ),
              );*/
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
    return Scaffold(
      appBar: AppBar(
        title: Text("MainPage"),
        actions: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app_sharp,
              color: Colors.white,
            ),
            onPressed: () async {
              authentication.signOut();

              SharedPreferences pref = await SharedPreferences.getInstance();
              pref.clear();

              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()),);
            },
          )
        ],
      ),
      body: _getPageData(),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_page),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'MyPage',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}