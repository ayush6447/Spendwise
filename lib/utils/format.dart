import 'package:intl/intl.dart';

final NumberFormat kRupees = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final DateFormat kDate = DateFormat('dd MMM yyyy');
final DateFormat kDateShort = DateFormat('dd MMM');
