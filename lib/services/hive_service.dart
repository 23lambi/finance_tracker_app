import 'package:hive_flutter/hive_flutter.dart';

import '../models/account_model.dart';
import '../models/transaction_model.dart';

class HiveService {
  static const String transactionsBoxName = 'transactions';
  static const String accountsBoxName = 'accounts';
  static const String settingsBoxName = 'settings';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AccountModelAdapter());
    }

    if (!Hive.isBoxOpen(transactionsBoxName)) {
      await Hive.openBox<TransactionModel>(transactionsBoxName);
    }

    if (!Hive.isBoxOpen(accountsBoxName)) {
      await Hive.openBox<AccountModel>(accountsBoxName);
    }

    if (!Hive.isBoxOpen(settingsBoxName)) {
      await Hive.openBox(settingsBoxName);
    }

    _initialized = true;
  }

  static Box<TransactionModel> get transactionsBox {
    _assertInitialized();
    return Hive.box<TransactionModel>(transactionsBoxName);
  }

  static Box<AccountModel> get accountsBox {
    _assertInitialized();
    return Hive.box<AccountModel>(accountsBoxName);
  }

  static Box get settingsBox {
    _assertInitialized();
    return Hive.box(settingsBoxName);
  }

  static void _assertInitialized() {
    if (!_initialized) {
      throw StateError(
        'Hive has not been initialized yet. Call HiveService.initialize() before using boxes.',
      );
    }
  }
}
