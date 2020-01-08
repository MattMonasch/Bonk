import 'package:flutter/material.dart';
import '../Ball.dart';
import '../extentions.dart';

// Handles the simulation's physics updates and rendering to canvas
class CollisionSim extends CustomPainter with ChangeNotifier {
  List<Ball> balls;

  Paint _paint = Paint()..color = Colors.white;

  // Flutter task manager, used for scheduling the next frame
  WidgetsFlutterBinding gameLoop = WidgetsFlutterBinding.ensureInitialized();

  /// Size of the ball pen
  Offset bounds;

  /// Returns an average time per frame using cached times in [previousFrameTimes] based on Flutter's task manager hook-in [WidgetsFlutterBinding] 
  double get rollingFrameAverage {
      return previousFrameTimes.fold(0, (acc, val) => acc + val) / 1000 /
      previousFrameTimes.length;}
  List<int> previousFrameTimes = List.filled(10, 1);

  /// Returns an average time per physics update using chaced times in [previousPhysicsTimes] collected by [timer]
  double get rollingPhysicsAverage {
      return previousPhysicsTimes.fold(0, (acc, val) => acc + val) / 1000 /
      previousPhysicsTimes.length;
  }
  List<int> previousPhysicsTimes = List.filled(10, 1);
  int previousFrameTimestamp = 0;
  int frameIndex = 0;

  Stopwatch timer = Stopwatch();
  bool paused = false;

  CollisionSim(this.balls, this.bounds): super() {
    gameLoop.addPersistentFrameCallback(updateActors);
  }

  void togglePause() {
    if(paused){
      timer.start();
      gameLoop.scheduleFrame();
    } else {
      timer.stop();
    }
    paused = !paused;
  }

  void updateActors(Duration timestamp) {
    // Begin timing the update
    timer.start();

    // Update positions
    balls.forEach((Ball ball) {
      ball.pos = (ball.pos + ball.dir).clampOnBounds(bounds - Offset(ball.radius, ball.radius));
    });
    
    // Handle collisions
    for (int i = 0; i < balls.length; i++) {
      Ball ballA = balls[i];
      bool hadCollision = false;

      // Against Top Wall
      if (!hadCollision && ballA.pos.dy <= ballA.radius) {
        ballA.dir = Offset(ballA.dir.dx, ballA.dir.dy.abs());
        hadCollision = true;
      }

      // Against Bottom Wall
      if (!hadCollision && ballA.pos.dy >= bounds.dy - ballA.radius) {
        ballA.dir = Offset(ballA.dir.dx, -1 * ballA.dir.dy.abs());
        hadCollision = true;
      }

      // Against Left Wall
      if (!hadCollision && ballA.pos.dx <= ballA.radius) {
        ballA.dir = Offset(ballA.dir.dx.abs(), ballA.dir.dy);
        hadCollision = true;
      }

      // Against Right Wall
      if (!hadCollision && ballA.pos.dx >= bounds.dx - ballA.radius) {
        ballA.dir = Offset(-1 * ballA.dir.dx.abs(), ballA.dir.dy);
        hadCollision = true;
      }

      // Against Other Actors
      for (int j = i + 1; !hadCollision && j < balls.length; j++) {
        Ball ballB = balls[j];

        if (ballB.isCollidingWith(ballA)) {
          hadCollision = true;

          // handle collision
          Offset collisionNormal = ballB.pos - ballA.pos;
          if (collisionNormal == Offset.zero) {
            collisionNormal = randomVector(); // assured to be non-zero
          }
          double dist = collisionNormal.distance;
          double overlapDist = ballA.radius + ballB.radius - dist;
          collisionNormal = collisionNormal / dist;

          // push out by overlapDist
          ballA.pos = ballA.pos - collisionNormal * overlapDist * .5;
          ballB.pos = ballB.pos + collisionNormal * overlapDist * .5;

          // compute relative velocity
          Offset relativeVelocity = ballA.dir - ballB.dir;
          double vDotN = relativeVelocity.dotProduct(collisionNormal);
          if (vDotN >= 0) {
            //compute impulse vector
            double modifiedVel =
                vDotN / (1 / 1 + 1 / 1); // vDotN / (1/massA + 1/massB)
            double j1 = modifiedVel * -2; //modifiedVel * (-1 + elasticityA)
            double j2 = modifiedVel * -2; //modifiedVel * (-1 + elasticityB)
            ballA.dir = ballA.dir +
                (collisionNormal * j1); // dir += j1/massA * collisionNormal
            ballB.dir = ballB.dir -
                (collisionNormal * j2); // dir -= j2/massB * collisionNormal
          }
        }
      }
    }

    // Set frame time
    timer.stop();
    previousFrameTimes[frameIndex] = timer.elapsedMilliseconds;
    frameIndex = (frameIndex + 1) % previousFrameTimes.length;
    timer.reset();

    // Send event that update is completed
    notifyListeners();

    // Add frame update to flutter activity handler
    gameLoop.scheduleFrame();
  }

  @override
  void paint(Canvas canvas, Size size) {
    balls.forEach((Ball b) {
      canvas.drawCircle(b.pos, b.radius, _paint);
    });
  }

  // @override
  bool shouldRepaint(CollisionSim oldDelegate) => true;
}
