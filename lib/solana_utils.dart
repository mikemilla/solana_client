import 'package:solana/solana.dart' as solana;
import 'package:bip39/bip39.dart' as bip39;

/// Utility class for Solana-related operations that don't require a client instance
class SolanaUtils {
  /// Generates a new 12-word mnemonic seed phrase
  /// 
  /// Returns a new mnemonic phrase as a string
  static Future<String> generateMnemonic() async {
    return bip39.generateMnemonic();
  }

  /// Derives a Solana keypair from a mnemonic seed phrase
  /// 
  /// Uses the standard Solana derivation path: m/44'/501'/0'/0'
  /// This matches Phantom wallet and other standard Solana wallets
  /// 
  /// [mnemonic] - The mnemonic seed phrase (12 or 24 words)
  /// [account] - Optional account index (defaults to 0)
  /// [change] - Optional change index (defaults to 0)
  /// Returns an [Ed25519HDKeyPair] derived from the mnemonic
  static Future<solana.Ed25519HDKeyPair> deriveKeypairFromMnemonic(
    String mnemonic, 
    int account,
    int change,
  ) async {
    return await solana.Ed25519HDKeyPair.fromMnemonic(
      mnemonic,
      account: account,
      change: change,
    );
  }
}

