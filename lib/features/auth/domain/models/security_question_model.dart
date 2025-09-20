import 'package:equatable/equatable.dart';

class SecurityQuestionModel extends Equatable {
  final String id;
  final String userId;
  final String question;
  final String answerHash;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SecurityQuestionModel({
    required this.id,
    required this.userId,
    required this.question,
    required this.answerHash,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SecurityQuestionModel.fromJson(Map<String, dynamic> json) {
    return SecurityQuestionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      question: json['question'] as String,
      answerHash: json['answer_hash'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'question': question,
      'answer_hash': answerHash,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [
    id,
    userId,
    question,
    answerHash,
    isActive,
    createdAt,
    updatedAt,
  ];
}

class SecurityAnswerModel extends Equatable {
  final String questionId;
  final String answer;

  const SecurityAnswerModel({required this.questionId, required this.answer});

  @override
  List<Object> get props => [questionId, answer];
}
