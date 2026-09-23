import 'package:clinix/providers/patient_providers.dart';
import 'package:clinix/features/patients/data/model/patient_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'patient_details_page.dart';
import 'widgets/patient_card.dart';

class PatientsPage extends ConsumerStatefulWidget {
  const PatientsPage({super.key});

  @override
  ConsumerState<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends ConsumerState<PatientsPage> {
  final TextEditingController _searchController =
      TextEditingController();

  List<PatientModel> _patients = [];
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    final repository =
        ref.read(patientRepositoryProvider);

    final patients =
        await repository.getPatients();

    if (!mounted) return;

    setState(() {
      _patients = patients;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredPatients =
        _patients.where((patient) {
      final query = _searchQuery.toLowerCase();

      return patient.fullName
              .toLowerCase()
              .contains(query) ||
          patient.id
              .toLowerCase()
              .contains(query);
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildSearch(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredPatients.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          24,
                        ),
                        itemCount:
                            filteredPatients.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(
                          height: 12,
                        ),
                        itemBuilder:
                            (context, index) {
                          final patient =
                              filteredPatients[index];

                          return PatientCard(
                            patient: patient,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PatientDetailsPage(
                                    patient: patient,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        18,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Patients',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xFF152A5B),
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.filter_list,
              color: Color(0xFF147DE5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        18,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search patients',
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF667494),
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFFE8ECF2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFFE8ECF2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFF147DE5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No patients found',
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFF667494),
        ),
      ),
    );
  }
}