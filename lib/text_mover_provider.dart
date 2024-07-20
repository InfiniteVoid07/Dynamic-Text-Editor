//import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:celebrare_project2/text_data.dart';
import 'package:uuid/uuid.dart';
import 'change.dart';
import 'package:celebrare_project2/undo_stack.dart';

class TextMoverProvider extends ChangeNotifier {
  String selectedFont = 'Arial';
  int currentPageIndex = 0;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final PageController pageController = PageController();
  List<List<TextData>> pages = List.generate(3, (_) => []);
  TextEditingController textController = TextEditingController();
  var changes = ChangeStack();
  late double startX;
  late double startY;
  late double stackHeight;
  late double stackWidth;

  Future<void> saveAppStateToFirestore() async {
    try {
      for (int i = 0; i < pages.length; i++) {
        await firestore
            .collection('textData')
            .doc('page$i')
            .collection('Texts')
            .get()
            .then((snapshot) {
          for (DocumentSnapshot ds in snapshot.docs) {
            ds.reference.delete();
          }
        });
      }
      for (int i = 0; i < pages.length; i++) {
        for (int j = 0; j < pages[i].length; j++) {
          await firestore
              .collection('textData')
              .doc('page$i')
              .collection('Texts')
              .doc('text$j')
              .set(pages[i][j].toMap());
        }
      }
    } catch (e) {
      // print('Failed to save app state: $e');
    }
  }

  Future<void> loadAppStateFromFirestore() async {
    try {
      for (int i = 0; i < pages.length; i++) {
        DocumentSnapshot<Map<String, dynamic>> snapshot = await firestore
            .collection('textData')
            .doc('page$i')
            .collection('Texts')
            .doc('text0')
            .get();
        if (snapshot.exists) {
          Map<String, dynamic>? appStateMap = snapshot.data();
          if (appStateMap != null) {
            QuerySnapshot textSnapshot = await firestore
                .collection('textData')
                .doc('page$i')
                .collection('Texts')
                .get();

            pages[i] = textSnapshot.docs
                .map((doc) =>
                    TextData.fromMap(doc.data() as Map<String, dynamic>))
                .toList();
          }
          notifyListeners();
        } else {}
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  void undo() {
    changes.undo();
    notifyListeners();
  }

  void redo() {
    changes.redo();
    notifyListeners();
  }

  void addText(
      BuildContext context, String text, double stackX, double stackY) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 20, fontFamily: selectedFont),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final textWidth = textPainter.width;
    TextData textData = TextData(
      id: const Uuid().v4(),
      fontFamily: '',
      text: '',
      textColor: Colors.black,
      textSize: 0,
      positionX: (stackX - textWidth) / 2,
      positionY: stackY / 2,
    );
    changes.add(
      Change(
          TextData(
            id: textData.id,
            fontFamily: textData.fontFamily,
            text: textData.text,
            textColor: textData.textColor,
            textSize: textData.textSize,
            positionX: textData.positionX,
            positionY: textData.positionY,
          ),
          () => {
                textData.id = const Uuid().v4(),
                textData.fontFamily = selectedFont,
                textData.text = text,
                textData.textColor = Colors.black,
                textData.textSize = 20.0,
                textData.positionX = (stackX - textWidth) / 2,
                textData.positionY = stackY / 2,
              },
          (oldVal) => {
                textData.id = oldVal.id,
                textData.fontFamily = oldVal.fontFamily,
                textData.text = oldVal.text,
                textData.textColor = oldVal.textColor,
                textData.textSize = oldVal.textSize,
                textData.positionX = oldVal.positionX,
                textData.positionY = oldVal.positionY,
              }),
    );
    pages[currentPageIndex].add(textData);
    notifyListeners();
  }

  void updateText(TextData textData, String newText) {
    changes.add(
      Change(
          textData.text,
          () => {
                textData.text = newText,
              },
          (oldVal) => {
                textData.text = oldVal,
              }),
    );
    notifyListeners();
  }

  void updateTextColor(TextData textData, Color newColor) {
    changes.add(
      Change(
          textData.textColor,
          () => {
                textData.textColor = newColor,
              },
          (oldVal) => {
                textData.textColor = oldVal,
              }),
    );
    notifyListeners();
  }

  void updateTextSize(TextData textData, double newSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: textData.text,
        style: TextStyle(fontSize: newSize, fontFamily: selectedFont),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final textWidth = textPainter.width;
    changes.add(
      Change(
          [
            textData.textSize,
            textData.positionX,
          ],
          () => {
                textData.textSize = newSize,
                currentPageIndex == 0
                    ? textData.positionX = (stackWidth - textWidth) / 2
                    : textData.positionX = textData.positionX,
              },
          (oldVal) => {
                textData.textSize = oldVal[0],
                textData.positionX = oldVal[1],
              }),
    );
    notifyListeners();
  }

  void updateDragTextSize(TextData textData, double startVal, double endVal,
      double endPos, double startPos) {
    changes.add(Change(
      [
        textData.textSize,
        textData.positionX,
      ],
      () => {
        textData.textSize = endVal,
        textData.positionX = endPos,
      },
      (oldval) => {
        textData.textSize = startVal,
        textData.positionX = startPos,
      },
    ));
    notifyListeners();
  }

  void updateTextFont(TextData textData, String newFont) {
    changes.add(
      Change(
          textData.fontFamily,
          () => {
                textData.fontFamily = newFont,
              },
          (oldVal) => {
                textData.fontFamily = oldVal,
              }),
    );
    notifyListeners();
  }

  void updateStartPosition(TextData text) {
    startX = text.positionX;
    startY = text.positionY;
  }

  void updateTextPosition(TextData textData, DragUpdateDetails details,
      double stackHeight, double stackWidth) {
    double newX;
    double newY;
    if (currentPageIndex == 0) {
      newX = textData.positionX;
      newY = textData.positionY + details.delta.dy;
    } else {
      newX = textData.positionX + details.delta.dx;
      newY = textData.positionY + details.delta.dy;
    }
    final textPainter = TextPainter(
      text: TextSpan(
        text: textData.text,
        style: TextStyle(fontSize: textData.textSize, fontFamily: selectedFont),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final textWidth = textPainter.width;
    final textHeight = textPainter.height;
    newX = newX.clamp(0.0, stackWidth - textWidth);
    newY = newY.clamp(-20.0, stackHeight - textHeight - 30);
    textData.positionX = newX;
    textData.positionY = newY;
    notifyListeners();
  }

  void updateEndTextPosition(TextData textData, DragEndDetails details) {
    double endX = textData.positionX;
    double endY = textData.positionY;
    changes.add(
      Change(
        [startX, startY],
        () => {textData.positionX = endX, textData.positionY = endY},
        (oldVal) => {
          textData.positionX = oldVal[0],
          textData.positionY = oldVal[1],
        },
      ),
    );
    notifyListeners();
  }

  void editSelectedText(BuildContext context, TextData text) {
    Map<String, Color> colors = {
      'Black': Colors.black,
      'White': Colors.white,
      'Red': Colors.red,
      'Blue': Colors.blue,
      'Green': Colors.green,
      'Orange': Colors.orange,
      'Purple': Colors.purple,
      'Yellow': Colors.yellow,
    };

    Color tempTextColor = Colors.black;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Text'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      controller: textController,
                      onEditingComplete: () =>
                          updateText(text, textController.text),
                      decoration:
                          const InputDecoration(labelText: 'Enter text'),
                    ),
                    const SizedBox(height: 10),
                    const Text('Text Color:'),
                    const SizedBox(height: 5),
                    DropdownButton<Color>(
                      value: tempTextColor,
                      underline: Container(
                        height: 2,
                        color: Colors.black,
                      ),
                      onChanged: (Color? value) {
                        updateTextColor(text, value as Color);
                        setState(() {
                          tempTextColor = value;
                        });
                      },
                      items: colors.keys
                          .map<DropdownMenuItem<Color>>((String value) {
                        return DropdownMenuItem<Color>(
                          value: colors[value],
                          child: Row(
                            children: [
                              Container(
                                height: 24,
                                width: 24,
                                color: colors[value],
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(value)
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    const Text('Text Size:'),
                    Slider(
                        activeColor: Colors.black,
                        value: text.textSize,
                        onChanged: (double newSize) {},
                        // onChangeStart: (double newSize) {
                        //   updateTextSize(text, newSize);
                        // },
                        onChangeEnd: (double newSize) {
                          setState(() {
                            updateTextSize(text, newSize);
                          });
                        },
                        min: 10,
                        max: 60,
                        divisions: 10,
                        label: text.textSize.toString()),
                    const SizedBox(height: 10),
                    const Text('Font Selection:'),
                    DropdownButton<String>(
                      value: text.fontFamily,
                      onChanged: (String? newValue) {
                        setState(() {
                          updateTextFont(text, newValue!);
                        });
                      },
                      items: <String>[
                        'Arial',
                        'Times New Roman',
                        'Courier New',
                        'Roboto',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(fontFamily: value),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final page = pages.removeAt(oldIndex);
    pages.insert(newIndex, page);
    changes.clearHistory();
    notifyListeners();
  }
}
