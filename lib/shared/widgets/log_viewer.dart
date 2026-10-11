import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared log viewer with a control bar.
///
/// Features:
///  * virtualized line list (handles large logs)
///  * optional line-number gutter
///  * "go to last line" + auto-tail that sticks to the bottom on reload
///  * last-N-lines control (drives a refetch via [onLineCountChanged])
///  * timestamp toggle (drives a refetch via [onTimestampsChanged])
///  * client-side search with match highlighting + next/previous match
///  * wrap toggle, font-size stepper, copy-all
class LogViewer extends StatefulWidget {
  const LogViewer({
    super.key,
    required this.logs,
    this.emptyLabel = '(no output yet)',
    this.initialLineCount = 200,
    this.initialTimestamps = false,
    this.onLineCountChanged,
    this.onTimestampsChanged,
    this.onRefresh,
    this.showControls = true,
    this.embeddedHeight,
    this.padding = const EdgeInsets.all(10),
  });

  final String logs;
  final String emptyLabel;

  final int initialLineCount;
  final bool initialTimestamps;

  /// Called when the user picks a different "last N lines" value.
  final ValueChanged<int>? onLineCountChanged;

  /// Called when the user toggles timestamps.
  final ValueChanged<bool>? onTimestampsChanged;

  final VoidCallback? onRefresh;

  final bool showControls;

  /// When set, the log list gets a fixed height instead of expanding — use
  /// this when embedding the viewer inside a scrolling page.
  final double? embeddedHeight;

  final EdgeInsets padding;

  static const lineCountOptions = <int>[100, 200, 500, 1000];

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final _scroll = ScrollController();
  final _searchCtl = TextEditingController();

  List<String> _lines = const [];
  int _matchCount = 0;
  int _currentMatch = -1;

  bool _tail = true;
  bool _showLineNumbers = true;
  bool _wrap = true;
  bool _searching = false;
  double _fontSize = 12;
  String _query = '';

  late int _lineCount = widget.initialLineCount;
  late bool _timestamps = widget.initialTimestamps;

  static const _logColor = Color(0xFFD8E1EC);
  static const _gutterColor = Color(0xFF5A6472);
  static const _matchBg = Color(0x66FFB300);
  static const _currentMatchBg = Color(0xFFFF6F00);

  @override
  void initState() {
    super.initState();
    _lines = widget.logs.isEmpty
        ? const []
        : widget.logs.replaceAll('\r\n', '\n').split('\n');
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  void didUpdateWidget(covariant LogViewer old) {
    super.didUpdateWidget(old);
    if (old.logs != widget.logs) {
      _setLines(widget.logs);
      if (_tail) _jumpToBottom();
    }
    if (old.initialLineCount != widget.initialLineCount) {
      _lineCount = widget.initialLineCount;
    }
    if (old.initialTimestamps != widget.initialTimestamps) {
      _timestamps = widget.initialTimestamps;
    }
  }

  void _setLines(String raw) {
    setState(() {
      _lines = raw.isEmpty ? const [] : raw.replaceAll('\r\n', '\n').split('\n');
      _recountMatches();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  // ── Search ──────────────────────────────────────────────────────────────────
  void _recountMatches() {
    if (_query.isEmpty) {
      _matchCount = 0;
      _currentMatch = -1;
      return;
    }
    final q = _query.toLowerCase();
    _matchCount = _lines.where((l) => l.toLowerCase().contains(q)).length;
    _currentMatch = _matchCount > 0 ? 0 : -1;
  }

  int _indexOfMatch(String needle, {bool after = true}) {
    final q = needle.toLowerCase();
    final start = after ? _currentMatch + 1 : 0;
    final end = after ? _lines.length : (_currentMatch < 0 ? 0 : _currentMatch);
    for (var i = start; i < end; i++) {
      if (_lines[i].toLowerCase().contains(q)) return i;
    }
    for (var i = after ? 0 : _currentMatch + 1; i < _lines.length; i++) {
      if (_lines[i].toLowerCase().contains(q)) return i;
    }
    return -1;
  }

  void _scrollToLine(int index) {
    if (!_scroll.hasClients) return;
    final lineHeight = _fontSize * 1.45 + 4;
    final target = (index * lineHeight)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _nextMatch() {
    if (_query.isEmpty || _matchCount == 0) return;
    final idx = _indexOfMatch(_query);
    if (idx < 0) return;
    setState(() => _currentMatch = idx);
    _scrollToLine(idx);
  }

  void _prevMatch() {
    if (_query.isEmpty || _matchCount == 0) return;
    final q = _query.toLowerCase();
    for (var i = _currentMatch - 1; i >= 0; i--) {
      if (_lines[i].toLowerCase().contains(q)) {
        setState(() => _currentMatch = i);
        _scrollToLine(i);
        return;
      }
    }
    // wrap to last
    for (var i = _lines.length - 1; i >= 0; i--) {
      if (_lines[i].toLowerCase().contains(q)) {
        setState(() => _currentMatch = i);
        _scrollToLine(i);
        return;
      }
    }
  }

  void _copyAll() {
    Clipboard.setData(ClipboardData(text: widget.logs));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Logs copied')));
  }

  // ── Rendering ───────────────────────────────────────────────────────────────
  TextSpan _spansFor(String line) {
    final base = TextStyle(
      fontFamily: 'monospace',
      fontSize: _fontSize,
      height: 1.45,
      color: _logColor,
    );
    if (_query.isEmpty) return TextSpan(text: line, style: base);

    final q = _query.toLowerCase();
    final lower = line.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    var hitIndex = 0;
    while (true) {
      final i = lower.indexOf(q, start);
      if (i < 0) {
        if (start < line.length) {
          spans.add(TextSpan(text: line.substring(start), style: base));
        }
        break;
      }
      if (i > start) {
        spans.add(TextSpan(text: line.substring(start, i), style: base));
      }
      final end = i + q.length;
      spans.add(TextSpan(
        text: line.substring(i, end),
        style: base.copyWith(
          backgroundColor:
              hitIndex == _currentMatch ? _currentMatchBg : _matchBg,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = end;
      hitIndex++;
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showControls) _controlBar(),
        if (_searching) _searchBar(),
        _wrapBody(),
      ],
    );
  }

  Widget _wrapBody() {
    final embedded = widget.embeddedHeight;
    if (embedded != null) {
      return SizedBox(height: embedded, child: _body());
    }
    return Expanded(child: _body());
  }

  Widget _body() {
    final q = _query.toLowerCase();
    final visible = _query.isEmpty
        ? _lines
        : _lines.where((l) => l.toLowerCase().contains(q)).toList();

    return widget.logs.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                widget.emptyLabel,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          )
        : visible.isEmpty
            ? const Center(
                child: Text(
                  'No lines match your search.',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            : SelectionArea(
                child: Scrollbar(
                  controller: _scroll,
                  child: ListView.builder(
                    controller: _scroll,
                    padding: widget.padding,
                    itemCount: visible.length,
                    itemExtent: _fontSize * 1.45 + 4,
                    itemBuilder: (context, i) {
                      final line = visible[i];
                      final number = _query.isEmpty
                          ? i + 1
                          : _lines.indexOf(line) + 1;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_showLineNumbers)
                            SizedBox(
                              width: 46,
                              child: Text(
                                '$number',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  height: 1.45,
                                  color: _gutterColor,
                                ),
                              ),
                            ),
                          if (_showLineNumbers) const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              _spansFor(line),
                              softWrap: _wrap,
                              overflow: _wrap
                                  ? TextOverflow.clip
                                  : TextOverflow.visible,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
  }

  // ── Control bar ─────────────────────────────────────────────────────────────
  Widget _controlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              onPressed: _jumpToBottom,
              icon: const Icon(Icons.vertical_align_bottom),
              tooltip: 'Go to last line',
            ),
            IconButton(
              onPressed: () {
                setState(() => _tail = !_tail);
                if (_tail) _jumpToBottom();
              },
              icon: Icon(_tail ? Icons.play_circle : Icons.pause_circle),
              tooltip: _tail ? 'Auto-tail on' : 'Auto-tail off',
            ),
            _lineCountPicker(),
            const VerticalDivider(width: 12, indent: 10, endIndent: 10),
            _toggle(
              icon: _timestamps ? Icons.schedule : Icons.schedule_outlined,
              tooltip: _timestamps ? 'Hide timestamps' : 'Show timestamps',
              active: _timestamps,
              onTap: () {
                setState(() => _timestamps = !_timestamps);
                widget.onTimestampsChanged?.call(_timestamps);
              },
            ),
            _toggle(
              icon: Icons.format_list_numbered,
              tooltip: _showLineNumbers ? 'Hide line numbers' : 'Show line numbers',
              active: _showLineNumbers,
              onTap: () => setState(() => _showLineNumbers = !_showLineNumbers),
            ),
            _toggle(
              icon: Icons.wrap_text,
              tooltip: _wrap ? 'Disable wrap' : 'Enable wrap',
              active: _wrap,
              onTap: () => setState(() => _wrap = !_wrap),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _searching = !_searching;
                  if (!_searching) {
                    _query = '';
                    _searchCtl.clear();
                    _recountMatches();
                  }
                });
              },
              icon: const Icon(Icons.search),
              tooltip: 'Search logs',
            ),
            IconButton(
              onPressed: () => setState(() => _fontSize =
                  _fontSize >= 20 ? 10 : _fontSize + 1),
              icon: const Icon(Icons.text_increase),
              tooltip: 'Increase font size',
            ),
            IconButton(
              onPressed: () => setState(() => _fontSize =
                  _fontSize <= 9 ? 20 : _fontSize - 1),
              icon: const Icon(Icons.text_decrease),
              tooltip: 'Decrease font size',
            ),
            IconButton(
              onPressed: _copyAll,
              icon: const Icon(Icons.copy_all),
              tooltip: 'Copy all logs',
            ),
            if (widget.onRefresh != null)
              IconButton(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh logs',
              ),
          ],
        ),
      ),
    );
  }

  Widget _lineCountPicker() {
    return PopupMenuButton<int>(
      tooltip: 'Last N lines',
      icon: const Icon(Icons.format_list_bulleted),
      onSelected: (v) {
        setState(() => _lineCount = v);
        widget.onLineCountChanged?.call(v);
      },
      itemBuilder: (context) => [
        for (final n in LogViewer.lineCountOptions)
          PopupMenuItem(value: n, child: Text('Last $n lines')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text('$_lineCount',
            style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _toggle({
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: active ? Theme.of(context).colorScheme.primary : null),
      tooltip: tooltip,
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtl,
              autofocus: true,
              onChanged: (v) => setState(() {
                _query = v;
                _recountMatches();
              }),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search…',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtl.clear();
                          setState(() {
                            _query = '';
                            _recountMatches();
                          });
                        },
                      ),
              ),
            ),
          ),
          if (_query.isNotEmpty && _matchCount > 0) ...[
            const SizedBox(width: 8),
            Text('${_currentMatch + 1}/$_matchCount',
                style: const TextStyle(fontSize: 12)),
            IconButton(
              onPressed: _prevMatch,
              icon: const Icon(Icons.keyboard_arrow_up),
              tooltip: 'Previous match',
            ),
            IconButton(
              onPressed: _nextMatch,
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: 'Next match',
            ),
          ],
        ],
      ),
    );
  }
}