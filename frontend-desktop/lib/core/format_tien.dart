import 'package:intl/intl.dart';

String dinhDangTien(int tien) {
  return '${NumberFormat('#,###', 'vi_VN').format(tien)}k';
}
