import 'package:drift/drift.dart';

class SyncRecordTable extends Table {
  TextColumn get uuid => text()();
  TextColumn get tableEntity => text()();
  IntColumn get localId => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get tokoId => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {uuid};
}
