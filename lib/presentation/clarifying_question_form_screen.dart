import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chuck_normis_app/application/clarifying_question_form_notifier.dart';
import 'package:chuck_normis_app/domain/models/clarifying_form.dart';

class ClarifyingQuestionFormScreen extends StatelessWidget {
  final ClarifyingForm form;

  const ClarifyingQuestionFormScreen({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClarifyingQuestionFormNotifier(form),
      child: _ClarifyingQuestionFormView(),
    );
  }
}

class _ClarifyingQuestionFormView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClarifyingQuestionFormNotifier>();
    final form = notifier.form;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Scaffold(
          appBar: AppBar(
            title: Text(form.title),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.all(16.0),
            itemCount: form.questions.length,
            itemBuilder: (context, index) {
              final question = form.questions[index];
              return _buildQuestion(context, question);
            },
            separatorBuilder: (context, index) => const Divider(height: 32),
          ),
          bottomNavigationBar: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: FilledButton(
              onPressed: () {
                final result = notifier.getFormattedAnswers();
                Navigator.of(context).pop(result);
              },
              child: const Text('Отправить'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestion(BuildContext context, FormQuestion question) {
    final notifier = context.watch<ClarifyingQuestionFormNotifier>();
    final answers = notifier.answers;
    final isMultiSelect = question.isMultiSelect;

    final currentAnswer = answers[question.id];
    final selectedOptions = List<String>.from(currentAnswer?['selected'] ?? []);

    // Add explicit "Другое" option that reveals an input when selected
    final otherLabel =
        (question.ownFieldLabel.isNotEmpty ? question.ownFieldLabel : 'Другое')
            .trim();
    final hasOther = question.hasOwnField;
    final optionsTexts = <String>[
      ...question.options.map((o) => o.text),
      if (hasOther) otherLabel,
    ];

    bool isOtherSelected() => selectedOptions.contains(otherLabel);

    final optionTiles = <Widget>[];

    if (isMultiSelect) {
      for (final text in optionsTexts) {
        final isOther = hasOther && text == otherLabel;
        optionTiles.add(
          CheckboxListTile(
            title: Text(text),
            value: selectedOptions.contains(text),
            onChanged: (_) {
              notifier.toggleMultiSelectAnswer(question.id, text);
            },
          ),
        );
        if (isOther && isOtherSelected()) {
          optionTiles.add(
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
              child: TextFormField(
                initialValue: currentAnswer?['own'] as String?,
                decoration: InputDecoration(
                  labelText: otherLabel,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  notifier.updateOwnAnswer(question.id, value);
                },
              ),
            ),
          );
        }
      }
    } else {
      for (final text in optionsTexts) {
        final isOther = hasOther && text == otherLabel;
        optionTiles.add(
          RadioListTile<String>(
            title: Text(text),
            value: text,
            groupValue: selectedOptions.isNotEmpty
                ? selectedOptions.first
                : null,
            onChanged: (value) {
              if (value != null) {
                notifier.updateSingleAnswer(question.id, value);
              }
            },
          ),
        );
        if (isOther && isOtherSelected()) {
          optionTiles.add(
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
              child: TextFormField(
                initialValue: currentAnswer?['own'] as String?,
                decoration: InputDecoration(
                  labelText: otherLabel,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  notifier.updateOwnAnswer(question.id, value);
                },
              ),
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.text, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...optionTiles,
      ],
    );
  }
}
