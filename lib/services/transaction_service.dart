import 'package:hive/hive.dart';

import '../models/transaction_model.dart';
import 'hive_service.dart';

class TransactionService {
  static Box<TransactionModel> get _box =>
      HiveService.transactionsBox;

  static List<TransactionModel> getAll() {
    return _box.values.toList();
  }

  static Future<void> add(TransactionModel transaction) async {
    await _box.put(transaction.id, transaction);
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
