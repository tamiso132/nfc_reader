part of 'cmd.dart';

// TODO, documentation, what it is for



abstract class _IEfParser<T>{
  T parseFromBytes(Uint8List bytes);
}

abstract class IEfID{
  int get shortID;
  Uint8List getFullID();

  AppID? appIdentifier();
}
