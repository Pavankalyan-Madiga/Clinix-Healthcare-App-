class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String gender;
  final String room;
  final String condition;
  final String status;

  const Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.room,
    required this.condition,
    required this.status,
  });

  String get fullName => '$firstName $lastName';
}