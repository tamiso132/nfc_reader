part of "cmd.dart";


class EncryptionInfo{
  EncryptionInfo(String oid){
    final list = oid.split('.');
    final last_number = list[list.length - 1];
    final second_last = list[list.length - 2];
  }
  KeyAgreement agreementType;
  CipherEncryption encryptType;
  MacType macType;
  EncryptLength len;

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


enum EncryptLength{
  len128,
  len192,
  len256
}

// TODO, function that depends on KeyAgreementType
enum KeyAgreement
{
  dh, // diffie-hellman
  ecDh, // eclipse curve diffe hellman
}

// TODO, function that depends on ciper encryption type
enum CipherEncryption
{
  aes,
  e3des,

}
// TODO, function that depends on mac type
enum MacType{
  cbc, // cbc-mac algoritm
  cMac, // CMac
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