import 'package:flutter/material.dart';

import '../domain/entities/patient.dart';
import '../../notes/presentation/notes_page.dart';
import '../../voice_notes/presentation/voice_notes_page.dart';
import '../../vitals/presentation/vitals_page.dart';
import '../../wound_documentation/presentation/wound_photos_page.dart';

class PatientDetailsPage extends StatelessWidget {
  final Patient patient;

  const PatientDetailsPage({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF152A5B),
          ),
        ),
        title: const Text(
          'Patient Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF152A5B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfile(),

            const SizedBox(height: 24),

            _buildSectionTitle('Demographics'),
            const SizedBox(height: 12),
            _buildDemographics(),

            const SizedBox(height: 24),

            _buildSectionTitle('Clinical Information'),
            const SizedBox(height: 12),
            _buildClinicalInformation(),

            const SizedBox(height: 24),

            _buildSectionTitle('Vitals'),
            const SizedBox(height: 12),
            _buildVitalsButton(context),

            const SizedBox(height: 24),

            _buildSectionTitle('Tasks'),
            const SizedBox(height: 12),
            _buildTasks(),

            const SizedBox(height: 24),

            _buildSectionTitle('Notes'),
            const SizedBox(height: 12),
            _buildNotesButton(context),

            const SizedBox(height: 12),

            _buildVoiceNotesButton(context),

            const SizedBox(height: 12),

            _buildWoundPhotosButton(context),

            const SizedBox(height: 24),

            _buildSectionTitle('Recent Activity'),
            const SizedBox(height: 12),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final needsAttention =
        patient.status == 'Needs Attention';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 42,
              color: Color(0xFF147DE5),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            patient.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF152A5B),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            patient.id,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF667494),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: needsAttention
                  ? const Color(0xFFFFEEEE)
                  : const Color(0xFFEAF9F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              patient.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: needsAttention
                    ? const Color(0xFFE04444)
                    : const Color(0xFF18A567),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF152A5B),
      ),
    );
  }

  Widget _buildDemographics() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _infoRow(
            'Date of Birth',
            patient.dateOfBirth,
          ),
          const Divider(height: 24),
          _infoRow(
            'Gender',
            patient.gender,
          ),
          const Divider(height: 24),
          _infoRow(
            'Room',
            patient.room,
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalInformation() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: _infoRow(
        'Condition',
        patient.condition,
      ),
    );
  }

  Widget _buildVitalsButton(
    BuildContext context,
  ) {
    return _actionCard(
      icon: Icons.monitor_heart_outlined,
      title: 'Patient Vitals',
      subtitle: 'View and record vital signs',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VitalsPage(
              patientId: patient.id,
              patientName: patient.fullName,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasks() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _taskRow(
            'Check vital signs',
            'Due today',
            false,
          ),
          const Divider(height: 24),
          _taskRow(
            'Review patient notes',
            'Completed',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesButton(
    BuildContext context,
  ) {
    return _actionCard(
      icon: Icons.note_alt_outlined,
      title: 'Clinical Notes',
      subtitle: 'View and add patient notes',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotesPage(
              patientId: patient.id,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceNotesButton(
    BuildContext context,
  ) {
    return _actionCard(
      icon: Icons.mic_none,
      title: 'Voice Notes',
      subtitle: 'Record and manage voice notes',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoiceNotesPage(
              patientId: patient.id,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWoundPhotosButton(
    BuildContext context,
  ) {
    return _actionCard(
      icon: Icons.camera_alt_outlined,
      title: 'Wound Photos',
      subtitle: 'Capture and manage wound photos',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WoundPhotosPage(
              patientId: patient.id,
            ),
          ),
        );
      },
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF147DE5),
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF152A5B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF667494),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Color(0xFF667494),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _activityRow(
            Icons.edit_note,
            'Patient information updated',
            'Today, 10:30 AM',
          ),
          const SizedBox(height: 20),
          _activityRow(
            Icons.assignment_outlined,
            'Task completed',
            'Yesterday, 4:15 PM',
          ),
          const SizedBox(height: 20),
          _activityRow(
            Icons.note_alt_outlined,
            'Clinical note added',
            'Yesterday, 2:20 PM',
          ),
          const SizedBox(height: 20),
          _activityRow(
            Icons.camera_alt_outlined,
            'Wound documentation',
            'Photos can be captured offline',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF667494),
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF152A5B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _taskRow(
    String title,
    String status,
    bool completed,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: completed
                ? const Color(0xFFEAF9F2)
                : const Color(0xFFEAF4FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            completed
                ? Icons.check
                : Icons.assignment_outlined,
            size: 20,
            color: completed
                ? const Color(0xFF18A567)
                : const Color(0xFF147DE5),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF152A5B),
            ),
          ),
        ),

        Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: completed
                ? const Color(0xFF18A567)
                : const Color(0xFF667494),
          ),
        ),
      ],
    );
  }

  Widget _activityRow(
    IconData icon,
    String title,
    String time,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF4FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF147DE5),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF152A5B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF667494),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFFE8ECF2),
      ),
    );
  }
}