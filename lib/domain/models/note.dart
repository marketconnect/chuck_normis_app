import 'dart:convert';

class Note {
  final String id;
  String type;
  DateTime createdAt;
  String textContent;
  List<String> tags;
  String? moodEmoji;
  List<String> photoPaths;
  bool isHiddenFromAi;
  String? workoutId;
  String? workoutName; // For display purposes

  Note({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.textContent,
    this.tags = const [],
    this.moodEmoji,
    this.photoPaths = const [],
    this.isHiddenFromAi = false,
    this.workoutId,
    this.workoutName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'date': createdAt.toIso8601String().substring(0, 10),
      'time': createdAt.toIso8601String().substring(11, 19),
      'text_content': textContent,
      'tags': jsonEncode(tags),
      'mood_emoji': moodEmoji,
      'photo_path': jsonEncode(
        photoPaths,
      ), // Storing list of paths as JSON string
      'is_hidden_from_ai': isHiddenFromAi ? 1 : 0,
      'workout_id': workoutId,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      type: map['type'],
      createdAt: DateTime.parse(map['created_at']),
      textContent: map['text_content'],
      tags: List<String>.from(jsonDecode(map['tags'] ?? '[]')),
      moodEmoji: map['mood_emoji'],
      photoPaths: List<String>.from(jsonDecode(map['photo_path'] ?? '[]')),
      isHiddenFromAi: map['is_hidden_from_ai'] == 1,
      workoutId: map['workout_id'],
      workoutName:
          map['workout_name'], // This will be joined from training_sessions
    );
  }

  Note copyWith({
    String? id,
    String? type,
    DateTime? createdAt,
    String? textContent,
    List<String>? tags,
    String? moodEmoji,
    List<String>? photoPaths,
    bool? isHiddenFromAi,
    String? workoutId,
    String? workoutName,
  }) {
    return Note(
      id: id ?? this.id,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      textContent: textContent ?? this.textContent,
      tags: tags ?? this.tags,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      photoPaths: photoPaths ?? this.photoPaths,
      isHiddenFromAi: isHiddenFromAi ?? this.isHiddenFromAi,
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
    );
  }
}
