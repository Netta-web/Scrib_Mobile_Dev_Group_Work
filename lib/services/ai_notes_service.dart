// lib/services/ai_notes_service.dart
//
// Sends a transcript to Claude (Anthropic) and parses the structured
// JSON response into a LectureNotes object.
//
// ════════════════════════════════════════════════════════════════════════════
// TEAMMATE TASK (Member 3)
// 1. Refine the system prompt to improve note quality and formatting.
// 2. Add a follow-up call that generates a "quiz" (multiple-choice questions).
// 3. Add a streaming version so the UI can show notes appearing in real time.
// 4. Handle very long transcripts by splitting and merging (see TODO below).
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/lecture.dart';

class AiNotesService {
  // ─── Generate notes from transcript ───────────────────────────────────────

  Future<LectureNotes> generateNotes(String transcript) async {
    final response = await http.post(
      Uri.parse(AppConstants.generateNotesEndpoint),
      headers: {
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'transcript': transcript,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'AI notes generation failed (${response.statusCode}): ${response.body}');
    }

    final notesJson = jsonDecode(response.body) as Map<String, dynamic>;
    return LectureNotes.fromJson(notesJson);
  }

  // ─── Generate a quiz (TODO for Member 3) ─────────────────────────────────
  // Future<List<QuizQuestion>> generateQuiz(LectureNotes notes) async { ... }
}