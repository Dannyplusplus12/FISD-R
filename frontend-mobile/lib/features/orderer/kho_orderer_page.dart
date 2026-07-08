import 'package:flutter/material.dart';
import '../kho_hang/kho_hang_page.dart';

class KhoOrdererPage extends StatelessWidget {
  const KhoOrdererPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const KhoHangPage(readOnly: false);
  }
}
