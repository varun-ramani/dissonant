import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:web_socket_channel/io.dart';
import 'globals.dart' as globals;
import 'dart:convert';

void main() => runApp(App());

class App extends StatelessWidget {
  App() {
    globals.channel = IOWebSocketChannel.connect(globals.wsURL);
  }

  @override
  Widget build(BuildContext build) {
    return MaterialApp(
      title: "Dissonant",
      home: Login(),
      routes: {
        '/login': (context) => Login(),
        '/home': (context) => Home()
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class Login extends StatelessWidget {
  String email;
  String password;

  Widget build(BuildContext build) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.purple, Colors.blue])
        ),
      )
    );
  }
}

class Home extends StatefulWidget {
  @override
  State createState() => HomeState();
}

class HomeState extends State<Home> {
  final List<Message> _messages = <Message>[];
  final TextEditingController _textController = TextEditingController();
  bool _isWriting = false;

  void _handleMessage(dynamic message) {
    Map jsonData = json.decode(message);
    _addMessage(jsonData['message'], "Bob");
  }

  HomeState() {
    globals.channel.stream.listen(_handleMessage);
  }

  void _addMessage(String message, String author) {
    setState(() {
      Message msg = Message(
        text: message,
        author: author,
        color: Colors.blue
      );
      _messages.insert(0, msg);
    });
  }

  void _sendMessage(String message) {
    if (!(_textController.text.length == 0)) {
      _textController.clear();
      _addMessage(message, "Varun");
      String jsonString = json.encode({"message": message, "channel": "foochannel", "token": "footoken"});
      globals.channel.sink.add(jsonString);
    }
  }

  Widget _buildComposer() {
    return Container(
      child: Row(
        children: <Widget>[
          Flexible(
            child: Container(
              child: TextField(
                controller: _textController,
                cursorColor: Colors.blue,
                style: TextStyle(color: Colors.blue),
                decoration: InputDecoration.collapsed(
                  hintText: "Send A Message!",
                  hintStyle: TextStyle(color: Colors.white)
                ),
                onChanged: (String txt) {
                  setState(() {
                    _isWriting = true;
                  });
                },
                onSubmitted: _sendMessage,
              ),
              padding: EdgeInsets.all(6.0),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            color: Colors.white,
            onPressed: () {_sendMessage(_textController.text);}
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext build) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Dissonant"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () {globals.channel = IOWebSocketChannel.connect(globals.wsURL); globals.channel.stream.listen(_handleMessage);},
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
              reverse: true,
              padding: new EdgeInsets.all(6.0)
            ),
          ),
          Divider(color: Colors.white, height: 10.0),
          Container(
            child: _buildComposer(),
          )
        ],
      )
    );
  }
}

class Message extends StatelessWidget {
  Message({this.text, this.author, this.datetime, this.color});

  final String text;
  final String author;
  final String datetime;
  final Color color;

  @override
  Widget build(BuildContext build) {
    return Container(
      child: Row(
        children: <Widget>[
          Text(author, style: TextStyle(color: Colors.white)),
          Container(
            padding: EdgeInsets.only(left: 15.0, top: 7.0, bottom: 7.0, right: 10.0),
            margin: EdgeInsets.all(6.0),
            child: Text(text, style: TextStyle(color: this.color)),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.only(topRight: Radius.circular(100.0), bottomRight: Radius.circular(100.0), topLeft: Radius.circular(100.0), bottomLeft: Radius.circular(100.0))
            ),
          ),
        ],
      ),
    );
  }
}