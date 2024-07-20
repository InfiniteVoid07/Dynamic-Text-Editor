//import 'dart:developer';
import 'dart:developer';
import 'dart:io';

import 'package:celebrare_project2/audio_trimmer_view.dart';
//import 'package:celebrare_project2/change.dart';
import 'package:celebrare_project2/undo_stack.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:celebrare_project2/text_mover_provider.dart';

class TextMoverScreen extends StatefulWidget {
  const TextMoverScreen({super.key});

  @override
  State<TextMoverScreen> createState() => _TextMoverScreenState();
}

class _TextMoverScreenState extends State<TextMoverScreen> {
  @override
  void initState() {
    super.initState();
    //final provider = Provider.of<TextMoverProvider>(context, listen: false);
    //provider.loadAppStateFromFirestore();
  }

  double? stackWidth;
  double? stackHeight;
  int pageIndex = 0;
  bool isSelected = false;
  String selectedText = '';
  double? startVal, endVal;
  double? startPos, endPos;
  double? textWidth;
  var changes = ChangeStack();
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TextMoverProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Text Adder',
          textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            onPressed: () async {
               FilePickerResult? result = await FilePicker.platform.pickFiles(
                 type: FileType.audio,
                 allowCompression: false,
               );
               if (result != null) {
              try {File file = File(result.files.single.path!);
                // ignore: use_build_context_synchronously
                Navigator.of(context).push(MaterialPageRoute(builder: (context) {return AudioTrimmerView(file);}),);
                
                
              } catch (e) {log(e.toString());
                
              }
                // return showDialog(
                //     context: context,
                //     builder: (BuildContext content) {
                //       return AlertDialog(
                //         content: AudioTrimmerView(file),
                //       );
                //     });
               } 
            },
            icon: const Icon(
              Icons.music_note,
              color: Colors.black, //save button
            ),
          ),
          IconButton(
            onPressed: () {
              provider.saveAppStateToFirestore();
            },
            icon: const Icon(
              Icons.save,
              color: Colors.black, //save button
            ),
          ),
          IconButton(
            onPressed: () {
              provider.loadAppStateFromFirestore();
            },
            icon: const Icon(
              Icons.replay_rounded,
              color: Colors.black, //save button
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.undo,
              color: Colors.black, //undo button
            ),
            onPressed: () {
              setState(() {
                changes.undo();
              });
              provider.undo();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.redo,
              color: Colors.black, //redo button
            ),
            onPressed: () {
              setState(() {
                changes.redo();
              });
              provider.redo();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<TextMoverProvider>(
          builder: (context, provider, _) => Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                child: PageView.builder(
                  controller: provider.pageController,
                  itemCount: provider.pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      pageIndex = index;
                      provider.currentPageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        double borderWidth = 2;
                        stackWidth = constraints.maxWidth - borderWidth;
                        stackHeight = constraints.maxHeight - borderWidth;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              isSelected = false;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.black, width: borderWidth),
                            ),
                            child: Stack(
                              children: [
                                Image.asset(
                                  'images/background_image.jpg',
                                  fit: BoxFit.cover,
                                  width: stackWidth,
                                  height: stackHeight,
                                ),
                                for (var text in provider.pages[index])
                                  Positioned(
                                    left: text.positionX,
                                    top: text.positionY,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedText = text.text;
                                          isSelected = true;
                                        });
                                      },
                                      onPanStart: (details) {
                                        isSelected = true;
                                        provider.updateStartPosition(text);
                                      },
                                      onPanUpdate: (details) {
                                        isSelected && selectedText == text.text
                                            ? provider.updateTextPosition(
                                                text,
                                                details,
                                                stackHeight!,
                                                stackWidth!)
                                            : null;
                                      },
                                      onPanEnd: (details) {
                                        provider.updateEndTextPosition(
                                            text, details);
                                      },
                                      onLongPress: () {
                                        provider.stackHeight = stackHeight!;
                                        provider.stackWidth = stackWidth!;
                                        provider.editSelectedText(
                                            context, text);
                                      },
                                      child: Stack(children: [
                                        Row(
                                          children: [
                                            Column(
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: isSelected &&
                                                              selectedText ==
                                                                  text.text
                                                          ? const Icon(
                                                              Icons.delete,
                                                              size: 20,
                                                            )
                                                          : const SizedBox
                                                              .shrink(),
                                                    ),
                                                    SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: isSelected &&
                                                              selectedText ==
                                                                  text.text
                                                          ? const Icon(
                                                              Icons.copy_all,
                                                              size: 20,
                                                            )
                                                          : const SizedBox
                                                              .shrink(),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: isSelected &&
                                                              selectedText ==
                                                                  text.text
                                                          ? Colors.black
                                                          : Colors.transparent,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    text.text,
                                                    style: TextStyle(
                                                      color: text.textColor,
                                                      fontSize: text.textSize,
                                                      fontFamily:
                                                          text.fontFamily,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.abc,
                                                  size: 20,
                                                  color: Colors.transparent,
                                                ),
                                              ],
                                            ),
                                            const Icon(
                                              Icons.abc,
                                              size: 20,
                                              color: Colors.transparent,
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: GestureDetector(
                                              onPanStart: (details) {
                                                startVal = text.textSize;
                                                startPos = text.positionX;
                                                if (pageIndex == 0) {
                                                  final textPainter =
                                                      TextPainter(
                                                    text: TextSpan(
                                                      text: text.text,
                                                      style: TextStyle(
                                                          fontSize:
                                                              text.textSize,
                                                          fontFamily:
                                                              text.fontFamily),
                                                    ),
                                                    textDirection:
                                                        TextDirection.ltr,
                                                  )..layout();
                                                  textWidth = textPainter.width;
                                                  text.positionX =
                                                      (stackWidth! -
                                                              textWidth!) /
                                                          2;
                                                }
                                              },
                                              onPanUpdate: (details) {
                                                isSelected = true;
                                                setState(() {
                                                  if (pageIndex == 0) {
                                                    final textPainter =
                                                        TextPainter(
                                                      text: TextSpan(
                                                        text: text.text,
                                                        style: TextStyle(
                                                            fontSize:
                                                                text.textSize,
                                                            fontFamily: text
                                                                .fontFamily),
                                                      ),
                                                      textDirection:
                                                          TextDirection.ltr,
                                                    )..layout();
                                                    textWidth =
                                                        textPainter.width;
                                                    text.positionX =
                                                        (stackWidth! -
                                                                textWidth!) /
                                                            2;
                                                  }
                                                  text.textSize =
                                                      text.textSize +
                                                          details.delta.dy;
                                                });
                                                if (text.textSize < 10) {
                                                  setState(() {
                                                    text.textSize = 10;
                                                  });
                                                }
                                                if (text.textSize > 50) {
                                                  setState(() {
                                                    text.textSize = 50;
                                                  });
                                                }
                                              },
                                              onPanEnd: (details) {
                                                isSelected = false;
                                                endVal = text.textSize;
                                                endPos = text.positionX;
                                                provider.updateDragTextSize(
                                                    text,
                                                    startVal!,
                                                    endVal!,
                                                    endPos!,
                                                    startPos!);
                                                if (pageIndex == 0) {
                                                  final textPainter =
                                                      TextPainter(
                                                    text: TextSpan(
                                                      text: text.text,
                                                      style: TextStyle(
                                                          fontSize:
                                                              text.textSize,
                                                          fontFamily:
                                                              text.fontFamily),
                                                    ),
                                                    textDirection:
                                                        TextDirection.ltr,
                                                  )..layout();
                                                  textWidth = textPainter.width;
                                                  text.positionX =
                                                      (stackWidth! -
                                                              textWidth!) /
                                                          2;
                                                }
                                              },
                                              child: isSelected &&
                                                      selectedText == text.text
                                                  ? const Icon(
                                                      FontAwesomeIcons.maximize,
                                                      color: Colors.black,
                                                      size: 20,
                                                    )
                                                  : const SizedBox.shrink(),
                                            ))
                                      ]),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < provider.pages.length; i++)
                    GestureDetector(
                      onTap: () {
                        //log('$pageIndex');
                        setState(() {
                          pageIndex = i;
                          provider.pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pageIndex == i ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              TextEditingController controller = TextEditingController();
              return AlertDialog(
                title: const Text('Add Text'),
                content: TextField(
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Enter text'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      provider.addText(
                          context, controller.text, stackWidth!, stackHeight!);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.mode_edit_outline_outlined),
      ),
      // persistentFooterButtons: [
      //   Center(
      //     child: GestureDetector(
      //       onTap: () {
      //         showModalBottomSheet<void>(
      //           context: context,
      //           builder: (BuildContext context) {
      //             return Consumer<TextMoverProvider>(
      //               builder: (context, provider, _) => Column(
      //                 mainAxisSize: MainAxisSize.min,
      //                 children: [
      //                   Expanded(
      //                     child: ReorderableListView(
      //                       onReorder: provider.onReorder,
      //                       children: List.generate(
      //                         provider.pages.length,
      //                         (index) {
      //                           return ListTile(
      //                             key: Key('${provider.pages[index].hashCode}'),
      //                             title: Text('Page ${index + 1}'),
      //                           );
      //                         },
      //                       ),
      //                     ),
      //                   ),
      //                   ButtonBar(
      //                     children: [
      //                       TextButton(
      //                         onPressed: () {
      //                           Navigator.of(context).pop();
      //                         },
      //                         child: const Text('Save'),
      //                       ),
      //                       TextButton(
      //                         onPressed: () {
      //                           Navigator.of(context).pop();
      //                         },
      //                         child: const Text('Close'),
      //                       ),
      //                     ],
      //                   ),
      //                 ],
      //               ),
      //             );
      //           },
      //         );
      //       },
      //       child: const Text('Customize Pages'),
      //     ),
      //   ),
      // ],
    );
  }
}
