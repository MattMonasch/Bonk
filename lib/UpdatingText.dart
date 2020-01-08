import 'package:flutter/material.dart';

typedef WidgetBuildFunction = Widget Function(BuildContext context);

class UpdatingWidget extends StatefulWidget {
  final WidgetBuildFunction builder;
  final ChangeNotifier trigger;
  UpdatingWidget({this.builder, this.trigger});

  State<UpdatingWidget> createState() => UpdatingWidgetState(builder, trigger);
}

class UpdatingWidgetState extends State<UpdatingWidget>{
  WidgetBuildFunction widgetBuilder;
  ChangeNotifier trigger;
  UpdatingWidgetState(
    this.widgetBuilder,
    this.trigger){
      this.trigger.addListener(update);
    }

  void update(){
    setState((){});
  }
  @override
  Widget build(BuildContext context){
    return widgetBuilder(context);
  }
}