import 'package:xml/xml.dart';

class FormOption {
  final String text;
  FormOption(this.text);
}

class FormQuestion {
  final String id;
  final String text;
  final List<FormOption> options;
  final bool isMultiSelect;
  final bool hasOwnField;
  final String ownFieldLabel;

  FormQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.isMultiSelect = false,
    this.hasOwnField = false,
    this.ownFieldLabel = 'Другое (указать)',
  });
}

class ClarifyingForm {
  final String title;
  final List<FormQuestion> questions;

  ClarifyingForm({required this.title, required this.questions});

  factory ClarifyingForm.fromXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final formElement = document.rootElement;

    // Title can be at root (<Form><Title/>) or inside the first Section (<Section><Title/>)
    final titleCandidateRoot = formElement
        .findElements('Title')
        .firstOrNull
        ?.innerText;
    final titleCandidateSection = formElement
        .findElements('Section')
        .firstOrNull
        ?.findElements('Title')
        .firstOrNull
        ?.innerText;
    final title = (titleCandidateRoot?.trim().isNotEmpty == true
        ? titleCandidateRoot!.trim()
        : (titleCandidateSection?.trim().isNotEmpty == true
              ? titleCandidateSection!.trim()
              : 'Вопросы'));

    // Legacy schema: <Questions><Question .../></Questions>
    final questionsNode = formElement.findElements('Questions').firstOrNull;
    if (questionsNode != null) {
      final questionElements = questionsNode.children
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'Question' || e.name.local == 'Item');

      final questions = questionElements
          .map((qElement) {
            final id = qElement.getAttribute('id');
            if (id == null) return null;

            final text =
                qElement.getAttribute('text') ??
                qElement.findElements('Text').firstOrNull?.innerText ??
                '';

            var optionNodes = qElement.findElements('Option');
            if (optionNodes.isEmpty) {
              optionNodes =
                  qElement
                      .findElements('Options')
                      .firstOrNull
                      ?.findElements('Option') ??
                  [];
            }
            final options = optionNodes
                .map((opt) => FormOption(opt.innerText))
                .toList();

            final ownElement = qElement.findElements('Own').firstOrNull;

            final typeAttr = qElement.getAttribute('type')?.toLowerCase();
            final isMulti = typeAttr == 'multi' || typeAttr == 'checkbox';

            return FormQuestion(
              id: id,
              text: text,
              options: options,
              isMultiSelect: isMulti,
              hasOwnField: true,
              ownFieldLabel: ownElement?.innerText ?? 'Другое (указать)',
            );
          })
          .whereType<FormQuestion>()
          .toList();

      return ClarifyingForm(title: title, questions: questions);
    }

    // New schema: <Form><Section><Field>...</Field></Section></Form>
    final sections = formElement.findElements('Section');
    if (sections.isEmpty) {
      return ClarifyingForm(title: title, questions: []);
    }

    final Map<String, FormQuestion> questionsById = {};

    // Helper: add question from a <Field> that contains a <Select>
    void _addQuestionFromSelect(XmlElement field) {
      final fieldId = field.getAttribute('id');
      if (fieldId == null) return;

      final labelText =
          field.findElements('Label').firstOrNull?.innerText ?? '';

      final select = field.findElements('Select').firstOrNull;
      if (select == null) return;

      final optionsNode = select.findElements('Options').firstOrNull;
      final optionElements =
          (optionsNode?.findElements('Option') ?? select.findElements('Option'))
              .toList();

      final options = optionElements.map((opt) {
        final text =
            opt.getAttribute('label') ??
            opt.getAttribute('value') ??
            opt.innerText;
        return FormOption(text);
      }).toList();

      // Detect multiselect flags: "multiselect" (schema), or "multiple"/checkbox fallback
      final isMulti =
          (select.getAttribute('multiselect') == 'true') ||
          (field.getAttribute('multiselect') == 'true') ||
          (select.getAttribute('multiple') == 'true') ||
          (field.getAttribute('multiple') == 'true') ||
          (select.getAttribute('type')?.toLowerCase() == 'checkbox');

      // Determine if custom ("Другое") is allowed from Options allowCustom="true"
      final allowCustom =
          optionsNode?.getAttribute('allowCustom')?.toLowerCase() == 'true';

      questionsById[fieldId] = FormQuestion(
        id: fieldId,
        text: labelText,
        options: options,
        isMultiSelect: isMulti,
        hasOwnField: allowCustom,
        ownFieldLabel: 'Другое (указать)',
      );
    }

    // Recursively parse all descendant <Field> nodes, including inside <Group>
    void _parseFieldRecursive(XmlElement field) {
      // If this field has a Select, add as a question
      _addQuestionFromSelect(field);

      // Recurse into groups
      for (final group in field.findElements('Group')) {
        for (final nested in group.findElements('Field')) {
          _parseFieldRecursive(nested);
        }
      }
    }

    // Pass 1: collect questions from any Select fields across all sections and nested groups
    for (final section in sections) {
      for (final field in section.findElements('Field')) {
        _parseFieldRecursive(field);
      }
    }

    // Helper: attach "own field" based on Text/Textarea fields with Visibility->Rule->Condition
    void _attachOwnFromText(XmlElement field) {
      final fieldId = field.getAttribute('id');
      if (fieldId == null) return;

      final hasTextChild =
          field.findElements('Text').isNotEmpty ||
          field.findElements('Textarea').isNotEmpty;
      if (!hasTextChild) {
        // Recurse into nested groups
        for (final group in field.findElements('Group')) {
          for (final nested in group.findElements('Field')) {
            _attachOwnFromText(nested);
          }
        }
        return;
      }

      final visibility = field.findElements('Visibility').firstOrNull;
      final condition = visibility
          ?.findElements('Rule')
          .firstOrNull
          ?.findElements('Condition')
          .firstOrNull;

      final ref = condition?.getAttribute('ref');
      if (ref != null && questionsById.containsKey(ref)) {
        final ownLabel =
            field.findElements('Label').firstOrNull?.innerText ?? 'Другое';
        final q = questionsById[ref]!;
        questionsById[ref] = FormQuestion(
          id: q.id,
          text: q.text,
          options: q.options,
          isMultiSelect: q.isMultiSelect,
          hasOwnField: true,
          ownFieldLabel: ownLabel,
        );
      }
    }

    // Pass 2: attach own fields using visible Text/Textarea rules
    for (final section in sections) {
      for (final field in section.findElements('Field')) {
        _attachOwnFromText(field);
      }
    }

    return ClarifyingForm(
      title: title,
      questions: questionsById.values.toList(),
    );
  }
}
