import 'package:flutter/material.dart';

Widget backAndMenuBtns(BuildContext context) {
  return Row(mainAxisSize: MainAxisSize.min, children: [
    if (Navigator.canPop(context))
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
  ]);
}
