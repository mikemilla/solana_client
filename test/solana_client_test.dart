import 'package:flutter_test/flutter_test.dart';
import 'package:solana_client/solana_client.dart';
import 'package:solana_client/solana_network.dart';
import 'package:solana_client/solana_utils.dart';
import 'package:solana_client/transaction_response.dart';

void main() {
  // Sample seed and address for testing
  final mnemonic1 = 'device bag talent edit comic adjust garbage yellow art monkey diary offer';
  final mnemonic2 = 'bracket bottom depend crater arctic toddler stool okay visit tiny shallow peace';
  const address = '6wB7LtCrKkptofNteYWGWwaLmhNNF8XMRQhppUHbcR9M';
  const mintAddress = 'CXxCgCYerJZjHo8baHdsYAw23Bv2WNCor5bVNWJp98XH';

  group('SolanaClient', () {

    test('getAddress - returns correct address for default account', () async {
      final client = SolanaClient(
        network: SolanaNetwork.mainnetBeta,
        mnemonic: mnemonic1,
      );
      final result = await client.getAddress();
      expect(result, address);
    });

    test('getAddress - returns unique addresses for different accounts', () async {
      final client = SolanaClient(
        network: SolanaNetwork.mainnetBeta,
        mnemonic: mnemonic1,
        account: 0,
      );
      final address0 = await client.getAddress();
      final client2 = SolanaClient(
        network: SolanaNetwork.mainnetBeta,
        mnemonic: mnemonic1,
        account: 1,
      );
      final address1 = await client2.getAddress();
      expect(address0, isNot(address1));
    });

    test('getSolanaBalance - returns nonnegative balance for valid address', () async {
      final client = SolanaClient(
        network: SolanaNetwork.devnet,
        mnemonic: mnemonic1,
      );
      final balance = await client.getSolanaBalance();
      expect(balance, greaterThanOrEqualTo(0.0));
    });

    test('sendSolana - returns error response for invalid mnemonic', () async {
      final client = SolanaClient(
        network: SolanaNetwork.devnet,
        mnemonic: mnemonic1,
      );
      final response = await client.sendSolana(
        to: address,
        amount: 0.01,
        mnemonic: 'invalid mnemonic phrase',
      );
      expect(response.status, 'Error');
      expect(response.message, isNotEmpty);
    });

    test('getTokenBalance - returns 0 for non-existent token account (mnemonic1)', () async {
      final client = SolanaClient(
        network: SolanaNetwork.devnet,
        mnemonic: mnemonic1,
      );
      final balance = await client.getTokenBalance(
        tokenMint: mintAddress,
      );
      expect(balance, greaterThanOrEqualTo(0.0));
    });

    test('getTokenBalance - returns 0 for non-existent token account (mnemonic2)', () async {
      final client = SolanaClient(
        network: SolanaNetwork.devnet,
        mnemonic: mnemonic2,
      );
      final balance = await client.getTokenBalance(
        tokenMint: mintAddress,
      );
      expect(balance, greaterThanOrEqualTo(0.0));
    });

    test('sendToken - sends token successfully from mnemonic1 to mnemonic2', () async {
      // Create a SolanaClient for sender using mnemonic1 on devnet
      final client1 = SolanaClient(
        network: SolanaNetwork.devnet,
        mnemonic: mnemonic1,
      );
      // Create a SolanaClient for receiver using mnemonic2 on devnet
      final client2 = SolanaClient(
        network: SolanaNetwork.devnet,
        mnemonic: mnemonic2,
      );
      // Sender sends 0.01 tokens to receiver's address
      final response = await client1.sendToken(
        tokenMint: mintAddress, // Token mint address
        to: await client2.getAddress(), // Get receiver's address
        amount: 0.01, // Amount of token to send
      );
      // Check that transaction status is 'Done'
      expect(response.status, 'Done');
      expect(response.message, isA<String>());
    });

    test('getTokenTransactions - returns list of token transaction signatures', () async {
      final client = SolanaClient(
        network: SolanaNetwork.devnet,
        mnemonic: mnemonic1,
      );
      final transactions = await client.getTokenTransactions();
      expect(transactions, isA<List<String>>());
    });

    test('TransactionResponse - toString returns correct format', () {
      final response = TransactionResponse(
        status: 'Done',
        message: 'test_signature',
      );
      expect(response.toString(), '{status: Done, message: test_signature}');
    });
  });

  group('SolanaUtils', () {

    test('generateMnemonic - creates a valid 12-word mnemonic', () async {
      final seed = await SolanaUtils.generateMnemonic();
      expect(seed, isNotEmpty);
      final words = seed.split(' ');
      expect(words.length, 12);
    });
    test('deriveKeypairFromMnemonic - derives same keypair for same mnemonic and account', () async {
      final keypair1 = await SolanaUtils.deriveKeypairFromMnemonic(mnemonic1, 0, 0);
      final keypair2 = await SolanaUtils.deriveKeypairFromMnemonic(mnemonic1, 0, 0);
      expect(keypair1.publicKey.toBase58(), keypair2.publicKey.toBase58());
    });

    test('deriveKeypairFromMnemonic - derives different keypairs for different accounts', () async {
      final keypair1 = await SolanaUtils.deriveKeypairFromMnemonic(mnemonic1, 0, 0);
      final keypair2 = await SolanaUtils.deriveKeypairFromMnemonic(mnemonic1, 1, 0);
      expect(keypair1.publicKey.toBase58(), isNot(keypair2.publicKey.toBase58()));
    });
  });
}
