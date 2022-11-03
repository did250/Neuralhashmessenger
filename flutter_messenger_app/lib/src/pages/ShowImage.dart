import 'package:flutter/material.dart';
import 'dart:typed_data';

class ShowImageScreen extends StatefulWidget {
  final Uint8List imageBytetest;
  ShowImageScreen(this.imageBytetest);

  @override
  _ShowImageScreenState createState() => _ShowImageScreenState();
}

class _ShowImageScreenState extends State<ShowImageScreen> {

  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              }),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              alignment: Alignment.center,
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                child: InteractiveViewer(
                  child: Container(
                    child: Image.memory(Uint8List.fromList(widget.imageBytetest)),
                  ),
                ),
              ),
        ),
    );
  }
}