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
      appBar: AppBar(
        title: Text("MyPage"),
        iconTheme: IconThemeData(color: Color(0xFF09126C)),
        backgroundColor: Color(0xFFB6C7D1),
        actions: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app_sharp,
              color: Colors.white,
            ),
            onPressed: () {
              authentication.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              Navigator.push(context, MaterialPageRoute(builder: (context) => LoginSignupScreen()),);
            },
          )
        ],
      ),
      body: new Form(
        key: formKey,
        child: Column(
          children: [
            showUserNameInput(),
            //ChangeUserNameBtn(),
            ChangePasswordBtn(),
            WithdrawalAccountBtn(),
          ],
        ),
      ),
    );
  }

  InputDecoration _textFormDecoration(hintText, helperText){
    return new InputDecoration(
      contentPadding: EdgeInsets.fromLTRB(0, 16, 0, 0),
      hintText: hintText,
      helperText: helperText,
    );
  }

  Widget showUserNameInput() {
    return Padding(padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
        child: Column(
          children: [
            Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: TextFormField(
                  decoration: _textFormDecoration('Username to change', ''),
                  validator: (value) {
                    if (value!.isEmpty || value.length < 4) {
                      userNameChecked = false;
                      return 'Please enter at least 4 characters';
                    }
                    userNameChecked = true;
                    return null;
                  },
                  onSaved: (value) {
                    userName = value!;
                  },
                  onChanged: (value) {
                    userName = value;
                  },
                )),
          ],
        ));
  }

  /*Widget ChangeUserNameBtn() {
    return Padding(padding: EdgeInsets.only(top: 20),
        child: MaterialButton(
          height: 50,
          child: Text('Change Username'),
          onPressed: () async {
              return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Color(0xff161619),
                      title: Text(
                        'Do you want to change your username?',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () async {
                              formKey.currentState?.validate();
                              final DatabaseReference ref = FirebaseDatabase
                                  .instance.ref("UserList");
                              ref.child(loggedUser!.uid.toString()).update({
                                "Name": userName,
                              });
                              Navigator.pop(context);
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
  }*/

  Widget ChangePasswordBtn() {
    return Padding(padding: EdgeInsets.only(top: 40),
        child: MaterialButton(
          height: 50,
          child: Text('Change Password'),
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
                            Navigator.push(context, MaterialPageRoute(builder: (context) => LoginSignupScreen()),);
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
    return Padding(padding: EdgeInsets.only(top: 60),
        child: MaterialButton(
          height: 50,
          child: Text('Withdrawal'),
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
                            Navigator.push(context, MaterialPageRoute(builder: (context) => LoginSignupScreen()),);
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
}