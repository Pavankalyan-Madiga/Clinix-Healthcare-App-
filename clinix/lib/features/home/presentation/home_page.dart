import 'dart:async';

import 'package:clinix/features/messaging/presentation/messages_page.dart';
import 'package:clinix/features/qr_scanner/presentation/qr_scanner_page.dart';
import 'package:clinix/features/tasks/presentation/tasks_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_providers.dart';
import '../../../providers/patient_providers.dart';
import '../../../shared/widgets/main_navigation.dart';
import '../../auth/presentation/profile_page.dart';
import '../../more/presentation/more_page.dart';
import '../../notes/presentation/notes_page.dart';
import '../../patients/presentation/patient_details_page.dart';
import '../../patients/presentation/patients_page.dart';
import 'widgets/home_overview_card.dart';
import 'widgets/home_quick_action.dart';
import 'widgets/recent_patient_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  Timer? _clockTimer;
  DateTime _currentDateTime = DateTime.now();

  List<dynamic> _patients = [];
  int _taskCount = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _currentDateTime = DateTime.now();
        });
      },
    );

    _loadHomeData();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    try {
      final patientRepository = ref.read(
        patientRepositoryProvider,
      );

      final database = ref.read(
        databaseProvider,
      );

      final patients =
          await patientRepository.getPatients();

      final tasks =
          await database.taskDao.getAllTasks();

      if (!mounted) {
        return;
      }

      setState(() {
        _patients = patients;
        _taskCount = tasks.length;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      debugPrint(
        '[Home] Failed to load data: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(),
      bottomNavigationBar: MainNavigation(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0) {
            _loadHomeData();
          }
        },
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 1:
        return const PatientsPage();

      case 2:
        return const TasksPage();

      case 3:
        return const MessagesPage();

      case 4:
        return const MorePage();

      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            24,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 34),

              _buildGreeting(),

              const SizedBox(height: 28),

              _buildOverview(),

              const SizedBox(height: 30),

              _buildSectionHeader(
                'Quick Actions',
              ),

              const SizedBox(height: 12),

              _buildQuickActions(),

              const SizedBox(height: 30),

              _buildSectionHeader(
                'Recent Patients',
              ),

              const SizedBox(height: 12),

              _buildRecentPatients(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Clinix',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF152A5B),
                ),
              ),
              TextSpan(
                text: 'App',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF147DE5),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const ProfilePage(),
              ),
            );
          },
          borderRadius:
              BorderRadius.circular(30),
          child: Container(
            width: 46,
            height: 46,
            decoration:
                const BoxDecoration(
              color: Color(0xFFEAF4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 28,
              color: Color(0xFF2F5D8C),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    final hour = _currentDateTime.hour;

    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning,';
    } else if (hour < 17) {
      greeting = 'Good Afternoon,';
    } else {
      greeting = 'Good Evening,';
    }

    final date =
        '${_weekdayName(_currentDateTime.weekday)}, '
        '${_monthName(_currentDateTime.month)} '
        '${_currentDateTime.day}, '
        '${_currentDateTime.year}';

    final hour12 =
        _currentDateTime.hour % 12 == 0
            ? 12
            : _currentDateTime.hour % 12;

    final minute = _currentDateTime.minute
        .toString()
        .padLeft(2, '0');

    final period =
        _currentDateTime.hour >= 12
            ? 'PM'
            : 'AM';

    final time =
        '$hour12:$minute $period';

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF152A5B),
          ),
        ),
        const Text(
          'Clinical Staff',
          style: TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF152A5B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          date,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF667494),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF667494),
          ),
        ),
      ],
    );
  }

  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return names[month - 1];
  }

  Widget _buildOverview() {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 1;
              });
            },
            child: HomeOverviewCard(
              value: _patients.length.toString(),
              label: 'Patients',
              icon: Icons.person_outline,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
            },
            child: HomeOverviewCard(
              value: _taskCount.toString(),
              label: 'Tasks',
              icon: Icons.assignment_outlined,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF152A5B),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        HomeQuickAction(
          icon: Icons.qr_code_scanner,
          label: 'Scan',
          onTap: _scanPatient,
        ),
        const SizedBox(width: 10),
        HomeQuickAction(
          icon: Icons.monitor_heart_outlined,
          label: 'Vitals',
          onTap: _openVitals,
        ),
        const SizedBox(width: 10),
        HomeQuickAction(
          icon: Icons.description_outlined,
          label: 'Notes',
          onTap: _openNotes,
        ),
        const SizedBox(width: 10),
        HomeQuickAction(
          icon: Icons.chat_bubble_outline,
          label: 'Messages',
          onTap: _openMessages,
        ),
      ],
    );
  }

  void _openVitals() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _openMessages() {
    setState(() {
      _currentIndex = 3;
    });
  }

  void _openNotes() {
    if (_patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No patients available',
          ),
        ),
      );
      return;
    }

    final patient = _patients.first;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotesPage(
          patientId: patient.id,
        ),
      ),
    );
  }

  Widget _buildRecentPatients() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_patients.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE8ECF2),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.people_outline,
              size: 42,
              color: Color(0xFF667494),
            ),
            const SizedBox(height: 12),
            const Text(
              'No patients available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF152A5B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Patients added to Clinix will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF667494),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
              child: const Text(
                'View Patients',
              ),
            ),
          ],
        ),
      );
    }

    final recentPatients =
        _patients.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8ECF2),
        ),
      ),
      child: Column(
        children: [
          for (
            int index = 0;
            index < recentPatients.length;
            index++
          ) ...[
            _buildRecentPatient(
              recentPatients[index],
            ),
            if (index <
                recentPatients.length - 1)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentPatient(
    dynamic patient,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                PatientDetailsPage(
              patient: patient,
            ),
          ),
        );
      },
      borderRadius:
          BorderRadius.circular(20),
      child: RecentPatientCard(
        name: patient.fullName,
        room: patient.room,
        condition: patient.condition,
        status: patient.status,
        needsAttention:
            patient.status ==
                'Needs Attention',
      ),
    );
  }

  Future<void> _scanPatient() async {
    final patientId =
        await Navigator.of(context)
            .push<String>(
      MaterialPageRoute(
        builder: (_) =>
            const QrScannerPage(),
      ),
    );

    if (!mounted || patientId == null) {
      return;
    }

    final patientRepository =
        ref.read(
      patientRepositoryProvider,
    );

    final patient =
        await patientRepository
            .getPatientById(
      patientId,
    );

    if (!mounted) {
      return;
    }

    if (patient == null) {
      await _showPatientNotFoundDialog(
        patientId,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PatientDetailsPage(
          patient: patient,
        ),
      ),
    );
  }

  Future<void> _showPatientNotFoundDialog(
    String patientId,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: const Text(
            'Patient Not Found',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF152A5B),
            ),
          ),
          content: Text(
            'No patient with ID $patientId was found on this device.',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF667494),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF667494),
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                if (!mounted) {
                  return;
                }

                _scanPatient();
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF147DE5),
              ),
              child: const Text(
                'Scan Again',
              ),
            ),
          ],
        );
      },
    );
  }
}