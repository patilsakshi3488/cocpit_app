import 'package:flutter/material.dart';

class TextEditorSheet extends StatefulWidget {
  final String? initialText;
  final Color initialColor;
  final Color? initialBackgroundColor;
  final TextAlign initialAlign;

  const TextEditorSheet({
    super.key,
    this.initialText,
    this.initialColor = Colors.white,
    this.initialBackgroundColor,
    this.initialAlign = TextAlign.center,
  });

  @override
  State<TextEditorSheet> createState() => _TextEditorSheetState();
}

class _TextEditorSheetState extends State<TextEditorSheet> {
  late TextEditingController _controller;
  late Color _color;
  Color? _backgroundColor;
  late TextAlign _align;

  final List<Color> _colors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _color = widget.initialColor;
    _backgroundColor = widget.initialBackgroundColor;
    _align = widget.initialAlign;
  }

  void _toggleBackground() {
    setState(() {
      if (_backgroundColor == null) {
        // Mode 1: Text Color with translucent black background
        _backgroundColor = Colors.black45;
      } else if (_backgroundColor == Colors.black45) {
        // Mode 2: Filled with Text Color (inverted)
        _backgroundColor = _color == Colors.white ? Colors.black : Colors.white;
      } else {
        // Mode 0: None
        _backgroundColor = null;
      }
    });
  }

  void _toggleAlign() {
    setState(() {
      if (_align == TextAlign.left) {
        _align = TextAlign.center;
      } else if (_align == TextAlign.center) {
        _align = TextAlign.right;
      } else {
        _align = TextAlign.left;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // We adjust the top padding manually to ensure buttons are reachable below notches/status bars
    return Scaffold(
      backgroundColor: Colors.transparent, // Fully transparent to show image
      body: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            // Header: Added extra top spacing for "Instagram-like" feel (lower down)
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side controls
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _align == TextAlign.left
                              ? Icons.format_align_left
                              : _align == TextAlign.right
                              ? Icons.format_align_right
                              : Icons.format_align_center,
                          color: Colors.white,
                        ),
                        onPressed: _toggleAlign,
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "A",
                            style: TextStyle(
                              color: _backgroundColor == null
                                  ? Colors.white
                                  : (_backgroundColor == Colors.white
                                        ? Colors.black
                                        : Colors.white),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onPressed: _toggleBackground,
                      ),
                    ],
                  ),

                  // Done Button
                  TextButton(
                    onPressed: () {
                      if (_controller.text.trim().isEmpty) {
                        Navigator.pop(context); // Cancel
                      } else {
                        Navigator.pop(context, {
                          'text': _controller.text,
                          'color': _color,
                          'backgroundColor': _backgroundColor,
                          'align': _align,
                        });
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Input Area
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      textAlign: _align,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 32,
                        color: _color,
                        backgroundColor: _backgroundColor,
                      ),
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      cursorColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Keyboard/Color Bar
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  return GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == color
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Push content up when keyboard opens
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
