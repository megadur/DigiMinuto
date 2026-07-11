import '../models/transaction.dart';

abstract class TransactionRepository {
  Future<void> saveTransaction(Transaction transaction);
  Future<List<Transaction>> getTransactionsForToken(String tokenId);
  Future<List<Transaction>> getAllTransactions();
}
