part of "cmd.dart";

enum AlgorithmType {
  brainPool,
  nist,
  modPrime;
}

class AlgorithmIdentifier {
  final AlgorithmType type;
  final int bitLength;
  final int? modPrimeOrder;

  AlgorithmIdentifier(this.type, this.bitLength, {this.modPrimeOrder});
}

class EncryptionInfo{

  static final Map<int, (KeyAgreement, Mapping)> _paceMap = {
    1: (KeyAgreement.dh, Mapping.gm),
    2: (KeyAgreement.ecDh, Mapping.gm),
    3: (KeyAgreement.dh, Mapping.im),
    4: (KeyAgreement.ecDh, Mapping.im),
    6: (KeyAgreement.ecDh, Mapping.cam),
  };

  static final Map<int, (CipherEncryption, MacType, int)> _cryptoMap = {
    1: (CipherEncryption.e3des, MacType.cbc, 0),
    2: (CipherEncryption.aes, MacType.cMac, 128),
    3: (CipherEncryption.aes, MacType.cMac, 192),
    4: (CipherEncryption.aes, MacType.cMac, 256),
  };

  static EncryptionInfo get(String oid, int parameterID){
    final list = oid.split('.');
    final lastID = int.parse(list[list.length - 1]);
    final paceID = int.parse(list[list.length - 2]);



    EncryptionInfo info = EncryptionInfo();

    info.agreementType = _paceMap[paceID]!.$1;
    info.mappingType = _paceMap[paceID]!.$2;

    info.encryptType = _cryptoMap[paceID]!.$1;
    info.macType = _cryptoMap[paceID]!.$2;
    info.len = _cryptoMap[paceID]!.$3;

    switch(parameterID){

    }


    if (info.agreementType == KeyAgreement.unknown) {
      throw Exception("Invalid configuration: KeyAgreement is unknown");
    }
    if (info.encryptType == CipherEncryption.unknown) {
      throw Exception("Invalid configuration: CipherEncryption is unknown");
    }
    if (info.mappingType == Mapping.unknown) {
      throw Exception("Invalid configuration: Mapping is unknown");
    }
    if (info.macType == MacType.unknown) {
      throw Exception("Invalid configuration: MacType is unknown");
    }

    return info;
  }

  KeyAgreement agreementType = KeyAgreement.unknown;
  CipherEncryption encryptType = CipherEncryption.unknown;
  Mapping mappingType = Mapping.unknown;
  MacType macType = MacType.unknown;
  AlgorithmIdentifier? algoIdent = null;
  int len = 0;



}

List<String> _splitOnId(String input) {
  List<String> results = [];
  int index = 0;

  while (index < input.length) {
    int start = input.indexOf('id-', index);
    if (start == -1) break;

    int nextStart = input.indexOf('id-', start + 1);

    if (nextStart == -1) {
      // This is the last item
      results.add(input.substring(start));
      break;
    } else {
      results.add(input.substring(start, nextStart));
      index = nextStart;
    }
  }

  return results;
}
// 9
// sista nummer också




enum Mapping{
  im,
  gm,
  cam,
  unknown,
}

// TODO, function that depends on KeyAgreementType
enum KeyAgreement
{
  dh, // diffie-hellman
  ecDh, // eclipse curve diffe hellman
  unknown,
}

// TODO, function that depends on ciper encryption type
enum CipherEncryption
{
  aes,
  e3des,
  unknown,
}
// TODO, function that depends on mac type
enum MacType{
  cbc, // cbc-mac algoritm
  cMac, // CMac
  unknown,
}

//TODO:
// Add DH encyption - Diffie Hellman
// Add ECDH encryption - Diffie Hellman Elliptic curve

// ECDH
// 13 - BrainpoolP256r1
// 16 - BrainpoolP384r1

ECDomainParameters getDomainParameter(int parameterId){
  if (parameterId == 13) {
    print("Using: Brainpool P256r1 for parameterID = $parameterId");
    return ECCurve_brainpoolp256r1();
  } else if (parameterId == 16){
    print("Using: Brainpool P384r1 for parameterID = $parameterId");
    return ECCurve_brainpoolp384r1();
  } else {
    throw ArgumentError("PACE ID not supported ($parameterId");

  }
}

// Ephermal ECDH key pair

AsymmetricKeyPair<ECPublicKey, ECPrivateKey> generateEcKeyPair(ECDomainParameters domainParams){
  final SecureRandom = FortunaRandom();
  final random = SecureRandom();
  final seed = Uint8List.fromList(List<int>.generate(32, (_) -> random.nextInt(256)));

}