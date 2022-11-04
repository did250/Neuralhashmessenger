import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_messenger_app/src/pages/Home.dart';
import 'package:flutter_messenger_app/src/pages/Signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authentication = FirebaseAuth.instance;

  final formKey = GlobalKey<FormState>();
  String userEmail = '';
  String userPassword = '';

  TextEditingController userEmailController = TextEditingController(text: '');
  TextEditingController userPwdController = TextEditingController(text: '');

  final storage = FlutterSecureStorage();

  void initState() {
    super.initState();
    load_prefData();
  }

  void set_prefData(String prefID, String prefPwd) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: 'prefEmailId', value: prefID);
    await storage.write(key: 'prefPassword', value: prefPwd);
  }

  void load_prefData() async {
      final storage = FlutterSecureStorage();

      userEmail = (await storage.read(key: 'prefEmailId') ?? '');
      userPassword = (await storage.read(key: 'prefPassword') ?? '');

      userEmailController = TextEditingController(
          text: await storage.read(key: 'prefEmailId') ?? '');
      userPwdController = TextEditingController(
          text: await storage.read(key: 'prefPassword') ?? '');

      try {
        final newUser = await authentication.signInWithEmailAndPassword(
          email: userEmail,
          password: userPassword,
        );
        if (userEmail != '' && userPassword != '' && FirebaseAuth.instance.currentUser?.emailVerified == false) {
          FirebaseAuth.instance.currentUser?.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Please verify your email'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        else {
        if (newUser.user != null) {
          set_prefData(userEmail, userPassword);

          Navigator.push(context, MaterialPageRoute(builder: (context) {
                return Home();
              },
            ),
          );
        }
      }} catch (e) {
        //LOGIN FAILED
        print(e);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            width: 500,
                            height: 80,
                            alignment: Alignment.topCenter,
                            child: Image(
                              image: AssetImage('assets/images/logo.png'),
                            )),
                        SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          controller: userEmailController,
                          key: ValueKey(4),
                          validator: (value) {
                            if (value!.isEmpty || !value.contains('@')) {
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
                                borderSide:
                                BorderSide(color: Color(0XFFA7BCC7)),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                              hintText: 'email',
                              hintStyle: TextStyle(
                                  fontSize: 14, color: Color(0XFFA7BCC7)),
                              contentPadding: EdgeInsets.all(10)),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        TextFormField(
                          controller: userPwdController,
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
                                borderSide:
                                BorderSide(color: Color(0XFFA7BCC7)),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                              hintText: 'password',
                              hintStyle: TextStyle(
                                  fontSize: 14, color: Color(0XFFA7BCC7)),
                              contentPadding: EdgeInsets.all(10)),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: const Color(0xff588970),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3.0)),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: Text('LOGIN', style: TextStyle(fontSize: 20)),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();

                              try {
                                final newUser = await authentication
                                    .signInWithEmailAndPassword(
                                  email: userEmail,
                                  password: userPassword,
                                );

                                if (newUser.user != null) {
                                  set_prefData(userEmail, userPassword);

                                  if (FirebaseAuth.instance.currentUser?.emailVerified == false) {
                                    FirebaseAuth.instance.currentUser?.sendEmailVerification();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Please verify your email'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  }
                                  else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return Home();
                                        },
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                //LOGIN FAILED
                                print(e);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Please check your email and password'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        SizedBox(
                          height: 40,
                        ),
                        Center(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(height: 1, color: Theme.of(context).primaryColorLight),
                              ),
                              Text("  or  ",
                                style: TextStyle(color: Theme.of(context).primaryColorLight),
                              ),
                              Expanded(
                                child: Container(height: 1, color: Theme.of(context).primaryColorLight),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 40,
                        ),
                        Center(
                          child: InkWell(
                            child: Text(
                              'Create account',
                              style: TextStyle(
                                letterSpacing: 1.0,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColorLight,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignupScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          );
      }
}
