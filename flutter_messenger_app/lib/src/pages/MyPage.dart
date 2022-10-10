import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_messenger_app/src/pages/Login.dart';

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final authentication = FirebaseAuth.instance;
  User? loggedUser;

  String userName = '';
  String userEmail = '';
  bool userNameChecked = false;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
      body: SingleChildScrollView(
        child: Form(
          key: this.formKey,
          child: Column(
            children: [
              showUserNameInput(),
              ChangeUserNameBtn(),
              ButtonLine(),
            ]
          )
        )
      )
    );
  }

  Widget showUserNameInput() {
    return Padding(padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
        child: Column(
          children: [
            Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Username to change',
                  ),
                  validator: (value) {
                    if (value!.isEmpty || value.length < 4) {
                      userNameChecked = false;
                      return 'Please enter at least 4 characters';
                    }
                    userNameChecked = true;
                    return null;
                    },
                    onSaved: (value) { userName = value!; },
                    onChanged: (value) { userName = value; },
                )),
          ],
        ));
  }

  Widget ChangeUserNameBtn() {
    return Padding(padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            //primary: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3.0)
            ),
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text('Change Username', style: TextStyle(fontSize: 20)),
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              formKey.currentState!.save();

              final DatabaseReference ref = FirebaseDatabase
                  .instance.ref("UserList");
              ref.child(loggedUser!.uid.toString()).update({
                "Name": userName,
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Username is changed!'),
                  duration: Duration(seconds: 5),)
              );
            }
          },
        ),
    );
  }

  Widget ChangePasswordBtn() {
    return Padding(padding: EdgeInsets.only(top: 20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            //primary: Colors.orange,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.0)
            ),
            //minimumSize: const Size.fromHeight(50),
          ),
          child: Text('Change Password', style: TextStyle(fontSize: 16)),
          onPressed: () async {
            return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Color(0xff161619),
                    title: Text(
                      'Do you want to change your password? You can change your password via a message sent by email.',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () async {
                            await authentication.sendPasswordResetEmail(email: loggedUser!.email.toString());
                            authentication.signOut();
                            Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()),);
                          },
                          child: Text('Yes')),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('No')),
                    ],
                  );
                });
            },
        ));
  }

  Widget WithdrawalAccountBtn() {
    return Padding(padding: EdgeInsets.only(top: 20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            //primary: Colors.orange,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.0)
            ),
            //minimumSize: const Size.fromHeight(50),
          ),
          child: Text('Withdrawal', style: TextStyle(fontSize: 16)),
          onPressed: () async {
            return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Color(0xff161619),
                    title: Text(
                      'Do you want to withdrawal your account?',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () async {
                            await authentication.currentUser?.delete();
                            final DatabaseReference ref = FirebaseDatabase.instance.ref("UserList");
                            ref.child(loggedUser!.uid.toString()).remove();
                            Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()),);
                          },
                          child: Text('Yes')),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('No')),
                    ],
                  );
                });
          },
        ));
  }

  Widget ButtonLine() {
    return Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ChangePasswordBtn(),
          WithdrawalAccountBtn(),
        ],
      )
    );
  }
}