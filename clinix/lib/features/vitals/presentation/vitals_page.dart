import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/vital_providers.dart';
import '../data/model/vital_model.dart';
import '../domain/entities/vital.dart';
import 'widgets/vital_card.dart';

class VitalsPage extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const VitalsPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<VitalsPage> createState() =>
      _VitalsPageState();
}

class _VitalsPageState
    extends ConsumerState<VitalsPage> {
  List<VitalModel> _vitals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  Future<void> _loadVitals() async {
    final repository =
        ref.read(vitalRepositoryProvider);

    final vitals =
        await repository.getVitalsByPatientId(
      widget.patientId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _vitals = vitals;
      _loading = false;
    });
  }

  VitalModel? _latest(VitalType type) {
    for (final vital in _vitals) {
      if (vital.type == type) {
        return vital;
      }
    }

    return null;
  }

  String _formatTime(DateTime dateTime) {
    final hour =
        dateTime.hour % 12 == 0
            ? 12
            : dateTime.hour % 12;

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    final period =
        dateTime.hour >= 12 ? 'PM' : 'AM';

    return 'Today, $hour:$minute $period';
  }

  Future<void> _openAddVitals() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) {
        return _AddVitalsSheet(
          patientId: widget.patientId,
          onSaved: _loadVitals,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloodPressure =
        _latest(VitalType.bloodPressure);

    final heartRate =
        _latest(VitalType.heartRate);

    final temperature =
        _latest(VitalType.temperature);

    final oxygen =
        _latest(VitalType.oxygenSaturation);

    final respiratory =
        _latest(VitalType.respiratoryRate);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF152A5B),
            size: 20,
          ),
        ),
        title: const Text(
          'Vitals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF152A5B),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddVitals,
        backgroundColor: const Color(0xFF147DE5),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadVitals,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  100,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patientName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF152A5B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.patientId,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667494),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Latest Vitals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF152A5B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (bloodPressure != null)
                      VitalCard(
                        title: 'Blood Pressure',
                        value: bloodPressure.value,
                        unit: bloodPressure.unit,
                        icon:
                            Icons.favorite_border,
                        recordedAt:
                            _formatTime(
                          bloodPressure.recordedAt,
                        ),
                      ),
                    if (bloodPressure != null)
                      const SizedBox(height: 12),
                    if (heartRate != null)
                      VitalCard(
                        title: 'Heart Rate',
                        value: heartRate.value,
                        unit: heartRate.unit,
                        icon:
                            Icons.monitor_heart_outlined,
                        recordedAt:
                            _formatTime(
                          heartRate.recordedAt,
                        ),
                      ),
                    if (heartRate != null)
                      const SizedBox(height: 12),
                    if (temperature != null)
                      VitalCard(
                        title: 'Temperature',
                        value: temperature.value,
                        unit: temperature.unit,
                        icon: Icons.thermostat_outlined,
                        recordedAt:
                            _formatTime(
                          temperature.recordedAt,
                        ),
                      ),
                    if (temperature != null)
                      const SizedBox(height: 12),
                    if (oxygen != null)
                      VitalCard(
                        title: 'SpO₂',
                        value: oxygen.value,
                        unit: oxygen.unit,
                        icon:
                            Icons.air_outlined,
                        recordedAt:
                            _formatTime(
                          oxygen.recordedAt,
                        ),
                      ),
                    if (oxygen != null)
                      const SizedBox(height: 12),
                    if (respiratory != null)
                      VitalCard(
                        title: 'Respiratory Rate',
                        value: respiratory.value,
                        unit: respiratory.unit,
                        icon:
                            Icons.air_outlined,
                        recordedAt:
                            _formatTime(
                          respiratory.recordedAt,
                        ),
                      ),
                    if (_vitals.isEmpty)
                      _buildEmptyState(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8ECF2),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            size: 46,
            color: Color(0xFF9AA6BA),
          ),
          SizedBox(height: 14),
          Text(
            'No vitals recorded',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF152A5B),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Add the patient’s latest vital signs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF667494),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddVitalsSheet extends ConsumerStatefulWidget {
  final String patientId;
  final Future<void> Function() onSaved;

  const _AddVitalsSheet({
    required this.patientId,
    required this.onSaved,
  });

  @override
  ConsumerState<_AddVitalsSheet> createState() =>
      _AddVitalsSheetState();
}

class _AddVitalsSheetState
    extends ConsumerState<_AddVitalsSheet> {
  final _bloodPressureController =
      TextEditingController();

  final _heartRateController =
      TextEditingController();

  final _temperatureController =
      TextEditingController();

  final _oxygenController =
      TextEditingController();

  final _respiratoryController =
      TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _bloodPressureController.dispose();
    _heartRateController.dispose();
    _temperatureController.dispose();
    _oxygenController.dispose();
    _respiratoryController.dispose();
    super.dispose();
  }

  Future<void> _saveVitals() async {
    if (_saving) {
      return;
    }

    if (_bloodPressureController.text
            .trim()
            .isEmpty &&
        _heartRateController.text
            .trim()
            .isEmpty &&
        _temperatureController.text
            .trim()
            .isEmpty &&
        _oxygenController.text
            .trim()
            .isEmpty &&
        _respiratoryController.text
            .trim()
            .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter at least one vital.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final repository =
        ref.read(vitalRepositoryProvider);

    final now = DateTime.now();

    if (_bloodPressureController.text
        .trim()
        .isNotEmpty) {
      await repository.insertVital(
        VitalModel(
          id:
              'VITAL_BP_${widget.patientId}_${now.microsecondsSinceEpoch}',
          patientId: widget.patientId,
          type: VitalType.bloodPressure,
          value:
              _bloodPressureController.text.trim(),
          unit: 'mmHg',
          recordedAt: now,
          recordedBy: 'Clinical Staff',
        ),
      );
    }

    if (_heartRateController.text
        .trim()
        .isNotEmpty) {
      await repository.insertVital(
        VitalModel(
          id:
              'VITAL_HR_${widget.patientId}_${now.microsecondsSinceEpoch}',
          patientId: widget.patientId,
          type: VitalType.heartRate,
          value:
              _heartRateController.text.trim(),
          unit: 'bpm',
          recordedAt: now,
          recordedBy: 'Clinical Staff',
        ),
      );
    }

    if (_temperatureController.text
        .trim()
        .isNotEmpty) {
      await repository.insertVital(
        VitalModel(
          id:
              'VITAL_TEMP_${widget.patientId}_${now.microsecondsSinceEpoch}',
          patientId: widget.patientId,
          type: VitalType.temperature,
          value:
              _temperatureController.text.trim(),
          unit: '°C',
          recordedAt: now,
          recordedBy: 'Clinical Staff',
        ),
      );
    }

    if (_oxygenController.text
        .trim()
        .isNotEmpty) {
      await repository.insertVital(
        VitalModel(
          id:
              'VITAL_SPO2_${widget.patientId}_${now.microsecondsSinceEpoch}',
          patientId: widget.patientId,
          type: VitalType.oxygenSaturation,
          value:
              _oxygenController.text.trim(),
          unit: '%',
          recordedAt: now,
          recordedBy: 'Clinical Staff',
        ),
      );
    }

    if (_respiratoryController.text
        .trim()
        .isNotEmpty) {
      await repository.insertVital(
        VitalModel(
          id:
              'VITAL_RR_${widget.patientId}_${now.microsecondsSinceEpoch}',
          patientId: widget.patientId,
          type: VitalType.respiratoryRate,
          value:
              _respiratoryController.text.trim(),
          unit: '/min',
          recordedAt: now,
          recordedBy: 'Clinical Staff',
        ),
      );
    }

    await widget.onSaved();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Vitals saved locally.',
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String unit,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit,
        filled: true,
        fillColor: const Color(0xFFF5F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context)
                  .viewInsets
                  .bottom +
              24,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Vitals',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF152A5B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Record the latest patient observations.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF667494),
              ),
            ),
            const SizedBox(height: 24),
            _field(
              label: 'Blood Pressure',
              hint: '120/80',
              controller:
                  _bloodPressureController,
              unit: 'mmHg',
            ),
            const SizedBox(height: 14),
            _field(
              label: 'Heart Rate',
              hint: '72',
              controller:
                  _heartRateController,
              unit: 'bpm',
            ),
            const SizedBox(height: 14),
            _field(
              label: 'Temperature',
              hint: '36.8',
              controller:
                  _temperatureController,
              unit: '°C',
            ),
            const SizedBox(height: 14),
            _field(
              label: 'SpO₂',
              hint: '98',
              controller:
                  _oxygenController,
              unit: '%',
            ),
            const SizedBox(height: 14),
            _field(
              label: 'Respiratory Rate',
              hint: '16',
              controller:
                  _respiratoryController,
              unit: '/min',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed:
                    _saving ? null : _saveVitals,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF147DE5),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Vitals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}