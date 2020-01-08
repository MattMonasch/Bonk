import 'package:flutter/material.dart';
import 'Ball.dart';
import 'extentions.dart';

// Handles the simulation's physics updates and rendering to canvas
class CollisionSim extends CustomPainter with ChangeNotifier {
  List<Ball> balls;
  List<List<Ball>> cells = [[]];

  Paint _paint = Paint()..color = Colors.white;
  Paint _partitionPaint = Paint()..color = Colors.black..strokeWidth = 2;

  // Flutter task manager, used for scheduling the next frame
  WidgetsFlutterBinding gameLoop = WidgetsFlutterBinding.ensureInitialized();
  
  /// Size of the ball pen
  Offset bounds;

  int _cellsInOneAxis = 1;
  int get cellsInOneAxis => _cellsInOneAxis;
  /// Set the cells for both axes. Lower bound of 1 is enforced
  set cellsInOneAxis(int val) {
    _cellsInOneAxis = val.clamp(1, double.infinity);
    updatePartitioning();
  }

  /// Returns an average time per frame using cached times in [previousFrameTimes] based on Flutter's task manager hook-in [WidgetsFlutterBinding] 
  double get rollingFrameAverage {
      return previousFrameTimes.fold(0, (acc, val) => acc + val) / 1000 /
      previousFrameTimes.length;
  }
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
  static ValueNotifier repainter = ValueNotifier(Duration());

  CollisionSim(this.balls, this.bounds): super() {
    gameLoop.addPersistentFrameCallback(updateActors);
    updatePartitioning();
  }

  /// Checks to see if the cells list needs to be updated based on changes to number of cells in a single axis
  void updatePartitioning() {
    if(cells.length != _cellsInOneAxis * _cellsInOneAxis){
      cells = List.generate(_cellsInOneAxis * _cellsInOneAxis, (_) {return [];});
    }
  }

  /// Toggles on/off the update loop
  void togglePause() {
    if(paused){
      timer.start();
      gameLoop.scheduleFrame();
    } else {
      timer.stop();
    }
    paused = !paused;
  }

  /// Increments position based on velocity and resolves collisions
  void updateActors(Duration timestamp) {
    timer.start();
    balls.forEach((Ball ball) {
      ball.pos = (ball.pos + ball.dir).clampOnBounds(bounds - Offset(ball.radius, ball.radius));
      
      int partition =
          (ball.pos.dy / (bounds.dy / _cellsInOneAxis)).floor() * _cellsInOneAxis +
          (ball.pos.dx / (bounds.dx / _cellsInOneAxis)).floor();
      cells[partition].add(ball);
    });
    
    // Handle collisions
    // For each cell, compare the actors in itself vs itself + neighbors + walls
    for(int partitionIdx = cells.length-1; partitionIdx >= 0; partitionIdx--){

      
      List<Ball> currentCell = cells[partitionIdx];
      List<Ball> comparitors = List.from(currentCell);
      
      
      bool isOnLeftEdge = partitionIdx % _cellsInOneAxis == 0;
      bool isOnRightEdge = partitionIdx % _cellsInOneAxis == _cellsInOneAxis - 1;
      bool isOnTopEdge = (partitionIdx / _cellsInOneAxis).floor() == 0;

      // Left cell
      if(!isOnLeftEdge){
        comparitors.addAll(cells[partitionIdx - 1]);
      }

      // Above/Left cell
      if(!isOnLeftEdge && !isOnTopEdge){
        comparitors.addAll(cells[partitionIdx - 1 - _cellsInOneAxis]);
      }
      
      // Above cell
      if(!isOnTopEdge){
        comparitors.addAll(cells[partitionIdx - _cellsInOneAxis]);
      }
      
      // Above/Right cell
      if(!isOnRightEdge && !isOnTopEdge){
        comparitors.addAll(cells[partitionIdx + 1 - _cellsInOneAxis]);
      }

      for (int i = 0; i < currentCell.length; i++) {
        Ball ballA = currentCell[i];
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

        // Against Other balls
        for (int j = i + 1; !hadCollision && j < comparitors.length; j++) {
          Ball ballB = comparitors[j];

          if (ballB.isCollidingWith(ballA)) {
            hadCollision = true;

            // handle collision
            Offset collisionNormal = ballB.pos - ballA.pos;
            if (collisionNormal == Offset.zero) {
              collisionNormal = randomVector();
            }
            double dist = collisionNormal.distance;
            double overlapDist = ballA.radius + ballB.radius - dist;
            collisionNormal = collisionNormal / dist;

            // collision point is average of overlapDist
            // Offset collisionPoint = .5 * (ballA.pos + (ballRadius*collisionNormal));
            // Offset collisionPoint = ((collisionNormal * ballRadius) + ballA.pos) * .5 + ((collisionNormal * ballRadius) + ballB.pos) * .5;

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
      currentCell.clear();
    }
    timer.stop();
    previousPhysicsTimes[frameIndex] = timer.elapsedMicroseconds;
    previousFrameTimes[frameIndex] = timestamp.inMicroseconds - previousFrameTimestamp;
    previousFrameTimestamp = timestamp.inMicroseconds;
    frameIndex = (frameIndex + 1) % previousFrameTimes.length;
    timer.reset();
    repainter.value = timestamp;
    notifyListeners();
    if(!paused){
      gameLoop.scheduleFrame();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw partitions
    double xCellSize = bounds.dx / _cellsInOneAxis;
    double yCellSize = bounds.dy / _cellsInOneAxis;
    for(int i = 1; i < _cellsInOneAxis; i++){
      // horizontal
      canvas.drawLine(Offset(0, yCellSize*i), Offset(bounds.dx, yCellSize*i), _partitionPaint);
      // vertical
      canvas.drawLine(Offset(xCellSize*i, 0), Offset(xCellSize*i, bounds.dy), _partitionPaint);
    }

    // Draw Balls
    balls.forEach((Ball b) {
      canvas.drawCircle(b.pos, b.radius, _paint);
    });
  }

  // @override
  bool shouldRepaint(CollisionSim oldDelegate) => true;
}
