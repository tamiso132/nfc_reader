import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NfcExample(),
    );
  }
}

class NfcExample extends StatefulWidget {
  @override
  NfcExampleState createState() => NfcExampleState();
}

class NfcExampleState extends State<NfcExample> {
  String _tagData = "Scan an NFC tag";

  void _startNfcSession() {

     NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (tag) {
        print(tag.data);
      },
      alertMessageIos: "Hold your device near the NFC tag",
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("NFC Example")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_tagData),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startNfcSession,
              child: Text("Start NFC Scan"),
            ),
          ],
        ),
      ),
    );
  }
}
