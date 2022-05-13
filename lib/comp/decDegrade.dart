import 'package:flutter/material.dart';

BoxDecoration decDegrade() {
  const Color color1 = Color(0xff373D69);
  const Color color2 = Color(0xff57C0A4);

  return const BoxDecoration(
    gradient: LinearGradient(
        colors: [color1, color2],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter),
  );
}
