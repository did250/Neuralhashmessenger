import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const String _name = "MYNAME";


class ChatRoom extends StatefulWidget {
  final String name;

  const ChatRoom(this.name);
  ChatRoomState createState() => ChatRoomState();
}

class ChatRoomState extends State<ChatRoom> with TickerProviderStateMixin{
  final List<Messages> _message = <Messages>[];
  final TextEditingController _textController = TextEditingController();
  bool _exist = false;


  @override
  void initState() {
    // TODO: implement initState
    _aaa();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.name)
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Flexible(child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemCount: _message.length,
              itemBuilder: (_, index) => _message[index],
            ),
            ),
            Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              child: _buildTextComposer(),
            )
          ],
        ),
      ),
    );
  }
  Widget _buildTextComposer(){
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onChanged: (text){
                  setState(() {
                    _exist = text.length > 0;
                  });
                },
                onSubmitted: _exist ? _handleSubmitted : null,
                decoration: InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: CupertinoButton(
                child: Text("보내기"),
                onPressed: _exist
                    ? () => _handleSubmitted(_textController.text)
                    :null,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _aaa(){
    Messages mas = Messages(text: "first message", animationController: AnimationController(duration : Duration(milliseconds: 700),vsync: this));
    setState(() {
      _message.insert(0, mas);
    });
    mas.animationController.forward();
  }

  void _handleSubmitted(String text){
    _textController.clear();
    setState(() {
      _exist = false;
    });
    Messages message = Messages(
      text: text,
      animationController: AnimationController(
        duration: Duration(milliseconds: 700),
        vsync: this,
      ),
    );
    setState(() {
      _message.insert(0,message);
    });
    message.animationController.forward();
  }

  @override
  void dispose() {
    for (Messages message in _message){
      message.animationController.dispose();
    }
    super.dispose();
  }

}

class Messages extends StatelessWidget {
  final String text;
  final AnimationController animationController;

  Messages({required this.text, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(child: Text(_name[0])),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(_name),
                  Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: Text(text),
                  )
                ],
              ),
            )
          ],
        ),
      ),

    );
  }
}