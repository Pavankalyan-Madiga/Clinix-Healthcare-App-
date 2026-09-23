import 'package:clinix/features/auth/domain/entites/staff.dart';

class StaffModel extends Staff {
  const StaffModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.department,
    required super.status,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Clinical Staff',
      department: json['department']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'status': status,
    };
  }
}
