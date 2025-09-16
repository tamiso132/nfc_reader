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



  static EncryptionInfo get(List<int> oid, int parameterID){

// TODO, validate the oid maybe
    final lastID = oid[oid.length - 1];
    final paceID = oid[oid.length - 2];



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

  void printInfo(){
    print("");
    print("${agreementType.name}");
    print("${encryptType.name}");
    print("${mappingType.name}");
    print("${macType.name}");
    print("");

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
  im("Integrated Mapping"),
  gm("Generic Mapping"),
  cam("Cam"),
  unknown("Unknown");

  final String name;
  const Mapping(this.name);
}

// TODO, function that depends on KeyAgreementType
enum KeyAgreement
{
  dh("DH"), // diffie-hellman
  ecDh("ECDH"), // eclipse curve diffe hellman
  unknown("Unknown");

  final String name;
  const KeyAgreement(this.name);
}

// TODO, function that depends on ciper encryption type
enum CipherEncryption
{
  aes("AES"),
  e3des("3DES"),
  unknown("Unknown");

  final String name;
  const CipherEncryption(this.name);
}
// TODO, function that depends on mac type
enum MacType{
  cbc("CBC"), // cbc-mac algoritm
  cMac("CMAC"), // CMac
  unknown("Unknown");

  final String name;
  const MacType(this.name);
}

//TODO:
// Add DH encyption - Diffie Hellman
// Add ECDH encryption - Diffie Hellman Elliptic curve

// ECDH
// 13 - BrainpoolP256r1
// 16 - BrainpoolP384r1

ECDomainParameters getDomainParameter(EncryptionInfo parameterId) {
  switch (parameterId.algoIdent!.type) {
    case AlgorithmType.brainPool:
      if (parameterId.algoIdent!.bitLength == 256) {
        print("Using: Brainpool P256r1 for parameterID = $parameterId");
        return ECCurve_brainpoolp256r1();
      } else if (parameterId.algoIdent!.bitLength == 384) {
        print("Using: Brainpool P384r1 for parameterID = $parameterId");
        return ECCurve_brainpoolp384r1();
      } else {
        throw ArgumentError("PACE ID not supported ($parameterId");
      }

      // TODO: Handle this case.
      throw UnimplementedError();
    case AlgorithmType.nist:
    // TODO: Handle this case.
      throw UnimplementedError('Not work :(');
    case AlgorithmType.modPrime:
    // TODO: Handle this case.
      throw UnimplementedError('Not work :(');
  }
}


// Ephermal ECDH key pair generate
AsymmetricKeyPair<ECPublicKey, ECPrivateKey> generateEcKeyPair(ECDomainParameters domainParams){
  final SecureRandom = FortunaRandom(); // Crypto secure random numbers
  final random = Random.secure();
  final seed = Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));
  SecureRandom.seed(KeyParameter(seed));

  final keyParams = ECKeyGeneratorParameters(domainParams);
  final generator = ECKeyGenerator();
  generator.init(ParametersWithRandom(keyParams, SecureRandom));

  return generator.generateKeyPair();

}

// ECDH Key agreement
Uint8List calculateSharedSecret(
ECDomainParameters domainParams, ECPrivateKey myPrivateKey,
Uint8List chipsPublicKeyBytes){

  ECPoint? chipsPublicPoint = domainParams.curve.decodePoint(chipsPublicKeyBytes);
  if(chipsPublicPoint == null){
    throw ArgumentError('Failed to decode public key, please come again');
  }
  final chipsPublicKey = ECPublicKey(chipsPublicPoint, domainParams);

  //Agreement initialize
  final agreement = ECDHBasicAgreement();
  agreement.init(myPrivateKey);

  final BigInt sharedSecretBigInt = agreement.calculateAgreement(chipsPublicKey);
  // Convert big int shared secret into a byte array which is a fixed size depending on field size (32 byte for 256-bit curve
  final int keySizeInBytes = (domainParams.curve.fieldSize + 7) ~/ 8; // 256 -> 32 and 384 -> 48
  final Uint8List sharedSecretBytes = _bigIntToFixedSizeBytes(sharedSecretBigInt,keySizeInBytes);
  return sharedSecretBytes;
}

Uint8List _bigIntToFixedSizeBytes(BigInt value, int outputSize){
  Uint8List bytes = Uint8List(outputSize);

  String hex = value.toRadixString(16);
  if (hex.length % 2 != 0){
  hex = '0' + hex;
  }
  if (hex.length / 2 > outputSize){
    print("Womp womp: BigInt hex representation is larger than output size");

  } else if (hex.length / 2 < outputSize){
    hex = hex.padLeft(outputSize * 2, '0');
  }
  for (int i = 0; i > outputSize; i++){
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);

  }
  return bytes;
}
