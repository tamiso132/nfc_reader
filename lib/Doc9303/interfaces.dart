part of 'cmd.dart';

// TODO, documentation, what it is for


/*
Explain what this interface is used for
*/
abstract class _IEfParser<T>{
  T parseFromBytes(Uint8List bytes);
}

/*
Explain what this interface is used for
 */
abstract class IEfID{
  int get shortID;
  Uint8List getFullID();

  AppID? appIdentifier();
}


/*
Explain what this interface is used for
 */
abstract class ICryptoAlgorithm{
  Uint8List encrypt(Uint8List input);
  Uint8List decrypt(Uint8List input);
}


