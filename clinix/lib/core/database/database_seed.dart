import 'app_database.dart';

class DatabaseSeed {
  static Future<void> seed(AppDatabase database) async {
    await _seedPatients(database);
    await _seedTasks(database);
    await _seedEntityVersions(database);
  }

  static Future<void> _seedPatients(
    AppDatabase database,
  ) async {
    final existingPatients =
        await database.patientDao.getAllPatients();

    if (existingPatients.isNotEmpty) {
      return;
    }

    await database.patientDao.insertPatient(
      PatientsCompanion.insert(
        id: 'P-1001',
        firstName: 'Maria',
        lastName: 'Garcia',
        dateOfBirth: '1985-04-12',
        gender: 'Female',
        room: 'Room 101',
        condition: 'Type 2 Diabetes',
        status: 'Stable',
      ),
    );

    await database.patientDao.insertPatient(
      PatientsCompanion.insert(
        id: 'P-1002',
        firstName: 'Robert',
        lastName: 'Johnson',
        dateOfBirth: '1978-09-21',
        gender: 'Male',
        room: 'Room 103',
        condition: 'Hypertension',
        status: 'Needs Attention',
      ),
    );

    await database.patientDao.insertPatient(
      PatientsCompanion.insert(
        id: 'P-1003',
        firstName: 'Emily',
        lastName: 'Davis',
        dateOfBirth: '1992-03-18',
        gender: 'Female',
        room: 'Room 104',
        condition: 'Post Surgery',
        status: 'Stable',
      ),
    );

    await database.patientDao.insertPatient(
      PatientsCompanion.insert(
        id: 'P-1004',
        firstName: 'James',
        lastName: 'Wilson',
        dateOfBirth: '1988-11-05',
        gender: 'Male',
        room: 'Room 106',
        condition: 'Asthma',
        status: 'Stable',
      ),
    );

    await database.patientDao.insertPatient(
      PatientsCompanion.insert(
        id: 'P-1005',
        firstName: 'Sophia',
        lastName: 'Martinez',
        dateOfBirth: '1975-06-27',
        gender: 'Female',
        room: 'Room 108',
        condition: 'Cardiac Care',
        status: 'Needs Attention',
      ),
    );
  }

  static Future<void> _seedTasks(
    AppDatabase database,
  ) async {
    final existingTasks =
        await database.taskDao.getAllTasks();

    if (existingTasks.isNotEmpty) {
      return;
    }

    await database.taskDao.insertTask(
      TasksCompanion.insert(
        id: 'T-1001',
        patientId: 'P-1001',
        title: 'Check vital signs',
        description:
            'Record blood pressure, temperature and heart rate.',
        assignedTo: 'Clinical Staff',
        dueDate: 'Today 10:00 AM',
        status: 'pending',
      ),
    );

    await database.taskDao.insertTask(
      TasksCompanion.insert(
        id: 'T-1002',
        patientId: 'P-1002',
        title: 'Review patient condition',
        description:
            'Review current condition and update clinical notes.',
        assignedTo: 'Clinical Staff',
        dueDate: 'Today 11:30 AM',
        status: 'inProgress',
      ),
    );

    await database.taskDao.insertTask(
      TasksCompanion.insert(
        id: 'T-1003',
        patientId: 'P-1003',
        title: 'Post-surgery assessment',
        description:
            'Complete scheduled post-surgery assessment.',
        assignedTo: 'Clinical Staff',
        dueDate: 'Today 1:00 PM',
        status: 'pending',
      ),
    );

    await database.taskDao.insertTask(
      TasksCompanion.insert(
        id: 'T-1004',
        patientId: 'P-1004',
        title: 'Medication review',
        description:
            'Review scheduled medication tasks.',
        assignedTo: 'Clinical Staff',
        dueDate: 'Today 2:00 PM',
        status: 'completed',
      ),
    );

    await database.taskDao.insertTask(
      TasksCompanion.insert(
        id: 'T-1005',
        patientId: 'P-1005',
        title: 'Cardiac monitoring',
        description:
            'Record cardiac monitoring observations.',
        assignedTo: 'Clinical Staff',
        dueDate: 'Today 3:30 PM',
        status: 'pending',
      ),
    );
  }

  static Future<void> _seedEntityVersions(
    AppDatabase database,
  ) async {
    final patients =
        await database.patientDao.getAllPatients();

    for (final patient in patients) {
      final existing =
          await database.entityVersionsDao.getVersion(
        'PATIENT',
        patient.id,
      );

      if (existing == null) {
        await database.entityVersionsDao.createVersion(
          entityType: 'PATIENT',
          entityId: patient.id,
          version: 1,
        );
      }
    }

    final tasks =
        await database.taskDao.getAllTasks();

    for (final task in tasks) {
      final existing =
          await database.entityVersionsDao.getVersion(
        'TASK',
        task.id,
      );

      if (existing == null) {
        await database.entityVersionsDao.createVersion(
          entityType: 'TASK',
          entityId: task.id,
          version: 1,
        );
      }
    }
  }
}