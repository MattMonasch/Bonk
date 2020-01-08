import 'dart:math';
import 'package:flutter/material.dart';
import 'extentions.dart';

class Ball {
  Offset pos;
  Offset dir;
  double radius;
  Ball(this.radius, this.pos, this.dir);
  Ball.withRandomDir(this.radius, this.pos) {
    dir = randomVector() * 10;
  }

  /// Returns true if this Ball and the provided Ball are touching or overlapping
  bool isCollidingWith(Ball b) {
    return (this.pos - b.pos).distanceSquared <= pow(b.radius + radius, 2);
  }

  /// Returns a list of Balls where none are colliding with each other given a particular space
  /// 
  /// [ballCount] is allowed to exceed the maximum allowed actors, but the returned list will only contain up to this maximum amount
  static List<Ball> fitIntoBoard(Offset size, num ballCount, double radius) {
    List<Ball> balls = [];

    Offset xRange = Offset(radius * 1.5, size.dx - radius * 1.5);
    Offset yRange = Offset(radius * 1.5, size.dy - radius * 1.5);
    num howManyBallsMaxInX = size.dx - radius * 5;
    if (howManyBallsMaxInX > 0) {
      howManyBallsMaxInX = (howManyBallsMaxInX / (radius * 2.5)).floor() + 1;
    }

    num howManyBallsMaxInY = size.dy - radius * 5;
    if (howManyBallsMaxInY > 0) {
      howManyBallsMaxInY = (howManyBallsMaxInY / (radius * 2.5)).floor() + 1;
    }

    bool ballCountMet() => ballCount == balls.length;
    for (num x = xRange.dx; !ballCountMet() && x < xRange.dy; x += radius * 2.5) {
      for (num y = yRange.dx; !ballCountMet() && y < yRange.dy; y += radius * 2.5) {
        balls.add(Ball.withRandomDir(radius, Offset(x, y)));
      }
    }
    return balls;
  }
}
