part of 'cmd.dart';

// TODO, documentation, what it is for


/*
Explain what this inteface is used for
*/
abstract class _IEfParser<T>{
  T parseFromBytes(Uint8List bytes);
}

/*
Explain what this inteface is used for
 */
abstract class IEfID{
  int get shortID;
  Uint8List getFullID();

  AppID? appIdentifier();
}
