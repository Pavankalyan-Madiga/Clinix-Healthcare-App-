class Note {
  final String id;
  final String patientId;
  final String content;
  final String author;
  final String createdAt;

  const Note({
    required this.id,
    required this.patientId,
    required this.content,
    required this.author,
    required this.createdAt,
  });
}