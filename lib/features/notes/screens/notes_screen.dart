import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notes_provider.dart';
import '../../../data/models/note_model.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}


class NoteTab {
  final NoteModel note;
  final TextEditingController controller;
  final UndoHistoryController undoController;
  NoteTab({required this.note, required this.controller, required this.undoController});
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final List<NoteTab> _tabs = [];
  int _activeTabIndex = 0;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotes());
  }

  void _loadNotes() {
    final notes = ref.read(notesProvider);
    if (notes.isEmpty) {
      // Create a fresh note
      final note = ref.read(notesProvider.notifier).addNote();
      setState(() {
        _tabs.add(NoteTab(
          note: note,
          controller: TextEditingController(text: note.content),
          undoController: UndoHistoryController(),
        ));
        _activeTabIndex = 0;
      });
    } else {
      setState(() {
        _tabs.clear();
        for (final note in notes) {
          _tabs.add(NoteTab(
            note: note,
            controller: TextEditingController(text: note.content),
            undoController: UndoHistoryController(),
          ));
        }
        _activeTabIndex = 0;
      });
    }
  }

  TextEditingController get _controller => _tabs[_activeTabIndex].controller;
  UndoHistoryController get _undoController => _tabs[_activeTabIndex].undoController;

  bool _isBold = false;
  bool _isItalic = false;
  bool _isH1 = false;

  void _showMockAction(String action) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action action triggered'),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addNewTab() {
    final note = ref.read(notesProvider.notifier).addNote();
    setState(() {
      _tabs.add(NoteTab(
        note: note,
        controller: TextEditingController(text: note.content),
        undoController: UndoHistoryController(),
      ));
      _activeTabIndex = _tabs.length - 1;
    });
  }

  void _onTextChanged(String value) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      if (_tabs.isEmpty) return;
      final tab = _tabs[_activeTabIndex];
      ref.read(notesProvider.notifier).updateNote(tab.note.id, content: value);
    });
  }

  void _showLinkDialog(bool isDark) {
    final displayCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? const Color(0xDEFFFFFF) : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Link', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Display text', style: TextStyle(fontSize: 13, color: textColor)),
            const SizedBox(height: 4),
            TextField(
              controller: displayCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Text for the link (optional)',
                hintStyle: TextStyle(color: hintColor, fontSize: 13),
                border: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD3643B))),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text('Address', style: TextStyle(fontSize: 13, color: textColor)),
            const SizedBox(height: 4),
            TextField(
              controller: addressCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Link to an existing webpage',
                hintStyle: TextStyle(color: hintColor, fontSize: 13),
                border: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD3643B))),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(right: 24, bottom: 24),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  final display = displayCtrl.text.isNotEmpty ? displayCtrl.text : addressCtrl.text;
                  if (addressCtrl.text.isNotEmpty) {
                    final text = _controller.text;
                    _controller.text = '$text${text.isEmpty ? '' : ' '}[$display](${addressCtrl.text})';
                    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
                  }
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD3643B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Insert', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  foregroundColor: textColor,
                ),
                child: Text('Cancel', style: TextStyle(color: textColor)),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _handlePrint() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Printing document...'),
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleEditAction(String val) async {
    final text = _controller.text;
    final selection = _controller.selection;

    switch (val) {
      case 'undo':
        _undoController.undo();
        break;
      case 'copy':
        if (selection.isValid && !selection.isCollapsed) {
          Clipboard.setData(ClipboardData(text: selection.textInside(text)));
        }
        break;
      case 'cut':
        if (selection.isValid && !selection.isCollapsed) {
          Clipboard.setData(ClipboardData(text: selection.textInside(text)));
          _controller.text = selection.textBefore(text) + selection.textAfter(text);
          _controller.selection = TextSelection.collapsed(offset: selection.start);
        }
        break;
      case 'paste':
        final data = await Clipboard.getData('text/plain');
        if (data != null && data.text != null) {
          if (selection.isValid) {
            _controller.text = selection.textBefore(text) + data.text! + selection.textAfter(text);
            _controller.selection = TextSelection.collapsed(offset: selection.start + data.text!.length);
          } else {
            _controller.text = text + data.text!;
            _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
          }
        }
        break;
      case 'select_all':
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
        break;
      case 'delete':
        if (selection.isValid && !selection.isCollapsed) {
          _controller.text = selection.textBefore(text) + selection.textAfter(text);
          _controller.selection = TextSelection.collapsed(offset: selection.start);
        }
        break;
    }
  }

  void _applyBlockFormatting(String prefix, RegExp replaceRegex) {
    final text = _controller.text;
    final selection = _controller.selection;

    if (text.isEmpty && prefix.isNotEmpty) {
      _controller.text = prefix;
      _controller.selection = TextSelection.collapsed(offset: prefix.length);
      return;
    }

    if (selection.isValid && !selection.isCollapsed) {
      String selectedText = selection.textInside(text);
      String before = selection.textBefore(text);
      String after = selection.textAfter(text);

      if (before.isNotEmpty && !before.endsWith('\n')) before += '\n';
      if (after.isNotEmpty && !after.startsWith('\n')) after = '\n$after';

      List<String> lines = selectedText.split('\n');
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].replaceFirst(replaceRegex, '');
        if (prefix.isNotEmpty) line = prefix + line;
        lines[i] = line;
      }
      String newSelected = lines.join('\n');

      _controller.text = before + newSelected + after;
      _controller.selection = TextSelection(baseOffset: before.length, extentOffset: before.length + newSelected.length);
    } else {
      int cursorPosition = selection.isValid ? selection.baseOffset : text.length;
      if (cursorPosition < 0) cursorPosition = text.length;

      int lineStart = cursorPosition;
      while (lineStart > 0 && text[lineStart - 1] != '\n') {
        lineStart--;
      }

      int lineEnd = cursorPosition;
      while (lineEnd < text.length && text[lineEnd] != '\n') {
        lineEnd++;
      }

      String currentLine = text.substring(lineStart, lineEnd);
      currentLine = currentLine.replaceFirst(replaceRegex, '');

      String newLineText = prefix.isEmpty ? currentLine : prefix + currentLine;
      _controller.text = text.substring(0, lineStart) + newLineText + text.substring(lineEnd);
      _controller.selection = TextSelection.collapsed(offset: lineStart + newLineText.length);
    }
  }

  void _applyInlineFormatting(String token) {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.isValid && !selection.isCollapsed) {
      String selectedText = selection.textInside(text);
      String before = selection.textBefore(text);
      String after = selection.textAfter(text);

      if (selectedText.startsWith(token) && selectedText.endsWith(token)) {
        selectedText = selectedText.substring(token.length, selectedText.length - token.length);
      } else {
        selectedText = token + selectedText + token;
      }
      _controller.text = before + selectedText + after;
      _controller.selection = TextSelection(baseOffset: before.length, extentOffset: before.length + selectedText.length);
    } else {
      if (selection.isValid) {
        String before = text.substring(0, selection.baseOffset);
        String after = text.substring(selection.baseOffset);
        _controller.text = before + token + token + after;
        _controller.selection = TextSelection.collapsed(offset: before.length + token.length);
      } else {
        _controller.text = text + token + token;
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length - token.length);
      }
    }
  }

  void _showSaveDialog(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bottomBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9F9F9);
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final textColor = isDark ? const Color(0xDEFFFFFF) : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Save as Markdown to keep formatting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    Text(
                      'This is a text file. To keep the current formatting, like bolding and headings, save it as a Markdown file (.md).',
                      style: TextStyle(fontSize: 13, height: 1.5, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'If you save as a plain text file, all formatting will be lost.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: borderColor),
              Container(
                decoration: BoxDecoration(
                  color: bottomBg,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: ElevatedButton(
                        onPressed: () {
                          context.pop();
                          _showMockAction('Saved as Markdown');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3C5A86),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save as Markdown fi...', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: OutlinedButton(
                        onPressed: () {
                          context.pop();
                          _showMockAction('Saved as Text');
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: textColor,
                        ),
                        child: Text('Save as text file', style: TextStyle(color: textColor, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: textColor,
                        ),
                        child: Text('Cancel', style: TextStyle(color: textColor, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var tab in _tabs) {
      tab.controller.dispose();
      tab.undoController.dispose();
    }
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final scaffoldBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final tabBarBg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF3F3F3);
    final activeTabBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inactiveTabBg = isDark ? const Color(0xFF141414) : const Color(0xFFE5E5E5);
    final toolbarBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final toolbarBorderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final textColor = isDark ? const Color(0xDEFFFFFF) : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;
    final iconColor = isDark ? Colors.white54 : Colors.black54;
    final editorBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    // Context menu colors
    final menuBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final menuDivider = isDark ? Colors.white12 : Colors.grey.shade200;
    final menuHover = isDark ? Colors.white10 : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Tab Bar ──────────────────────────────────────────
            Container(
              height: 48,
              color: tabBarBg,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 20, color: textColor),
                    onPressed: () => context.pop(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_tabs.length, (index) {
                          final isActive = index == _activeTabIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _activeTabIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              margin: const EdgeInsets.only(top: 8, right: 2),
                              decoration: BoxDecoration(
                                color: isActive ? activeTabBg : inactiveTabBg,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.description, size: 16,
                                      color: isActive ? const Color(0xFFD3643B) : secondaryTextColor),
                                  const SizedBox(width: 8),
                                  Text(_tabs[index].note.title,
                                      style: TextStyle(fontSize: 12, color: textColor,
                                          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal)),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (_tabs.length > 1) {
                                          _tabs[index].controller.dispose();
                                          _tabs.removeAt(index);
                                          if (_activeTabIndex >= _tabs.length) {
                                            _activeTabIndex = _tabs.length - 1;
                                          }
                                        } else {
                                          context.pop();
                                        }
                                      });
                                    },
                                    child: Icon(Icons.close, size: 14, color: secondaryTextColor),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 18, color: secondaryTextColor),
                    onPressed: _addNewTab,
                    tooltip: 'New Tab',
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // ── Menu & Formatting Toolbar ─────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: toolbarBg,
                border: Border(
                  bottom: BorderSide(color: toolbarBorderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  _PopupMenuButton(
                    title: 'File',
                    isDark: isDark,
                    items: const [
                      PopupMenuItem(value: 'new_tab', child: Text('New tab\t\t\t\t\t\t\t\t\tCtrl+N')),
                      PopupMenuItem(value: 'save', child: Text('Save\t\t\t\t\t\t\t\t\t\t\tCtrl+S')),
                      PopupMenuItem(value: 'save_as', child: Text('Save as\t\t\t\t\t\t\t\tCtrl+Shift+S')),
                      PopupMenuDivider(),
                      PopupMenuItem(value: 'print', child: Text('Print\t\t\t\t\t\t\t\t\t\t\t\tCtrl+P')),
                    ],
                    onSelected: (val) {
                      if (val == 'new_tab') {
                        _addNewTab();
                      } else if (val == 'save' || val == 'save_as') {
                        _showSaveDialog(isDark);
                      } else if (val == 'print') {
                        _handlePrint();
                      } else {
                        _showMockAction('File -> $val');
                      }
                    },
                  ),
                  _PopupMenuButton(
                    title: 'Edit',
                    isDark: isDark,
                    items: const [
                      PopupMenuItem(value: 'undo', child: Text('Undo\t\tCtrl+Z')),
                      PopupMenuItem(value: 'cut', child: Text('Cut\t\tCtrl+X')),
                      PopupMenuItem(value: 'copy', child: Text('Copy\t\tCtrl+C')),
                      PopupMenuItem(value: 'paste', child: Text('Paste\t\tCtrl+V')),
                      PopupMenuItem(value: 'delete', child: Text('Delete\t\tDel')),
                    ],
                    onSelected: _handleEditAction,
                  ),
                  const Spacer(),
                  // Formatting Tools
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        tooltip: 'Heading Style',
                        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFDF1EB),
                        offset: const Offset(0, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (val) {
                          setState(() { _isH1 = val == 'Subtitle' || val == 'Heading'; });
                          String prefix = '';
                          switch (val) {
                            case 'Title': prefix = '# '; break;
                            case 'Subtitle': prefix = '## '; break;
                            case 'Heading': prefix = '### '; break;
                            case 'Subheading': prefix = '#### '; break;
                            case 'Section': prefix = '##### '; break;
                            case 'Subsection': prefix = '###### '; break;
                            case 'Body': prefix = ''; break;
                          }
                          _applyBlockFormatting(prefix, RegExp(r'^#{1,6}\s'));
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'Title', height: 40, child: Text('Title', style: TextStyle(fontSize: 22, color: textColor, fontWeight: FontWeight.w500))),
                          PopupMenuItem(value: 'Subtitle', height: 40, child: Text('Subtitle', style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.w500))),
                          PopupMenuItem(value: 'Heading', height: 40, child: Text('Heading', style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500))),
                          PopupMenuItem(value: 'Subheading', height: 40, child: Text('Subheading', style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w500))),
                          PopupMenuItem(value: 'Section', height: 40, child: Text('Section', style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500))),
                          PopupMenuItem(value: 'Subsection', height: 40, child: Text('Subsection', style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500))),
                          PopupMenuItem(value: 'Body', height: 40, child: Row(children: [Container(width: 4, height: 16, color: const Color(0xFFD3643B), margin: const EdgeInsets.only(right: 8)), Text('Body', style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500))])),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: [
                              Text('H1', style: TextStyle(fontSize: 13, color: _isH1 ? const Color(0xFFD3643B) : secondaryTextColor, fontWeight: _isH1 ? FontWeight.bold : FontWeight.normal)),
                              const SizedBox(width: 2),
                              Icon(Icons.keyboard_arrow_down, size: 16, color: _isH1 ? const Color(0xFFD3643B) : secondaryTextColor),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'List Style',
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        offset: const Offset(0, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        position: PopupMenuPosition.under,
                        onSelected: (val) {
                          String prefix = '';
                          if (val == 'bullet') { prefix = '• '; }
                          else if (val == 'number') { prefix = '1. '; }
                          _applyBlockFormatting(prefix, RegExp(r'^(\*|-|\+|\u2022|\d+\.)\s'));
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'bullet', child: Row(children: [Container(width: 4, height: 16, color: const Color(0xFFD3643B), margin: const EdgeInsets.only(right: 8)), Text('Bulleted list', style: TextStyle(color: textColor))])),
                          PopupMenuItem(value: 'number', child: Text('Numbered list', style: TextStyle(color: textColor))),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: [
                              Icon(Icons.format_list_bulleted, size: 18, color: iconColor),
                              const SizedBox(width: 2),
                              Icon(Icons.keyboard_arrow_down, size: 16, color: iconColor),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          setState(() => _isBold = !_isBold);
                          _applyInlineFormatting('**');
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _isBold ? const Color(0xFFD3643B) : textColor)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() => _isItalic = !_isItalic);
                          _applyInlineFormatting('*');
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text('I', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, fontSize: 14, color: _isItalic ? const Color(0xFFD3643B) : textColor)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.link, size: 18, color: iconColor),
                        onPressed: () => _showLinkDialog(isDark),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Editor Area ────────────────────────────────────────
            Expanded(
              child: Container(
                color: editorBg,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: TextField(
                  controller: _controller,
                  undoController: _undoController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  autofocus: true,
                  cursorColor: const Color(0xFFD3643B),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TextStyle(
                    fontSize: _isH1 ? 24 : 14,
                    color: textColor,
                    height: 1.5,
                    fontWeight: _isBold ? FontWeight.bold : (_isH1 ? FontWeight.bold : FontWeight.normal),
                    fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                  ),
                  onChanged: _onTextChanged,
                  contextMenuBuilder: (context, editableTextState) {
                    final anchors = editableTextState.contextMenuAnchors;
                    final selection = _controller.selection;
                    final hasSelection = selection.isValid && !selection.isCollapsed;

                    // Helper: icon+label row item
                    Widget menuItem({
                      required IconData icon,
                      required String label,
                      required VoidCallback? onTap,
                    }) {
                      final enabled = onTap != null;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: enabled ? () {
                            ContextMenuController.removeAny();
                            onTap();
                          } : null,
                          hoverColor: menuHover,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            child: Row(
                              children: [
                                Icon(icon, size: 18, color: enabled ? textColor : textColor.withValues(alpha: 0.3)),
                                const SizedBox(width: 14),
                                Text(label,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: enabled ? textColor : textColor.withValues(alpha: 0.3))),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // Top row icon items
                    Widget topItem({
                      required IconData icon,
                      required String label,
                      required VoidCallback? onTap,
                    }) {
                      final enabled = onTap != null;
                      return Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: enabled ? () {
                              ContextMenuController.removeAny();
                              onTap();
                            } : null,
                            hoverColor: menuHover,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 22,
                                      color: enabled ? textColor : textColor.withValues(alpha: 0.3)),
                                  const SizedBox(height: 4),
                                  Text(label,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: enabled ? textColor : textColor.withValues(alpha: 0.3))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return CustomSingleChildLayout(
                      delegate: _ContextMenuLayoutDelegate(anchors),
                      child: Container(
                        decoration: BoxDecoration(
                          color: menuBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        width: 260,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top icon row
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                child: Row(
                                  children: [
                                    topItem(
                                      icon: Icons.content_cut,
                                      label: 'Cut',
                                      onTap: hasSelection ? () => _handleEditAction('cut') : null,
                                    ),
                                    topItem(
                                      icon: Icons.content_copy,
                                      label: 'Copy',
                                      onTap: hasSelection ? () => _handleEditAction('copy') : null,
                                    ),
                                    topItem(
                                      icon: Icons.content_paste,
                                      label: 'Paste',
                                      onTap: () => _handleEditAction('paste'),
                                    ),
                                    topItem(
                                      icon: Icons.select_all,
                                      label: 'Select all',
                                      onTap: () => _handleEditAction('select_all'),
                                    ),
                                    topItem(
                                      icon: Icons.delete_outline,
                                      label: 'Delete',
                                      onTap: hasSelection ? () => _handleEditAction('delete') : null,
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: menuDivider),
                              menuItem(
                                icon: Icons.undo,
                                label: 'Undo',
                                onTap: () => _handleEditAction('undo'),
                              ),
                              Divider(height: 1, color: menuDivider),
                              menuItem(
                                icon: Icons.table_chart_outlined,
                                label: 'Insert table',
                                onTap: () => _showMockAction('Insert table'),
                              ),
                              Divider(height: 1, color: menuDivider),
                              menuItem(
                                icon: Icons.format_bold,
                                label: 'Bold',
                                onTap: () {
                                  setState(() => _isBold = !_isBold);
                                  _applyInlineFormatting('**');
                                },
                              ),
                              menuItem(
                                icon: Icons.format_italic,
                                label: 'Italic',
                                onTap: () {
                                  setState(() => _isItalic = !_isItalic);
                                  _applyInlineFormatting('*');
                                },
                              ),
                              menuItem(
                                icon: Icons.spellcheck,
                                label: 'Spelling',
                                onTap: () => _showMockAction('Spelling'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Layout delegate that positions the context menu near the cursor/selection.
class _ContextMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final TextSelectionToolbarAnchors anchors;
  _ContextMenuLayoutDelegate(this.anchors);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final anchor = anchors.primaryAnchor;
    double x = anchor.dx;
    double y = anchor.dy;

    // Keep within bounds
    if (x + childSize.width > size.width) {
      x = size.width - childSize.width - 8;
    }
    if (y + childSize.height > size.height) {
      y = anchor.dy - childSize.height - 8;
    }
    if (x < 8) x = 8;
    if (y < 8) y = 8;

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_ContextMenuLayoutDelegate oldDelegate) =>
      oldDelegate.anchors != anchors;
}

class _PopupMenuButton extends StatelessWidget {
  final String title;
  final List<PopupMenuEntry<String>> items;
  final Function(String) onSelected;
  final bool isDark;

  const _PopupMenuButton({
    required this.title,
    required this.items,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? const Color(0xDEFFFFFF) : Colors.black87;
    final menuBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return PopupMenuButton<String>(
      tooltip: title,
      offset: const Offset(0, 30),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      color: menuBg,
      onSelected: onSelected,
      itemBuilder: (context) => items,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
