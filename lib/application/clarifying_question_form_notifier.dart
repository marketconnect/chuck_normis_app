import 'package:flutter/foundation.dart';
import 'package:chuck_normis_app/domain/models/clarifying_form.dart';

class ClarifyingQuestionFormNotifier extends ChangeNotifier {
  final ClarifyingForm form;
  final Map<String, Map<String, dynamic>> _answers = {};

  ClarifyingQuestionFormNotifier(this.form);

  Map<String, Map<String, dynamic>> get answers => _answers;

  void updateSingleAnswer(String questionId, String value) {
    _answers[questionId] = {
      'selected': [value],
      'own': _answers[questionId]?['own'] ?? '',
    };
    notifyListeners();
  }

  void toggleMultiSelectAnswer(String questionId, String option) {
    final currentAnswer =
        _answers[questionId] ?? {'selected': <String>[], 'own': ''};
    final selectedList = List<String>.from(currentAnswer['selected'] ?? []);

    if (selectedList.contains(option)) {
      selectedList.remove(option);
    } else {
      selectedList.add(option);
    }
    currentAnswer['selected'] = selectedList;
    _answers[questionId] = currentAnswer;
    notifyListeners();
  }

  void updateOwnAnswer(String questionId, String text) {
    final currentAnswer =
        _answers[questionId] ?? {'selected': <String>[], 'own': ''};
    currentAnswer['own'] = text;
    _answers[questionId] = currentAnswer;
    notifyListeners();
  }

  String _sanitizeQuestionText(FormQuestion q) {
    var t = q.text.trim();

    // Prefer to cut at the question mark if present (e.g., "1) ... ?").
    final qm = t.indexOf('?');
    if (qm != -1) {
      return t.substring(0, qm + 1).trim();
    }

    // Fallback: cut at the first colon if it looks like "Label: options".
    final colon = t.indexOf(':');
    if (colon != -1) {
      return t.substring(0, colon).trim();
    }

    // If options got embedded into the label, try to remove them by finding
    // the earliest occurrence of any option text and trimming before it.
    var earliest = t.length;
    for (final opt in q.options) {
      final idx = t.indexOf(opt.text);
      if (idx != -1 && idx < earliest) {
        earliest = idx;
      }
    }
    if (earliest != t.length) {
      t = t.substring(0, earliest).trim();
    }

    // Clean trailing separators if any remained.
    t = t.replaceAll(RegExp(r'(?:\s*[-–—/|]+\s*)$'), '').trim();
    return t;
  }

  String getFormattedAnswers() {
    final resultLines = <String>[];
    for (final question in form.questions) {
      final answerMap = _answers[question.id];
      if (answerMap == null) continue;

      final selected = (answerMap['selected'] as List<String>?) ?? [];
      final own = (answerMap['own'] as String?) ?? '';

      // Normalize "Другое"/own label for matching
      final otherLabelLower =
          (question.ownFieldLabel.isNotEmpty
                  ? question.ownFieldLabel
                  : 'Другое')
              .trim()
              .toLowerCase();

      bool isPlaceholder(String s) {
        final t = s.trim().toLowerCase();
        if (t.isEmpty) return false;
        if (t == otherLabelLower) return true;
        return t.contains('свой вариант') || t.contains('другое');
      }

      // Only include "own" text when "Другое" is selected
      final bool otherSelected = selected.any((s) {
        final t = s.trim().toLowerCase();
        return t == otherLabelLower ||
            t.contains('свой вариант') ||
            t.contains('другое');
      });

      final filteredSelected = selected
          .where((s) => !isPlaceholder(s))
          .toList();

      final answers = <String>[];
      if (filteredSelected.isNotEmpty) {
        answers.addAll(filteredSelected);
      }
      if (otherSelected && own.isNotEmpty) {
        answers.add(own);
      }

      if (answers.isNotEmpty) {
        final cleaned = _sanitizeQuestionText(question);
        resultLines.add('$cleaned - ${answers.join(', ')}');
      }
    }
    return resultLines.join('\n');
  }
}
