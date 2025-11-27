import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A debug widget to test basic drag and drop functionality
class DebugDragTarget extends StatefulWidget {
  const DebugDragTarget({super.key});

  @override
  State<DebugDragTarget> createState() => _DebugDragTargetState();
}

class _DebugDragTargetState extends State<DebugDragTarget> {
  String _status = 'Ready to test drag';
  Color _boxColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Drag Test')),
      body: Column(
        children: [
          // Draggable item
          Padding(
            padding: EdgeInsets.all(20),
            child: LongPressDraggable<String>(
              data: 'test-data',
              feedback: Container(
                width: 100,
                height: 100,
                color: Colors.red.withOpacity(0.5),
                child: Center(child: Text('Dragging')),
              ),
              childWhenDragging: Container(
                width: 100,
                height: 100,
                color: Colors.grey,
                child: Center(child: Text('Ghost')),
              ),
              onDragStarted: () {
                setState(() => _status = 'Drag started');
              },
              onDragEnd: (details) {
                setState(() => _status = 'Drag ended at ${details.offset}');
              },
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
                child: Center(child: Text('Drag me')),
              ),
            ),
          ),
          
          // Status
          Text(_status),
          
          // Drop target
          Padding(
            padding: EdgeInsets.all(20),
            child: DragTarget<String>(
              onWillAcceptWithDetails: (details) {
                return true;
              },
              onAcceptWithDetails: (details) {
                setState(() {
                  _status = 'Dropped: ${details.data}';
                  _boxColor = Colors.green;
                });
              },
              onMove: (_) {
                setState(() => _boxColor = Colors.orange);
              },
              onLeave: (_) {
                setState(() => _boxColor = Colors.blue);
              },
              builder: (context, candidates, rejected) {
                return Container(
                  width: 200,
                  height: 200,
                  color: _boxColor,
                  child: Center(
                    child: Text(
                      candidates.isNotEmpty ? 'Drop here!' : 'Target',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}