# solana_client

A simple and easy-to-use Flutter/Dart client for interacting with the Solana blockchain. This package provides a high-level interface for common Solana operations including balance queries, SOL transfers, SPL token operations, and transaction history retrieval.

## Features

- 🔐 **Mnemonic-based wallet management** - Derive Solana keypairs from BIP39 mnemonic phrases
- 💰 **Balance queries** - Get SOL and SPL token balances for any wallet
- 📤 **Token transfers** - Send SOL and SPL tokens to any address
- 📜 **Transaction history** - Retrieve transaction history for tokens

## Getting started

Add `solana_client` to your `pubspec.yaml`:

```bash
flutter pub add solana_client
```

## Usage

### Generate a new mnemonic

```dart
import 'package:solana_client/solana_utils.dart';

// Generate a new 12-word mnemonic
final mnemonic = await SolanaUtils.generateMnemonic();
print('Your mnemonic: $mnemonic');
```

### Initialize the client

```dart
import 'package:solana_client/solana_client.dart';

// Create a client for devnet
final client = SolanaClient(
  network: SolanaNetwork.devnet,
  mnemonic: 'your twelve word mnemonic phrase goes here',
);

// Or for mainnet-beta
final mainnetClient = SolanaClient(
  network: SolanaNetwork.mainnetBeta,
  mnemonic: 'your twelve word mnemonic phrase goes here',
  account: 0,
  change: 0,
);
```

### Get wallet address

```dart
final address = await client.getAddress();
print('Wallet address: $address');
```

### Check Solana balance

```dart
final balance = await client.getSolanaBalance();
print('SOL balance: $balance');
```

### Check token balance

```dart
final tokenBalance = await client.getTokenBalance(
  tokenMint: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v', // USDC
);
print('Token balance: $tokenBalance');
```

### Send Solana

```dart
final response = await client.sendSolana(
  to: 'RecipientWalletAddressHere',
  amount: 0.1, // Amount in SOL
);

print(response.message);
```

### Send token

```dart
final response = await client.sendToken(
  to: 'RecipientWalletAddressHere',
  tokenMint: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v', // USDC
  amount: 10.0, // Amount in token units
);

print(response.message);
```

### Get token transaction history

```dart
final transactions = await client.getTokenTransactions(
  limit: 10,
);

for (final tx in transactions) {
  print('Transaction: $tx');
}
```

### Dependencies

- [`solana`](https://pub.dev/packages/solana) - Core Solana functionality
- [`bip39`](https://pub.dev/packages/bip39) - BIP39 mnemonic generation and validation

### License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
