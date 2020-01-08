import 'dart:math';
import 'package:flutter/material.dart';

extension RichOffset on Offset {
  Offset clampOnBounds(Offset bounds) =>
      Offset(max(min(dx, bounds.dx), 0), max(min(dy, bounds.dy), 0));

  Offset modOnBounds(Offset bounds) => Offset(dx % bounds.dx, dy % bounds.dy);

  double dotProduct(Offset operand) => dx * operand.dx + dy * operand.dy;

  bool hasNaN() => dx.isNaN || dy.isNaN;
}

/// Return a vector where the absolute value of the components equals 1 and +/- is randomly assigned
Offset randomVector() {
  Random rand = Random();
  double dirDx = rand.nextDouble();
  double xSign = rand.nextDouble().sign;
  double ySign = rand.nextDouble().sign;
  return Offset(xSign * dirDx, ySign * (1 - dirDx));
}
