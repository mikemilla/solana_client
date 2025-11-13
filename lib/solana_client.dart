import 'package:solana_client/solana_network.dart';
import 'package:solana_client/solana_utils.dart';
import 'package:solana_client/transaction_response.dart';
import 'package:solana/solana.dart' as solana;

/// Main Solana client class for interacting with the Solana blockchain.
///
/// This client provides a high-level interface for common Solana operations
/// including balance queries, SOL transfers, SPL token operations, and
/// transaction history retrieval. It handles keypair derivation from mnemonics
/// and manages RPC connections to Solana networks.
///
/// Example usage:
/// ```dart
/// final client = SolanaClient(
///   network: SolanaNetwork.devnet,
///   mnemonic: 'your mnemonic phrase here',
///   account: 0,
///   change: 0,
/// );
/// ```
class SolanaClient {
  /// The Solana network to connect to (mainnet-beta or devnet).
  final SolanaNetwork network;

  /// The mnemonic seed phrase used to derive the wallet keypair.
  final String mnemonic;

  /// The account index for BIP44 derivation (default: 0).
  ///
  /// Used to derive different accounts from the same mnemonic.
  final int account;

  /// The change index for BIP44 derivation (default: 0).
  ///
  /// Typically 0 for external addresses and 1 for change addresses.
  final int change;

  /// Internal RPC client for Solana network operations.
  ///
  /// This is initialized lazily in the constructor based on the network.
  late final solana.SolanaClient _rpcClient;

  /// Creates a new [SolanaClient] instance.
  ///
  /// [network] - The Solana network to connect to
  /// [mnemonic] - The mnemonic seed phrase for wallet derivation
  /// [account] - The account index for key derivation (default: 0)
  /// [change] - The change index for key derivation (default: 0)
  SolanaClient({
    required this.network,
    required this.mnemonic,
    this.account = 0,
    this.change = 0,
  }) {
    final rpcUrl = _getRpcUrl();
    final websocketUrl = _getWebSocketUrl();
    _rpcClient = solana.SolanaClient(
      rpcUrl: rpcUrl,
      websocketUrl: websocketUrl,
    );
  }

  /// Gets the RPC URL based on the configured network.
  ///
  /// Returns the appropriate HTTP endpoint for the selected network.
  Uri _getRpcUrl() {
    switch (network) {
      case SolanaNetwork.mainnetBeta:
        return Uri.parse('https://api.mainnet-beta.solana.com');
      case SolanaNetwork.devnet:
        return Uri.parse('https://api.devnet.solana.com');
    }
  }

  /// Gets the WebSocket URL based on the configured network.
  ///
  /// Returns the appropriate WebSocket endpoint for real-time updates.
  Uri _getWebSocketUrl() {
    switch (network) {
      case SolanaNetwork.mainnetBeta:
        return Uri.parse('wss://api.mainnet-beta.solana.com');
      case SolanaNetwork.devnet:
        return Uri.parse('wss://api.devnet.solana.com');
    }
  }

  /// Gets the Solana wallet address for the configured account and change indices.
  ///
  /// The address is derived from the client's mnemonic using BIP44 derivation.
  /// Passing `account=0` and `change=0` matches the default address used by
  /// popular wallets like Phantom and Solflare (derivation path m/44'/501'/0'/0').
  ///
  /// Returns the wallet address as a base58-encoded string.
  ///
  /// Example:
  /// ```dart
  /// final address = await client.getAddress();
  /// print('Wallet address: $address');
  /// ```
  Future<String> getAddress() async {
    // Derive the keypair from the mnemonic using the configured account and change
    final keypair = await SolanaUtils.deriveKeypairFromMnemonic(mnemonic, account, change);
    // Return the public key encoded as a base58 string
    return keypair.publicKey.toBase58();
  }

  /// Gets the SOL balance for the wallet associated with this client.
  ///
  /// The balance is derived from the mnemonic using the configured account
  /// and change indices. The result is returned in SOL (not lamports).
  ///
  /// Returns the balance in SOL as a [double].
  ///
  /// Throws an [Exception] if the balance query fails.
  ///
  /// Example:
  /// ```dart
  /// final balance = await client.getSolanaBalance();
  /// print('Balance: $balance SOL');
  /// ```
  Future<double> getSolanaBalance() async {
    try {
      final address = await getAddress();
      final balanceResult = await _rpcClient.rpcClient.getBalance(address);
      // Convert lamports to SOL (1 SOL = 1,000,000,000 lamports)
      return balanceResult.value / 1000000000;
    } catch (e) {
      throw Exception('Error getting balance: $e');
    }
  }

  /// Gets the token balance for a specific SPL token mint address.
  ///
  /// This method queries the associated token account (ATA) for the wallet
  /// and the specified token mint. If no associated token account exists,
  /// returns 0.0.
  ///
  /// [tokenMint] - The token mint address (base58 encoded) of the SPL token
  ///
  /// Returns the token balance as a [double], accounting for the token's
  /// decimal places.
  ///
  /// Throws an [Exception] if the balance query fails.
  ///
  /// Example:
  /// ```dart
  /// final balance = await client.getTokenbalance(
  ///   tokenMint: 'TokenMintAddress...',
  /// );
  /// ```
  Future<double> getTokenBalance({
    required String tokenMint,
  }) async {
    try {
      // Get the wallet address and convert to public key
      final address = await getAddress();
      final walletPubkey = solana.Ed25519HDPublicKey.fromBase58(address);
      final mintPubkey = solana.Ed25519HDPublicKey.fromBase58(tokenMint);

      // Find the associated token account (ATA) for this wallet and token mint
      final tokenAccount = await _rpcClient.getAssociatedTokenAccount(
        owner: walletPubkey,
        mint: mintPubkey,
      );

      // If no associated token account exists, the balance is zero
      if (tokenAccount == null) {
        return 0.0;
      }

      // Query the token account balance from the RPC endpoint
      final balanceResponse = await _rpcClient.rpcClient.getTokenAccountBalance(
        tokenAccount.pubkey,
      );

      final amount = balanceResponse.value.amount;
      final decimals = balanceResponse.value.decimals;

      // Convert from the token's smallest unit to the human-readable amount
      // by dividing by 10^decimals
      return double.parse(amount) / BigInt.from(10).pow(decimals).toDouble();
    } catch (e) {
      throw Exception('Error getting token balance: $e');
    }
  }

  /// Sends SOL from the wallet associated with this client to a receiver address.
  ///
  /// This method creates and broadcasts a transfer transaction on the Solana
  /// blockchain. The transaction is signed using the keypair derived from the
  /// client's mnemonic and waits for confirmation before returning.
  ///
  /// [to] - The recipient's Solana wallet address (base58 encoded)
  /// [amount] - The amount of SOL to send (will be converted to lamports)
  ///
  /// Returns a [TransactionResponse] containing:
  /// - `status`: 'Done' on success, 'Error' on failure
  /// - `message`: Transaction signature on success, error message on failure
  ///
  /// Example:
  /// ```dart
  /// final response = await client.sendSolana(
  ///   to: 'RecipientAddress...',
  ///   amount: 1.5,
  /// );
  /// ```
  Future<TransactionResponse> sendSolana({
    required String to,
    required num amount,
  }) async {
    try {
      // Derive the sender's keypair from the mnemonic
      final senderKeypair = await SolanaUtils.deriveKeypairFromMnemonic(mnemonic, account, change);
      final senderPubkey = senderKeypair.publicKey;

      // Parse the recipient's public key from base58 string
      final recipientPubkey = solana.Ed25519HDPublicKey.fromBase58(to);

      // Convert SOL amount to lamports (1 SOL = 1,000,000,000 lamports)
      final lamports = (amount * 1000000000).toInt();

      // Create a system program transfer instruction
      final instruction = solana.SystemInstruction.transfer(
        fundingAccount: senderPubkey,
        recipientAccount: recipientPubkey,
        lamports: lamports,
      );

      // Build the transaction message with the transfer instruction
      final message = solana.Message(instructions: [instruction]);

      // Send the transaction and wait for confirmation
      final signature = await _rpcClient.sendAndConfirmTransaction(
        message: message,
        signers: [senderKeypair],
        commitment: solana.Commitment.confirmed,
      );

      return TransactionResponse(
        status: 'Done',
        message: signature,
      );
    } catch (e) {
      return TransactionResponse(
        status: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Sends SPL tokens from the wallet associated with this client to a receiver.
  ///
  /// This method handles the complete token transfer process:
  /// 1. Derives the sender's keypair from the mnemonic
  /// 2. Retrieves token mint information (decimals)
  /// 3. Creates an associated token account (ATA) for the recipient if needed
  /// 4. Transfers the tokens and waits for confirmation
  ///
  /// [to] - The recipient's Solana wallet address (base58 encoded)
  /// [tokenMint] - The token mint address (base58 encoded) of the SPL token
  /// [amount] - The amount of tokens to send (will be converted using token decimals)
  ///
  /// Returns a [TransactionResponse] containing:
  /// - `status`: 'Done' on success, 'Error' on failure
  /// - `message`: Transaction signature on success, error message on failure
  ///
  /// Example:
  /// ```dart
  /// final response = await client.sendToken(
  ///   to: 'RecipientAddress...',
  ///   tokenMint: 'TokenMintAddress...',
  ///   amount: 100.0,
  /// );
  /// ```
  Future<TransactionResponse> sendToken({
    required String tokenMint,
    required String to,
    required num amount,
  }) async {
    try {
      // Derive the sender's keypair from the mnemonic
      final senderKeypair = await SolanaUtils.deriveKeypairFromMnemonic(mnemonic, account, change);

      // Parse the recipient's address and token mint address from base58 strings
      final recipientPubkey = solana.Ed25519HDPublicKey.fromBase58(to);
      final mintPubkey = solana.Ed25519HDPublicKey.fromBase58(tokenMint);

      // Fetch the token mint information to determine decimal places
      final mint = await _rpcClient.getMint(address: mintPubkey);
      final decimals = mint.decimals;

      // Convert the human-readable token amount to the smallest unit
      // (e.g., if token has 9 decimals, 1.0 token = 1,000,000,000 smallest units)
      final amountInSmallestUnit = (amount * BigInt.from(10).pow(decimals).toDouble()).toInt();

      // Check if the recipient already has an associated token account (ATA) for this mint
      final hasRecipientATA = await _rpcClient.hasAssociatedTokenAccount(
        owner: recipientPubkey,
        mint: mintPubkey,
        commitment: solana.Commitment.confirmed,
      );

      // Create an associated token account for the recipient if it doesn't exist
      // The sender pays for the account creation transaction
      if (!hasRecipientATA) {
        await _rpcClient.createAssociatedTokenAccount(
          owner: recipientPubkey,
          mint: mintPubkey,
          funder: senderKeypair,
          commitment: solana.Commitment.confirmed,
        );
      }

      // Execute the SPL token transfer using the extension method
      // This handles the token program instruction creation and transaction signing
      final signature = await _rpcClient.transferSplToken(
        mint: mintPubkey,
        destination: recipientPubkey,
        amount: amountInSmallestUnit,
        owner: senderKeypair,
        commitment: solana.Commitment.confirmed,
      );

      return TransactionResponse(
        status: 'Done',
        message: signature,
      );
    } catch (e) {
      return TransactionResponse(
        status: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Gets transaction signatures for a given wallet address.
  ///
  /// This method queries the Solana blockchain for all transactions involving
  /// the specified address, including both SOL and SPL token transactions.
  ///
  /// [address] - The Solana wallet address to query (base58 encoded)
  /// [limit] - Maximum number of transaction signatures to return (default: 100)
  /// [before] - Optional transaction signature to start pagination from
  ///            (returns transactions before this signature)
  /// [until] - Optional transaction signature to end pagination at
  ///           (returns transactions until this signature)
  ///
  /// Returns a list of transaction signatures (base58 encoded strings).
  ///
  /// Throws an [Exception] if the query fails.
  ///
  /// Example:
  /// ```dart
  /// final transactions = await client.getTokenTransactions(
  ///   limit: 50,
  /// );
  /// ```
  Future<List<String>> getTokenTransactions({
    int limit = 100,
    String? before,
    String? until,
  }) async {
    try {
      final address = await getAddress();
      final signatures = await _rpcClient.rpcClient.getSignaturesForAddress(
        address,
        limit: limit,
        before: before,
        until: until,
      );

      // Extract just the signature strings from the response objects
      return signatures.map((sig) => sig.signature).toList();
    } catch (e) {
      throw Exception('Error getting token transactions: $e');
    }
  }
}
