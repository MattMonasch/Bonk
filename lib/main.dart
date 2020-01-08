import 'package:flutter/material.dart';

import 'Ball.dart';
import 'CollisionSim.dart';
import 'UpdatingText.dart';

void main() => runApp(Bonk());

/// Runs a simple physics demonstration with toggleable amounts of balls and configurable spatial partitioning
class Bonk extends StatelessWidget {
  static final Offset penBounds = Offset(400, 400);
  static final double ballRadius = 2;
  static final int initialActorCount = 300;
  final CollisionSim physicsSim;
  

  Bonk()
      : physicsSim = CollisionSim(
            Ball.fitIntoBoard(penBounds, initialActorCount, ballRadius),
            penBounds);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: MaterialApp(
        title: 'Bonk',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          buttonTheme: ButtonThemeData(
            minWidth: 20,
          ),
        ),
        home: DefaultTextStyle(
          style: TextStyle(
              decoration: TextDecoration.none,
              color: Colors.white,
              fontSize: 36.0),
          child: Center(
            child: Column(
              children: [
                // ms taken for update loop and FPS
                UpdatingWidget(
                    builder: (BuildContext context) {
                      double frameAvg = physicsSim.rollingFrameAverage;
                      double fps = 1000 / frameAvg;
                      double physicsAvg = physicsSim.rollingPhysicsAverage;
                      return Container(
                        padding: EdgeInsets.only(top: 24),
                        child: SizedBox(
                          height: 100,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Text("GameLoop", style: TextStyle(fontSize: 12)),
                              Text(
                                "${frameAvg.floor()} ms\n"
                                "${fps.floor()} fps",
                              ),
                              Text("Just Physics", style: TextStyle(fontSize: 12)),
                              Text(
                                "${physicsAvg.toStringAsPrecision(3)} ms",
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    trigger: physicsSim),
                // Canvas that draws and calculates the current state of the physics demo
                SizedBox(
                  width: penBounds.dx,
                  height: penBounds.dy,
                  child: Stack(
                    children: [
                      Container(color: Colors.blueGrey),
                      CustomPaint(
                        painter: physicsSim,
                        willChange: true,
                      ),
                    ],
                  ),
                ),
                // Controls for the physics demo
                Center(
                  child: SizedBox(
                    height: 100,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Pause Button
                        RaisedButton(
                            color: Colors.grey,
                            child: Icon(
                                physicsSim.paused ? Icons.play_arrow : Icons.pause,
                                color: Colors.black87),
                            onPressed: physicsSim.togglePause),
                        // Text input for number of actors in physics demo
                        Flexible(
                            child: SizedBox(
                          width: 100,
                          child: Container(
                            padding: EdgeInsets.only(left: 5),
                            child: TextFormField(
                                style: TextStyle(color: Colors.white),
                                initialValue: physicsSim.balls.length.toString(),
                                onChanged: (val) => physicsSim.balls =
                                    Ball.fitIntoBoard(
                                        penBounds, int.parse(val), 2)),
                          ),
                        )),
                        // Up/Down arrows for number of partitions in a single axis
                        Column(
                          children: <Widget>[
                            RaisedButton(
                                color: Colors.grey,
                                child: Icon(Icons.arrow_upward,
                                    color: Colors.black87),
                                onPressed: () {
                                  physicsSim.cellsInOneAxis++;
                                }),
                            RaisedButton(
                                color: Colors.grey,
                                child: Icon(Icons.arrow_downward,
                                    color: Colors.black87),
                                onPressed: () {
                                  physicsSim.cellsInOneAxis--;
                                })
                          ],
                        ),
                        // Display for number of partitions in a single axis
                        UpdatingWidget(
                            builder: (context) => Container(
                                padding: EdgeInsets.only(left: 5),
                                child: Text(physicsSim.cellsInOneAxis.toString())),
                            trigger: physicsSim)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
