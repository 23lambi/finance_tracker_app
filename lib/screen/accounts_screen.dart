import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/account_model.dart';
import '../services/finance_service.dart';
import 'account_detail_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final nameController = TextEditingController();
  final balanceController = TextEditingController();

  Future<void> addAccountDialog() async {
    await _accountDialog();
  }

  Future<void> editAccountDialog(AccountModel account) async {
    await _accountDialog(account: account);
  }

  Future<void> _accountDialog({AccountModel? account}) async {
    nameController.text = account?.name ?? '';
    balanceController.text = account?.balance.toStringAsFixed(2) ?? '';

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(account == null ? 'New Account' : 'Edit Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Account name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(labelText: 'Available balance'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text) ?? 0;

                if (name.isEmpty) {
                  return;
                }

                final updatedAccount = AccountModel(
                  id: account?.id ?? const Uuid().v4(),
                  name: name,
                  balance: balance,
                );

                if (account == null) {
                  await FinanceService.addAccount(updatedAccount);
                } else {
                  await FinanceService.updateAccount(updatedAccount);
                }

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: Text(account == null ? 'Save' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> openAccountDetail(AccountModel account) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountDetailScreen(accountId: account.id),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> setOverviewAccount(AccountModel account) async {
    await FinanceService.setSelectedAccountId(account.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${account.name} is now shown in overview.')),
      );
      setState(() {});
    }
  }

  Future<void> deleteAccount(AccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: Text(
            'Delete ${account.name}? Linked transactions will stay, but they will no longer belong to this account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await FinanceService.deleteAccount(account);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> showAccountSettingsSheet(AccountModel account) async {
    final isOverviewAccount = FinanceService.selectedAccountId == account.id;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF111426),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  account.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isOverviewAccount
                      ? 'This account is currently active in the overview.'
                      : 'Open the settings you want for this account.',
                  style: const TextStyle(
                    color: Color(0xFFAAB2D5),
                  ),
                ),
                const SizedBox(height: 18),
                if (!isOverviewAccount) ...[
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await setOverviewAccount(account);
                    },
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Show in Overview'),
                  ),
                  const SizedBox(height: 10),
                ],
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await editAccountDialog(account);
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit Account'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await deleteAccount(account);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete Account'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = FinanceService.getAccounts();
    final selectedAccountId = FinanceService.selectedAccountId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: accounts.isEmpty
          ? const _AccountsEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => openAccountDetail(account),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  selectedAccountId == account.id
                                      ? 'Available balance • Overview account'
                                      : 'Available balance',
                                  style: const TextStyle(
                                    color: Color(0xFFAAB2D5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '€${account.balance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selectedAccountId == account.id)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0x22FFC857),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'OVERVIEW',
                                        style: TextStyle(
                                          color: Color(0xFFFFC857),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.tune_rounded,
                                      color: Color(0xFF6E79A6),
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        showAccountSettingsSheet(account),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: addAccountDialog,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _AccountsEmptyState extends StatelessWidget {
  const _AccountsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF171B31),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFFFFC857),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No accounts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create an account to track where each transaction belongs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFAAB2D5)),
            ),
          ],
        ),
      ),
    );
  }
}
