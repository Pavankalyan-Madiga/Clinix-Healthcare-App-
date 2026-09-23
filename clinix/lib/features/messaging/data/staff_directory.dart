class StaffDirectory {
  static const List<StaffMember> staff = [
    StaffMember(
      id: 'STAFF-001',
      name: 'John Smith',
      role: 'Clinical Staff',
      department: 'Clinical Care',
    ),
    StaffMember(
      id: 'STAFF-002',
      name: 'Sarah Williams',
      role: 'Clinical Staff',
      department: 'Clinical Care',
    ),
    StaffMember(
      id: 'STAFF-003',
      name: 'Michael Brown',
      role: 'Clinical Staff',
      department: 'Clinical Care',
    ),
    StaffMember(
      id: 'STAFF-004',
      name: 'Emily Johnson',
      role: 'Clinical Staff',
      department: 'Clinical Care',
    ),
  ];

  static List<StaffMember> getOtherStaff(
    String currentStaffId,
  ) {
    return staff
        .where(
          (member) => member.id != currentStaffId,
        )
        .toList();
  }

  static StaffMember? getById(String id) {
    for (final member in staff) {
      if (member.id == id) {
        return member;
      }
    }

    return null;
  }
}

class StaffMember {
  final String id;
  final String name;
  final String role;
  final String department;

  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
  });
}