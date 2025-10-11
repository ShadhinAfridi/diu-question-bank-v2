enum QuestionStatus {
  unapproved,
  approved,
  rejected,
}

extension QuestionStatusExtension on QuestionStatus {
  String get value {
    switch (this) {
      case QuestionStatus.unapproved:
        return 'unapproved';
      case QuestionStatus.approved:
        return 'approved';
      case QuestionStatus.rejected:
        return 'rejected';
    }
  }
}