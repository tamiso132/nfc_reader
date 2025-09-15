part of "cmd.dart";

/*
  Type of Coding
  N = number
  A = Alphabetic, only uppcase
  S = filter '<'
*/


//TODO implement TD3 for passes

// They use big endian format,  aka significant byte till least significant

// TODO, add tags etc and make it associated with a file element

// * This Data Group has yet to be defined. Until then, it is available for temporary proprietary usage
// Dg1 maybe complete
/* TODO: different LDS1 subgroups:
TODO: EF.COM, ---NOT CHECKED---
TODO: * EF.DG9
TODO: * EF.DG10
TODO: EF.DG16 - OPTIONAL
TODO: * EF.DG2
TODO: EF.SOD (V1), Two versions EF.SOD V0 or EF.SOD V1. V1 Recomended ONLY USE 1
 */


//EF.DG1:

class Dg1Info{
  int documentCode = 0; // 2 bytes
  int state = 0; // 3 bytes
  Uint8List documentNumber = Uint8List(0); // 9-24 bytes,  use
  Uint8List dateOfBirth = Uint8List(0);
  int gender = 0;
  Uint8List dateExpire = Uint8List(0);
  Uint8List nationality = Uint8List(0);
  String name = "";

  Dg1Info._();
}

class ImplEfDg1TD1 implements _IEfParser<Dg1Info>{
  @override
  Dg1Info parseFromBytes(Uint8List bytes) {
    Dg1Info ef = Dg1Info._();
    ByteReader byteReader = ByteReader(bytes);
    int tag = byteReader.readInt(1); // Should be 61, Maybe switch how we read the bytes and interpret them from the data. Might me more useful with readbytes function.
    if (tag != 61){
      throw Exception("Womp Womp, got: 0x${tag.toRadixString(16)}"); //TODO kanske ta bort :(
    }

    int length = byteReader.readLength();

    int innerTag = byteReader.readInt(2);
    if (innerTag != 0x5F1F){
      throw Exception("Womp Womp, skill issue. Wrong tag, expected: 0x${tag.toRadixString(16)}"); // TODO kanske ta bort :(
    }


    // Hardcoded ???????
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

// EF.DG9:
// NOTE: This Data Group has yet to be defined.
// Until then, it is available for temporary proprietary use
/*
class Dg9Info{
  int documentCode = 0; // 2 bytes
  int state = 0; // 3 bytes
  Uint8List documentNumber = Uint8List(0); // 9-24 bytes,  use
  Uint8List dateOfBirth = Uint8List(0);
  int gender = 0;
  Uint8List dateExpire = Uint8List(0);
  Uint8List nationality = Uint8List(0);
  String name = "";

  Dg9Info._();
}

class ImplEfDg9TD1 implements _IEfParser<Dg9Info>{
  @override
  Dg9Info parseFromBytes(Uint8List bytes) {
    //TODO, data check, that it is an correct value
    Dg9Info ef = Dg9Info._();
    ByteReader byteReader = ByteReader(bytes);



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
*/

// DG2 works mostly with the ENCODED FACE and cant be structured like DG1.
// TODO Does the nfc reader get bytes correlating to the encoded face structure?

// Exempel på DG2:

/*
class Dg2Info {
  List<FaceInfo> faces = [];
}

class FaceInfo {
  String format = "";
  int width = 0;
  int height = 0;
  Uint8List imageData = Uint8List(0);
}

class ImplEfDg2 implements _IEfParser<Dg2Info> {
  @override
  Dg2Info parseFromBytes(Uint8List bytes) {
    Dg2Info ef = Dg2Info();

    ByteReader reader = ByteReader(bytes);

    // Läs Biometric Header Template (exempel)
    int tag = reader.readInt(1); // borde vara 0x75 eller 0x7F61
    int length = reader.readLength(); // TLV-längd

    // Läs FaceInfo records (här behöver du följa ISO/IEC 19794-5 struktur)
    while (reader.hasRemaining()) {
      FaceInfo face = FaceInfo();
      // Här skulle du parsea metadata om bilden
      // t.ex. image format, size, etc.
      int imageLength = reader.readInt(4);
      face.imageData = reader.readBytes(imageLength);
      ef.faces.add(face);
    }

    return ef;
  }
}
*/

//EF.COM:
// ----NOT TESTED-----

class EfComInfo {
  String ldsVersion = "";
  String unicodeVersion = "";
  List<int> dgTags = [];
}


class ImplEfCom implements _IEfParser<EfComInfo> {
  @override
  EfComInfo parseFromBytes(Uint8List bytes) {
    EfComInfo ef = EfComInfo();
    ByteReader reader = ByteReader(bytes);

    int tag = reader.readInt(1); // borde vara 0x60
    if (tag != 0x60) {
      throw Exception("Not a valid EF.COM file, expected tag 0x60");
    }

    int length = reader.readLength(); // total length of COM structure

    while (reader.hasRemaining()) {
      int innerTag = reader.readInt(1);
      int innerLength = reader.readLength();
      Uint8List value = reader.readBytes(innerLength);

      switch (innerTag) {
        case 0x5F01: // LDS version
          ef.ldsVersion = String.fromCharCodes(value);
          break;
        case 0x5F36: // Unicode version
          ef.unicodeVersion = String.fromCharCodes(value);
          break;
        case 0x5C: // Data groups present
          ef.dgTags = value.toList();
          break;
        default:
        // okänd tag, hoppa över
          break;
      }
    }

    return ef;
  }
}

/*
//EF.DG10:
// "This Data Group has yet to be defined. Until then, it is available for temporary proprietary usage"

class Dg10Info{
  int documentCode = 0; // 2 bytes
  int state = 0; // 3 bytes
  Uint8List documentNumber = Uint8List(0); // 9-24 bytes,  use
  Uint8List dateOfBirth = Uint8List(0);
  int gender = 0;
  Uint8List dateExpire = Uint8List(0);
  Uint8List nationality = Uint8List(0);
  String name = "";

  Dg10Info._();
}

class ImplEfDg10TD1 implements _IEfParser<Dg10Info>{
  @override
  Dg10Info parseFromBytes(Uint8List bytes) {
    Dg10Info ef = Dg10Info._();
    ByteReader byteReader = ByteReader(bytes);
    int tag = byteReader.readInt(1); // Should be 6A, Maybe switch how we read the bytes and interpret them from the data. Might me more useful with readbytes function.
    if (tag != 0x6A){
      throw Exception("Womp Womp, skill issue. Wrong tag, expected: 0x${tag.toRadixString(16)}"); //TODO kanske ta bort :(
    }

    int length = byteReader.readLength();

    int innerTag = byteReader.readInt(2);
    if (innerTag != 0x02){
      throw Exception("Womp Womp, skill issue. Wrong tag, expected: 0x${tag.toRadixString(16)}"); // TODO kanske ta bort :(
    }


    // Hardcoded ???????
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
*/


class CardAccessInfo{
  String protocol = "";
  int version = 0;
  int parameterID = 0;
}

class ImplCardAccess implements _IEfParser<CardAccessInfo>{

  @override
  CardAccessInfo parseFromBytes(Uint8List bytes) {
    CardAccessInfo ef = CardAccessInfo();
    ByteReader reader = ByteReader(bytes);

    AsnInfo outerAsn = reader.readASN1();

    if (outerAsn.tag != 0x1C) {
      throw Exception("Not a valid EF.COM file, expected tag 0x1C but I get 0x${toHex(outerAsn.tag)}");
    }

    int length = outerAsn.data.length;

    while (reader.hasRemaining()) {
     AsnInfo readASN = reader.readASN1();

      switch (readASN.tag) {
        case 0x30: // PaceInfo

          ByteReader innerReader = ByteReader(readASN.data);
          while(innerReader.hasRemaining()){
            AsnInfo innerAsn = innerReader.readASN1();
            int count = 0;
            switch(innerAsn.tag){
              case 0xA: // identifier
                ef.protocol = innerReader.readString(innerAsn.data.length);
                break;
              default: //
                if(count == 0){
                  ef.version = innerReader.readInt(1);
                  count+= 1;
                }
                else{
                  ef.parameterID = innerReader.readInt(1);
                }
                break;
            }
          }




          break;
      }
    }

    return ef;
  }

}

// EF.cardaccess

//EF.SOD

class EFSodInfo{
  String ldsVersion = "";
  String digestAlgorithm = "";
  Map<int, Uint8List> dgHashes = {};
  Uint8List signature = Uint8List(0);

}

class ImplEfSod implements _IEfParser<EFSodInfo> {
  @override
  EFSodInfo parseFromBytes(Uint8List bytes) {
    EFSodInfo ef = EFSodInfo();
    ByteReader reader = ByteReader(bytes);

    int tag = reader.readInt(1); // bör vara 0x77
    if (tag != 0x77) {
      throw Exception("Womp Womp, Not a valid EF.SOD, expected tag 0x77");
    }

    int length = reader.readLength();

    // Läs version
    int versionTag = reader.readInt(1); // ex 0x5F01 eller 0x30 beroende på TLV
    int versionLength = reader.readLength();
    ef.ldsVersion = String.fromCharCodes(reader.readBytes(versionLength));

    // Läs digest algorithm
    int digestAlgTag = reader.readInt(1); // ex 0x30 för SEQUENCE
    int digestAlgLength = reader.readLength();
    ef.digestAlgorithm = String.fromCharCodes(reader.readBytes(digestAlgLength));

    // Läs DataGroupHashes
    int dgHashTag = reader.readInt(1); // ex 0x30
    int dgHashLength = reader.readLength();
    int dgHashEnd = reader.offset + dgHashLength;
    while (reader.offset < dgHashEnd) {
      int dgNumber = reader.readInt(1); // DG1, DG2, ...
      int hashLen = reader.readLength();
      ef.dgHashes[dgNumber] = reader.readBytes(hashLen);
    }

    // Läs signatur
    int signatureTag = reader.readInt(1); // ex 0x03 eller 0x30 beroende på struktur
    int signatureLength = reader.readLength();
    ef.signature = reader.readBytes(signatureLength);

    return ef;
  }
}



