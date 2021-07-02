import 'package:chat_online/chat_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
  /* BUSCAR O OBJETO FIRESTORE = ACESSAR
  PRIMEIRAMENTE QUAL COLEÇÃO, DEPOIS DOCUMENTO E POR ULTIMO QUAL DADO 
  Firestore.instance.collection('mensagens').document('msg4').setData({
    'texto' : 'Aqui ta sol',
    'from' : 'Sandra',
    'read' : false
  });*/

/* EDITAR/CRIAR DOCUMENTOS E +
 QuerySnapshot snapshot = await Firestore.instance.collection('mensagens').getDocuments();
  snapshot.documents.forEach((d) { 
    d.reference.updateData({'read' : false});
  }); */

/* ATUALIZAÇÕES SOBRE DOCUMENTOS, SEMPRE QUE ALGO MUDAR
Firestore.instance.collection('mensagens').snapshots().listen((dado) {
  dado.documents.forEach((d) {
    print(d.data);
  });
});
 */
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          iconTheme: IconThemeData(
            color: Colors.blue,
          ),
        ),
        home: ChatScreen());
  }
}
