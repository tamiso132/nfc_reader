part of "cmd.dart";

/*
  Type of Coding
  N = number
  A = Alphabetic, only uppcase
  S = filter '<'
*/


//TODO implement TD3 for passes

// They use big endian format,  aka significant byte till least significant

abstract class IEfParser<T>{
  T parseFromBytes(Uint8List bytes);
}


class ParserDg1{

}

class EfDg1TD1  {
  int documentCode = 0; // 2 bytes
  int state = 0; // 3 bytes
  Uint8List documentNumber = Uint8List(0); // 9-24 bytes,  use
  Uint8List dateOfBirth = Uint8List(0);
  int gender = 0;
  Uint8List dateExpire = Uint8List(0);
  Uint8List nationality = Uint8List(0);
  String name = "";

  EfDg1TD1._();

  static EfDg1TD1 parse_from_bytes(Uint8List data){
    //TODO, data check, that it is an correct value
    EfDg1TD1 ef = EfDg1TD1._();
    ByteReader byteReader = ByteReader(data);
    


    ef.documentCode = byteReader.readInt(2);
    ef.state = byteReader.readInt(3);
    ef.documentNumber.addAll(byteReader.readBytes(14));
    int isExtendedDocument = byteReader.readInt(1);

    if(isExtendedDocument == 1){ // if exceeding 9 characters for document number
     ef.documentNumber.addAll(byteReader.readBytes(15));
    }
    else{
      byteReader.paddingNext(15);
    }

    ef.dateOfBirth = byteReader.readBytes(6);
    int checkDigitdateOfBirth = byteReader.readInt(1);
    ef.gender = byteReader.readInt(1);
    ef.dateExpire = byteReader.readBytes(6);
    int checkDigitExpireDate = byteReader.readInt(1);
    ef.nationality = byteReader.readBytes(3);
    byteReader.paddingNext(11); // optional data, so I pad
    byteReader.paddingNext(1); // composite check digit
    ef.name = byteReader.readString(30);


    return ef;
  }


}

