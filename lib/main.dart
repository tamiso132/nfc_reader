import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';


import 'package:test_flutter/Doc9303/cmd.dart';


void main() {
 // WidgetsFlutterBinding.ensureInitialized();
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

enum NfcState{
  startNFC("Start NFC Scan"),
  closeNFC("Stop NFC Scan");

  final String label;
  const NfcState(this.label);
}

void testCallback(String result){
  print(result);
}

class NfcExampleState extends State<NfcExample> {

  NfcState _nfcState = NfcState.startNFC;


  void _startNfcSession() async{
    print("Start Session");

    //Mrzflutterplugin.startContinuousScanner(testCallback);

    await NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (tag) async{
       print("Discovered");
        print(tag.data);
       IsoDepAndroid? nfc = IsoDepAndroid.from(tag); // passport protocol

        if(nfc!= null) {

          ResponseCommand response=  await Command.selectApplication(nfc, AppID.idLSD_1);
          await Command.readBinary(nfc, EfIdAppSpecific.com, 0, 0);
          if(response.data != null){
            EfComInfo com =  ImplEfCom().parseFromBytes(response.data!);

           print("Access Info: ${  com.ldsVersion}");
          }




         // var response = await nfc.transceive();
          NfcManager.instance.stopSession();

        }
        else{
          print("not that?");
        }

        await NfcManager.instance.stopSession();
      },
      alertMessageIos: "Hold your device near the NFC tag",
    );

  }

  void _stopNfcSession() async{
    NfcManager.instance.stopSession();


  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("NFC Example")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  switch(_nfcState){
                    case NfcState.startNFC:
                      _startNfcSession();
                      _nfcState = NfcState.closeNFC;
                      break;
                    case NfcState.closeNFC:
                      _stopNfcSession();
                      _nfcState = NfcState.startNFC;
                      break;
                  }
                });
              },
              child: Text(_nfcState.label),
            ),
          ],
        ),
      ),
    );
  }
}
