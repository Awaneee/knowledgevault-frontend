class AskRequest {
  const AskRequest({required this.question});

  final String question;

  Map<String, dynamic> toJson() => {'question': question};
}
