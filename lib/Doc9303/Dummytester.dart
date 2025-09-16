part of 'cmd.dart';


// --- Assume your core crypto functions are defined elsewhere and imported ---
// import 'my_pace_crypto_logic.dart';
// (containing getDomainParameter, generateEcKeyPair, calculateSharedSecret, kdfIcaoPace, etc.)

// --- Test Data (Focus on MRZ and chosen parameters) ---

// 1. Visually Inspected MRZ Data (EXAMPLE - REPLACE WITH YOUR TEST PASSPORT'S MRZ)
final String DUMMY_MRZ_LINE_1 = "P<SWESANDVALL<<FILIP<OSCAR<HARALD<<<<<<<<<<<<<<<<<<<";
final String DUMMY_MRZ_LINE_2 = "94651334<5SWE9703197M2305112199703199456<<72";

// Extract relevant parts (you'll need a proper MRZ parser)
final String DUMMY_DOC_NUMBER = "94651334"; // Without check digit for now
final String DUMMY_DOB = "970319";       // YYMMDD
final String DUMMY_DOE = "180511";       // YYMMDD




// --- Test Functions ---

// Test MRZ parsing and password derivation (highly simplified)
Uint8List testDerivePaceSecretS_fromMRZ(String docNum, String dob, String doe, EncryptionInfo TesterInfo) {
  print("--- Testing PACE Secret S Derivation from MRZ ---");


  // 2. Chosen PACE Parameters for testing this MRZ scenario
  EncryptionInfo DUMMY_TEST_PACE_PARAMS = TesterInfo;// e.g., We decide to test with NIST P-256
  // An example Parameter ID for NIST P-256

  // Implement ICAO 9303 normalization and hashing for Kseed / S
  // This is a VERY simplified placeholder.
  String concatenated = docNum + dob + doe;
  Uint8List mrzBytes = Uint8List.fromList(utf8.encode(concatenated));

  var sha256 = SHA256Digest();
  sha256.reset();
  sha256.update(mrzBytes, 0, mrzBytes.length);
  Uint8List derivedSecretS = Uint8List(sha256.digestSize);
  sha256.doFinal(derivedSecretS, 0);

  print("   MRZ Input (simplified): $concatenated");
  print("   Derived Secret S (SHA256, hex): ${hexEncode(derivedSecretS)}");
  // In reality, this 'S' would be used in a mapping function with a nonce.
  return derivedSecretS;
}

// Test ECDH by agreeing on a key with ourselves
void testEcdhSelfAgreement(ECDomainParameters domainParams) {
  print("\n--- Testing ECDH Self-Agreement (${domainParams.domainName}) ---");
  // Terminal generates its key pair
  final keyPairA = generateEcKeyPair(domainParams);
  final ECPrivateKey privA = keyPairA.privateKey;
  final ECPublicKey pubA = keyPairA.publicKey;
  final Uint8List pubABytes = pubA.Q!.getEncoded(false);

  // "Chip" (also us for this test) generates its key pair
  final keyPairB = generateEcKeyPair(domainParams);
  final ECPrivateKey privB = keyPairB.privateKey;
  final ECPublicKey pubB = keyPairB.publicKey;
  final Uint8List pubBBytes = pubB.Q!.getEncoded(false);

  print("   Terminal Public Key A (hex): ${hexEncode(pubABytes)}");
  print("   'Chip' Public Key B (hex): ${hexEncode(pubBBytes)}");

  // Terminal calculates shared secret with Chip's public key
  final Uint8List secretZ_fromA = calculateSharedSecret(domainParams, privA, pubBBytes);
  print("   Secret Z computed by Terminal (using Chip's PubKey B, hex): ${hexEncode(secretZ_fromA)}");

  // "Chip" calculates shared secret with Terminal's public key
  final Uint8List secretZ_fromB = calculateSharedSecret(domainParams, privB, pubABytes);
  print("   Secret Z computed by 'Chip' (using Terminal's PubKey A, hex): ${hexEncode(secretZ_fromB)}");

  bool areSecretsEqual = _compareByteLists(secretZ_fromA, secretZ_fromB);
  print("   Are the two computed shared secrets equal? $areSecretsEqual");
  if (!areSecretsEqual) {
    throw Exception("ECDH Self-Agreement Test FAILED: Shared secrets do not match!");
  }
}

// Test KDF with a dummy Z
void testKdfWithDummyZ(ECDomainParameters domainParams, Uint8List dummyZ,EncryptionInfo TesterInfo) {
  print("\n--- Testing KDF with Dummy Z (${domainParams.domainName}) ---");
  print("   Using Dummy Shared Secret Z (hex): ${hexEncode(dummyZ)}");

  EncryptionInfo DUMMY_TEST_PACE_PARAMS = TesterInfo;// e.g., We decide to test with NIST P-256
  // An example Parameter ID for NIST P-256

  Digest hashForKdf;
  int aesKeyLengthBytes;
  // This logic should mirror what's in your actual PACE flow
  if (DUMMY_TEST_PACE_PARAMS.algoIdent!.bitLength == 256) {
    hashForKdf = SHA256Digest();
    aesKeyLengthBytes = 16; // Assuming AES-128 target for this test
    if (DUMMY_TEST_PACE_PARAMS.toString().contains("AES-CBC-CMAC-256")){
      aesKeyLengthBytes = 32;
    }
  } else if (DUMMY_TEST_PACE_PARAMS.algoIdent!.bitLength == 384) {
    hashForKdf = SHA384Digest();
    aesKeyLengthBytes = 24; // Assuming AES-192
    if (DUMMY_TEST_PACE_PARAMS.toString().contains("AES-CBC-CMAC-256")){
      aesKeyLengthBytes = 32;
    }
  } else {
    throw StateError("Unsupported bit length for KDF in dummy Z test.");
  }

  // Replace 'kdfIcaoPace' with your actual ICAO KDF implementation
  // Use placeholder purposes for now; these would be specific byte sequences in real KDF
  final Uint8List kEnc = kdfIcaoPace(dummyZ, "id-PACE-Kenc", aesKeyLengthBytes, hashForKdf);
  final Uint8List kMac = kdfIcaoPace(dummyZ, "id-PACE-Kmac", aesKeyLengthBytes, hashForKdf);

  print("   Derived K_enc (${kEnc.length} bytes, hex): ${hexEncode(kEnc)}");
  print("   Derived K_mac (${kMac.length} bytes, hex): ${hexEncode(kMac)}");
  // Here, you'd compare against expected K_enc/K_mac if you had official test vectors for your KDF.
}


// --- Main Test Execution ---
void runCryptoComponentTests(EncryptionInfo TesterInfo) {
  // Test MRZ to Secret S derivation
  EncryptionInfo DUMMY_TEST_PACE_PARAMS = TesterInfo;// e.g., We decide to test with NIST P-256
  // An example Parameter ID for NIST P-256
  testDerivePaceSecretS_fromMRZ(DUMMY_DOC_NUMBER, DUMMY_DOB, DUMMY_DOE, TesterInfo);

  // Get domain parameters for the chosen test scenario
  final domainParams = getDomainParameter(DUMMY_TEST_PACE_PARAMS);

  // Test ECDH self-agreement
  testEcdhSelfAgreement(domainParams);

  // Test KDF with an arbitrary dummy Z (e.g., the one from self-agreement, or a fixed one)
  // For consistency, let's make a fixed dummy Z of the correct size for the domainParams
  final int keySizeBytes = (domainParams.curve.fieldSize + 7) ~/ 8;
  final Uint8List fixedDummyZ = Uint8List(keySizeBytes);
  for(int i=0; i<keySizeBytes; i++) { fixedDummyZ[i] = (i + 0xA0) & 0xFF; } // Just some arbitrary bytes
  testKdfWithDummyZ(domainParams, fixedDummyZ, TesterInfo);

  print("\n--- Crypto Component Tests Finished ---");
}

// Helper to compare Uint8Lists (from previous example)
bool _compareByteLists(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// To run:
// void main() {
//   runCryptoComponentTests();
// }
