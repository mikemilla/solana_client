/// Response model for transaction operations on the Solana blockchain.
///
/// This class encapsulates the result of a blockchain transaction, providing
/// both the status of the operation and a message containing either the
/// transaction signature (on success) or an error description (on failure).
class TransactionResponse {
  /// The status of the transaction operation.
  ///
  /// Typically 'Done' for successful transactions or 'Error' for failed ones.
  final String status;

  /// The message associated with the transaction.
  ///
  /// For successful transactions, this contains the transaction signature.
  /// For failed transactions, this contains the error message.
  final String message;

  /// Creates a new [TransactionResponse] instance.
  ///
  /// [status] - The status of the transaction ('Done' or 'Error')
  /// [message] - The transaction signature or error message
  TransactionResponse({required this.status, required this.message});

  @override
  String toString() => '{status: $status, message: $message}';
}

