import 'package:drift/drift.dart';

class NotesTable extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get content => text().nullable()();
  IntColumn get userId => integer().named('user_id')();
  IntColumn get categoryId => integer().named('category_id').nullable()();
  TextColumn get organizationStatus =>
      text().named('organization_status').nullable()();
  TextColumn get createdAt => text().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
