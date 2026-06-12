import 'package:hive/hive.dart';

part 'sync_status.g.dart';

@HiveType(typeId: 50) // Choose an unused typeId
enum SyncStatus {
  @HiveField(0)
  synced,

  @HiveField(1)
  pending,
}