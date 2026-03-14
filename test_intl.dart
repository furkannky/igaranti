import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';
  print(DateFormat('dd.MM.yyyy').format(DateTime.now()));
}
