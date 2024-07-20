import 'dart:collection';
import 'change.dart';

class ChangeStack {

  final Queue<List<Change>> undoQueue = ListQueue();
  final Queue<List<Change>> redoQueue = ListQueue();

  void add<T>(Change<T> change) {
    try {
      change.execute();
      undoQueue.addLast([change]);
      redoQueue.clear();
    } catch (e) {
      rethrow;
    }
  }

  void clearHistory() {
    undoQueue.clear();
    redoQueue.clear();
  }

  void redo() {
    if (redoQueue.isNotEmpty) {
      final changes = redoQueue.removeFirst();
      for (final change in changes) {
        change.execute();
      }
      undoQueue.addLast(changes);
    }
  }

  void undo() {
    if (undoQueue.isNotEmpty) {
      final changes = undoQueue.removeLast();
      for (final change in changes) {
        change.undo();
      }
      redoQueue.addFirst(changes);
    }
  }
}
