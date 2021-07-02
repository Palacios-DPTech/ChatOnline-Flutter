import 'dart:io';
import 'package:chat_online/chat_message.dart';
import 'package:chat_online/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  FirebaseUser _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<FirebaseUser> _getUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      //  FAZER LOGIN COM O GOOGLE
      final googleSignInAccount =
          await googleSignIn.signIn();
      // LEVAR ESSE LOGIN PARA O FIREBASE
      final googleSignInAuthentication =
          await googleSignInAccount.authentication;
      //  FAZER CONEXÃO GOOGLE - FIREBASE (CREDENCIAIS NECESSARIAS)
      final credential = GoogleAuthProvider.getCredential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );
      // REALMENTE FAZENDO  LOGIN
      final AuthResult authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      // ACESSANDO O USUÁRIO NO FIREBASE
      final user = authResult.user;
      return user;
    } catch (error) {
      return null;
    }
  }

  void _sendMessage({String text, File imgFile}) async {
    // OBTER O USUÁRIO ATUAL
    final user = await _getUser();
    // VERIFICAÇÃO DO USUÁRIO
    if (user == null) {
       _scaffoldKey.currentState.showSnackBar(
        SnackBar(
        content: Text('Login error. Try again!'),
        backgroundColor: Colors.red,
      ));
    }

    var data = <String, dynamic>{
      "uid": user.uid,
      "senderName": user.displayName,
      "senderPhotoUrl": user.photoUrl,
      "time": Timestamp.now(),
    };

    if (imgFile != null) {
      var task = FirebaseStorage.instance
          .ref()
          .child(user.uid + DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(imgFile);
      setState(() {
        _isLoading = true;
      });

      var taskSnapshot = await task.onComplete;
      String url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl'] = url;
    }
    setState(() {
      _isLoading = false;
    });

    if (text != null) data['text'] = text;
    Firestore.instance.collection('messages').add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_currentUser != null
            ? 'Olá, ${_currentUser.displayName}'
            : 'Chat App'),
        centerTitle: true,
        elevation: 0,
        actions: <Widget>[
          _currentUser != null
              ? IconButton(
                  color: Colors.white,
                  icon: Icon(Icons.exit_to_app, color: Colors.white),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    googleSignIn.signOut();
                     _scaffoldKey.currentState.showSnackBar(SnackBar(
                      content: Text('Successfully sign out!'),
                    ));
                  },
                )
              : Container()
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance
                .collection('messages')
                .orderBy('time')
                .snapshots(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                default:
                  var documents =
                      snapshot.data.documents.reversed.toList();
                  return ListView.builder(
                    itemCount: documents.length,
                    reverse: true, // AS MENSAGENS APARECEM DE BAIXO PRA CIMA
                    itemBuilder: (context, index) {
                      return ChatMessage(documents[index].data,
                          documents[index].data['uid'] == _currentUser?.uid);
                    },
                  );
              }
            },
          )),
          _isLoading ? LinearProgressIndicator() : Container(),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}
