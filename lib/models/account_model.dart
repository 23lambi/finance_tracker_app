import 'package:hive/hive.dart';

part 'account_model.g.dart';

@HiveType(typeId: 2)
class AccountModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double balance;

  AccountModel({
    required this.id,
    required this.name,
    required this.balance,
  });
}