// lib/screens/notes_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../models/lecture.dart';

class NotesScreen extends StatefulWidget {
  final Lecture lecture;
  const NotesScreen({super.key, required this.lecture});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.lecture.notes;

    return Scaffold(
      backgroundColor: ScribTheme.background,
      appBar: AppBar(
        backgroundColor: ScribTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: ScribTheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lecture.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ScribTheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.lecture.subject != null)
              Text(
                widget.lecture.subject!,
                style: const TextStyle(
                    fontSize: 12, color: ScribTheme.textSecondary),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined,
                color: ScribTheme.textSecondary, size: 20),
            tooltip: 'Copy notes',
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: notes?.fullNotes ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Notes copied to clipboard'),
                    ],
                  ),
                  backgroundColor: ScribTheme.secondary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: ScribTheme.surfaceVariant, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: ScribTheme.primary,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: ScribTheme.primary,
              unselectedLabelColor: ScribTheme.textSecondary,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13),
              tabs: const [
                Tab(text: 'Notes'),
                Tab(text: 'Summary'),
                Tab(text: 'Flashcards'),
                Tab(text: 'Transcript'),
              ],
            ),
          ),
        ),
      ),
      body: notes == null
          ? _buildNoNotes()
          : TabBarView(
              controller: _tabController,
              children: [
                _NotesTab(notes: notes),
                _SummaryTab(notes: notes),
                _FlashcardsTab(flashcards: notes.flashcards),
                _TranscriptTab(transcript: widget.lecture.transcript),
              ],
            ),
    );
  }

  Widget _buildNoNotes() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined,
              color: ScribTheme.textSecondary, size: 52),
          SizedBox(height: 16),
          Text('Notes not available',
              style: TextStyle(
                  fontSize: 16, color: ScribTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Tab 1: Notes ─────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.notes});
  final LectureNotes notes;

  @override
  Widget build(BuildContext context) {
    final fullNotes = notes.fullNotes;

    if (fullNotes.isEmpty) {
      return const Center(
        child: Text('No notes content',
            style: TextStyle(color: ScribTheme.textSecondary)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _MarkdownText(content: fullNotes),
    );
  }
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Text(line.substring(2),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ScribTheme.onSurface)),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(line.substring(3),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ScribTheme.primary)),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(line.substring(4),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ScribTheme.secondary)),
        ));
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6, right: 8),
                child: Icon(Icons.circle,
                    size: 5, color: ScribTheme.textSecondary),
              ),
              Expanded(
                child: Text(
                  line.startsWith('- ')
                      ? line.substring(2)
                      : line.substring(2),
                  style: const TextStyle(
                      fontSize: 14,
                      color: ScribTheme.onSurface,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(line,
              style: const TextStyle(
                  fontSize: 14,
                  color: ScribTheme.onSurface,
                  height: 1.6)),
        ));
      }
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}

// ─── Tab 2: Summary ───────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.notes});
  final LectureNotes notes;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topics
          if (notes.topics.isNotEmpty) ...[
            const Text('Topics Covered',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ScribTheme.textSecondary,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: notes.topics
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ScribTheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: ScribTheme.secondary.withOpacity(0.3)),
                        ),
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 12,
                                color: ScribTheme.secondary,
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Summary
          if (notes.summary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ScribTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: ScribTheme.primary, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ScribTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.summarize_outlined,
                            color: ScribTheme.primary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text('Summary',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ScribTheme.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(notes.summary,
                      style: const TextStyle(
                          fontSize: 14,
                          color: ScribTheme.onSurface,
                          height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Key Points
          if (notes.keyPoints.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ScribTheme.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lightbulb_outline_rounded,
                      color: ScribTheme.secondary, size: 16),
                ),
                const SizedBox(width: 10),
                const Text('Key Points',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ScribTheme.onSurface)),
              ],
            ),
            const SizedBox(height: 12),
            ...notes.keyPoints.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(right: 12, top: 1),
                        decoration: BoxDecoration(
                          color: ScribTheme.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: ScribTheme.primary)),
                        ),
                      ),
                      Expanded(
                        child: Text(e.value,
                            style: const TextStyle(
                                fontSize: 14,
                                color: ScribTheme.onSurface,
                                height: 1.5)),
                      ),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Tab 3: Flashcards ────────────────────────────────────────────────────────

class _FlashcardsTab extends StatefulWidget {
  const _FlashcardsTab({required this.flashcards});
  final List<Flashcard> flashcards;

  @override
  State<_FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<_FlashcardsTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _flipAnim =
      Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
  );

  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _goToCard(int index) {
    if (index < 0 || index >= widget.flashcards.length) return;
    _flipController.value = 0;
    setState(() {
      _currentIndex = index;
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined,
                color: ScribTheme.textSecondary, size: 48),
            SizedBox(height: 16),
            Text('No flashcards available',
                style: TextStyle(color: ScribTheme.textSecondary)),
          ],
        ),
      );
    }

    final card = widget.flashcards[_currentIndex];
    final total = widget.flashcards.length;

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              Text('${_currentIndex + 1} / $total',
                  style: const TextStyle(
                      fontSize: 13, color: ScribTheme.textSecondary)),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / total,
                    backgroundColor: ScribTheme.surfaceVariant,
                    color: ScribTheme.primary,
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3D Flip card
        Expanded(
          child: GestureDetector(
            onTap: _flip,
            onHorizontalDragEnd: (d) {
              if (d.primaryVelocity == null) return;
              if (d.primaryVelocity! < -300) {
                _goToCard(_currentIndex + 1);
              } else if (d.primaryVelocity! > 300) {
                _goToCard(_currentIndex - 1);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (_, __) {
                  final angle = _flipAnim.value * math.pi;
                  final isShowingFront = angle < math.pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: isShowingFront
                        ? _CardFace(
                            label: 'Q',
                            labelColor: ScribTheme.primary,
                            text: card.question,
                            hint: 'Tap to reveal answer',
                            bgColor: ScribTheme.surface,
                            borderColor: ScribTheme.primary.withOpacity(0.3),
                          )
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _CardFace(
                              label: 'A',
                              labelColor: ScribTheme.secondary,
                              text: card.answer,
                              hint: 'Tap to see question',
                              bgColor: ScribTheme.secondary.withOpacity(0.06),
                              borderColor:
                                  ScribTheme.secondary.withOpacity(0.3),
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            total,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentIndex ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _currentIndex
                    ? ScribTheme.primary
                    : ScribTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentIndex > 0
                      ? () => _goToCard(_currentIndex - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 14),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ScribTheme.textSecondary,
                    side: const BorderSide(color: ScribTheme.surfaceVariant),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _currentIndex < total - 1
                      ? () => _goToCard(_currentIndex + 1)
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14),
                  label: const Text('Next'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ScribTheme.primary,
                    disabledBackgroundColor:
                        ScribTheme.surfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.label,
    required this.labelColor,
    required this.text,
    required this.hint,
    required this.bgColor,
    required this.borderColor,
  });

  final String label;
  final Color labelColor;
  final String text;
  final String hint;
  final Color bgColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Label badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: labelColor.withOpacity(0.3)),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: labelColor,
                      letterSpacing: 1)),
            ),

            const Spacer(),

            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: ScribTheme.onSurface,
                height: 1.5,
              ),
            ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.touch_app_outlined,
                    size: 13, color: ScribTheme.textSecondary),
                const SizedBox(width: 4),
                Text(hint,
                    style: const TextStyle(
                        fontSize: 12, color: ScribTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 4: Transcript ────────────────────────────────────────────────────────

class _TranscriptTab extends StatefulWidget {
  const _TranscriptTab({required this.transcript});
  final String? transcript;

  @override
  State<_TranscriptTab> createState() => _TranscriptTabState();
}

class _TranscriptTabState extends State<_TranscriptTab> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.transcript;

    if (text == null || text.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_snippet_outlined,
                color: ScribTheme.textSecondary, size: 48),
            SizedBox(height: 16),
            Text('Transcript not available',
                style: TextStyle(
                    fontSize: 15, color: ScribTheme.textSecondary)),
            SizedBox(height: 8),
            Text('Process a recording to see the transcript.',
                style:
                    TextStyle(fontSize: 13, color: ScribTheme.textSecondary)),
          ],
        ),
      );
    }

    final wordCount = text.split(RegExp(r'\s+')).length;

    return Column(
      children: [
        // Top bar with word count + copy
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
          decoration: const BoxDecoration(
            border: Border(
                bottom:
                    BorderSide(color: ScribTheme.surfaceVariant, width: 1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.text_fields_rounded,
                  color: ScribTheme.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text('$wordCount words',
                  style: const TextStyle(
                      fontSize: 13, color: ScribTheme.textSecondary)),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  setState(() => _copied = true);
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _copied = false);
                },
                icon: Icon(
                  _copied ? Icons.check_rounded : Icons.copy_outlined,
                  size: 15,
                  color: _copied ? ScribTheme.secondary : ScribTheme.primary,
                ),
                label: Text(
                  _copied ? 'Copied!' : 'Copy',
                  style: TextStyle(
                      fontSize: 13,
                      color: _copied
                          ? ScribTheme.secondary
                          : ScribTheme.primary),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SelectionArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: ScribTheme.onSurface,
                  height: 1.7,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
