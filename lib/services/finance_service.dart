import 'package:hive/hive.dart';

import '../models/account_model.dart';
import '../models/transaction_model.dart';
import 'hive_service.dart';

class FinanceService {
  static const String selectedAccountSettingKey = 'selected_account_id';
  static const String demoPreviewSeededSettingKey = 'demo_preview_seeded_v1';
  static const List<String> demoAccountIds = [
    'demo-account-daily-card',
    'demo-account-savings-vault',
  ];
  static const List<String> demoTransactionIds = [
    'demo-transaction-salary',
    'demo-transaction-groceries',
    'demo-transaction-transport',
    'demo-transaction-freelance',
    'demo-transaction-rent',
    'demo-transaction-savings',
  ];

  static Box<TransactionModel> get transactionBox =>
      HiveService.transactionsBox;

  static Box<AccountModel> get accountBox => HiveService.accountsBox;
  static Box get settingsBox => HiveService.settingsBox;

  static List<TransactionModel> getTransactions() {
    final items = transactionBox.values.toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  static List<AccountModel> getAccounts() {
    return accountBox.values.toList();
  }

  static String? get selectedAccountId =>
      settingsBox.get(selectedAccountSettingKey) as String?;

  static AccountModel? get selectedAccount {
    final id = selectedAccountId;
    if (id == null) {
      return null;
    }

    return accountBox.get(id);
  }

  static double get totalIncome {
    return transactionBox.values
        .where((t) => t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
  }

  static double get totalExpenses {
    return transactionBox.values
        .where((t) => t.isExpense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  static double get balance => totalIncome - totalExpenses;

  static double get totalAccountBalance {
    return accountBox.values.fold<double>(
      0,
      (sum, account) => sum + account.balance,
    );
  }

  static double incomeForAccount(String? accountId) {
    return transactionBox.values
        .where((t) => t.accountId == accountId && t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
  }

  static double expensesForAccount(String? accountId) {
    return transactionBox.values
        .where((t) => t.accountId == accountId && t.isExpense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  static Future<void> setSelectedAccountId(String? accountId) async {
    if (accountId == null || accountId.isEmpty) {
      await settingsBox.delete(selectedAccountSettingKey);
      return;
    }

    await settingsBox.put(selectedAccountSettingKey, accountId);
  }

  static Future<bool> seedPreviewDataIfNeeded() async {
    final previewAlreadyMarked = settingsBox.get(demoPreviewSeededSettingKey) == true;
    final missingPreviewAccount = demoAccountIds.any(
      (accountId) => !accountBox.containsKey(accountId),
    );
    final missingPreviewTransaction = demoTransactionIds.any(
      (transactionId) => !transactionBox.containsKey(transactionId),
    );

    if (previewAlreadyMarked &&
        !missingPreviewAccount &&
        !missingPreviewTransaction) {
      return false;
    }

    final everydayAccount = AccountModel(
      id: 'demo-account-daily-card',
      name: 'Daily Card',
      balance: 0,
    );
    final savingsAccount = AccountModel(
      id: 'demo-account-savings-vault',
      name: 'Savings Vault',
      balance: 0,
    );

    if (!accountBox.containsKey(everydayAccount.id)) {
      await addAccount(everydayAccount);
    }

    if (!accountBox.containsKey(savingsAccount.id)) {
      await addAccount(savingsAccount);
    }

    final now = DateTime.now();
    final demoTransactions = [
      TransactionModel(
        id: 'demo-transaction-salary',
        title: 'Monthly Salary',
        amount: 1850,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime(now.year, now.month, now.day - 10),
        accountId: everydayAccount.id,
      ),
      TransactionModel(
        id: 'demo-transaction-groceries',
        title: 'Groceries',
        amount: 64.80,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(now.year, now.month, now.day - 8),
        accountId: everydayAccount.id,
      ),
      TransactionModel(
        id: 'demo-transaction-transport',
        title: 'Metro Card',
        amount: 18.50,
        type: TransactionType.expense,
        category: 'Transport',
        date: DateTime(now.year, now.month, now.day - 6),
        accountId: everydayAccount.id,
      ),
      TransactionModel(
        id: 'demo-transaction-freelance',
        title: 'Freelance Project',
        amount: 420,
        type: TransactionType.income,
        category: 'Side Hustle',
        date: DateTime(now.year, now.month, now.day - 4),
        accountId: savingsAccount.id,
      ),
      TransactionModel(
        id: 'demo-transaction-rent',
        title: 'Apartment Rent',
        amount: 520,
        type: TransactionType.expense,
        category: 'Bills',
        date: DateTime(now.year, now.month, now.day - 3),
        accountId: everydayAccount.id,
      ),
      TransactionModel(
        id: 'demo-transaction-savings',
        title: 'Savings Transfer',
        amount: 300,
        type: TransactionType.income,
        category: 'Savings',
        date: DateTime(now.year, now.month, now.day - 2),
        accountId: savingsAccount.id,
      ),
    ];

    for (final transaction in demoTransactions) {
      if (!transactionBox.containsKey(transaction.id)) {
        await addTransaction(transaction);
      }
    }

    await settingsBox.put(demoPreviewSeededSettingKey, true);
    return true;
  }

  static Future<bool> clearPreviewData() async {
    var removedAnything = false;

    for (final transactionId in demoTransactionIds) {
      final transaction = transactionBox.get(transactionId);
      if (transaction != null) {
        await deleteTransaction(transaction);
        removedAnything = true;
      }
    }

    for (final accountId in demoAccountIds) {
      final account = accountBox.get(accountId);
      if (account != null) {
        await deleteAccount(account);
        removedAnything = true;
      }
    }

    await settingsBox.delete(demoPreviewSeededSettingKey);
    return removedAnything;
  }

  static Future<void> addAccount(AccountModel account) async {
    await accountBox.put(account.id, account);

    if (selectedAccountId == null) {
      await setSelectedAccountId(account.id);
    }
  }

  static Future<void> updateAccount(AccountModel account) async {
    await accountBox.put(account.id, account);
  }

  static Future<void> deleteAccount(AccountModel account) async {
    final linkedTransactions = transactionBox.values.where(
      (transaction) => transaction.accountId == account.id,
    );

    for (final transaction in linkedTransactions) {
      transaction.accountId = null;
      await transaction.save();
    }

    await accountBox.delete(account.id);

    if (selectedAccountId == account.id) {
      final remainingAccounts = getAccounts();
      await setSelectedAccountId(
        remainingAccounts.isEmpty ? null : remainingAccounts.first.id,
      );
    }
  }

  static Future<void> addTransaction(TransactionModel transaction) async {
    await transactionBox.put(transaction.id, transaction);
    await _applyTransactionToAccount(transaction);
  }

  static Future<void> updateTransaction(TransactionModel transaction) async {
    final previousTransaction = transactionBox.get(transaction.id);

    if (previousTransaction != null) {
      await _revertTransactionFromAccount(previousTransaction);
    }

    await transactionBox.put(transaction.id, transaction);
    await _applyTransactionToAccount(transaction);
  }

  static Future<void> deleteTransaction(TransactionModel transaction) async {
    await _revertTransactionFromAccount(transaction);
    await transactionBox.delete(transaction.id);
  }

  static Future<void> _applyTransactionToAccount(
    TransactionModel transaction,
  ) async {
    if (transaction.accountId == null) {
      return;
    }

    final account = accountBox.get(transaction.accountId);
    if (account == null) {
      return;
    }

    if (transaction.isIncome) {
      account.balance += transaction.amount;
    } else {
      account.balance -= transaction.amount;
    }

    await account.save();
  }

  static Future<void> _revertTransactionFromAccount(
    TransactionModel transaction,
  ) async {
    if (transaction.accountId == null) {
      return;
    }

    final account = accountBox.get(transaction.accountId);
    if (account == null) {
      return;
    }

    if (transaction.isIncome) {
      account.balance -= transaction.amount;
    } else {
      account.balance += transaction.amount;
    }

    await account.save();
  }
}
