import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_messenger_app/src/pages/Home.dart';
import 'package:flutter_messenger_app/src/pages/Signup.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authentication = FirebaseAuth.instance;

  User? loggedUser;

  final formKey = GlobalKey<FormState>();
  String userEmail = '';
  String userPassword = '';

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    final UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(credential);

    final String? uid = authResult.user?.uid;
    final String? gmail = authResult.user?.email;
    final String? displayName = authResult.user?.displayName;

    DatabaseReference ref = FirebaseDatabase.instance.ref("UserList/" + uid.toString());

    await ref.set({
      "Email": gmail,
      "Name": displayName,
      "Friend": "",
      "Num_Chatroom": "",
    });

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECF3F9),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(top: 200),
          padding: EdgeInsets.all(30),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 50,
                  width: 400,
                  alignment: Alignment.topCenter,
                  child: Text("LOGIN",
                    style: TextStyle(
                      letterSpacing: 1.0,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF09126C),
                    ),
                  ),
                ),

                TextFormField(
                  key: ValueKey(4),
                  validator: (value) {
                    if (value!.isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    userEmail = value!;
                  },
                  onChanged: (value) {
                    userEmail = value;
                  },
                  decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.email,
                        color: Color(0xFFB6C7D1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color(0XFFA7BCC7)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                      ),
                      hintText: 'email',
                      hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0XFFA7BCC7)),
                      contentPadding: EdgeInsets.all(10)),
                ),

                SizedBox(height: 8,),

                TextFormField(
                  obscureText: true,
                  key: ValueKey(5),
                  validator: (value) {
                    if (value!.isEmpty || value.length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    userPassword = value!;
                  },
                  onChanged: (value) {
                    userPassword = value;
                  },
                  decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock,
                        color: Color(0xFFB6C7D1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color(0XFFA7BCC7)),
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                      ),
                      hintText: 'password',
                      hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0XFFA7BCC7)),
                      contentPadding: EdgeInsets.all(10)),
                ),

                SizedBox(height: 8,),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    //primary: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.0)
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text('Login', style: TextStyle(fontSize: 20)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      try {
                        final newUser =
                        await authentication.signInWithEmailAndPassword(
                          email: userEmail,
                          password: userPassword,
                        );

                        if (newUser.user != null) {
                          Navigator.push(
                            context, MaterialPageRoute(builder: (context) {
                            return Home();
                          },),);
                        }
                      } catch (e) {
                        //LOGIN FAILED
                        print(e);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(
                              'Please check your email and password'),
                            backgroundColor: Colors.blue,),
                        );
                      }
                    }
                  },
                ),

                SizedBox(height: 16,),

                Center(
                  child: InkWell(
                    child: Text(
                      'Create account',
                      style:TextStyle(
                        letterSpacing: 1.0,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen()),
                      );
                    },
                  ),
                ),

                SizedBox(height: 16,),

                TextButton.icon(
                  onPressed: () {
                    signInWithGoogle();
                    //Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()),);
                    Navigator.push(
                      context, MaterialPageRoute(builder: (context) => Home()),);
                  },
                  style: TextButton.styleFrom(
                      primary: Colors.white,
                      minimumSize: Size(155, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: Color(0xFFDE4B39)),
                    icon: Icon(Icons.add),
                    label: Text('Google'),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
}