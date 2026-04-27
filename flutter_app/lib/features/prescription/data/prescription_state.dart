import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prescription_service.dart';

enum PrescriptionStatus { initial, scanning, processing, ready, error }

class PrescriptionState {
  final PrescriptionStatus status;
  final List<String> medications;
  final String? extractedText;
  final String? error;
  final File? imageFile;

  const PrescriptionState({
    this.status = PrescriptionStatus.initial,
    this.medications = const [],
    this.extractedText,
    this.error,
    this.imageFile,
  });

  PrescriptionState copyWith({
    PrescriptionStatus? status,
    List<String>? medications,
    String? extractedText,
    String? error,
    File? imageFile,
  }) {
    return PrescriptionState(
      status: status ?? this.status,
      medications: medications ?? this.medications,
      extractedText: extractedText ?? this.extractedText,
      error: error ?? this.error,
      imageFile: imageFile ?? this.imageFile,
    );
  }
}

class PrescriptionNotifier extends StateNotifier<PrescriptionState> {
  final PrescriptionService _service;

  PrescriptionNotifier(this._service) : super(const PrescriptionState());

  Future<void> scanPrescription(File imageFile) async {
    state = state.copyWith(
      status: PrescriptionStatus.scanning,
      imageFile: imageFile,
    );

    try {
      state = state.copyWith(status: PrescriptionStatus.processing);

      final extractedText = await _service.uploadPrescription(imageFile);
      final medications = _service.parseMedications(extractedText);

      state = state.copyWith(
        status: PrescriptionStatus.ready,
        extractedText: extractedText,
        medications: medications,
      );
    } catch (e) {
      state = state.copyWith(
        status: PrescriptionStatus.error,
        error: e.toString(),
      );
    }
  }

  void updateMedication(int index, String newName) {
    if (index >= 0 && index < state.medications.length) {
      final updated = List<String>.from(state.medications);
      updated[index] = newName;
      state = state.copyWith(medications: updated);
    }
  }

  void removeMedication(int index) {
    if (index >= 0 && index < state.medications.length) {
      final updated = List<String>.from(state.medications)..removeAt(index);
      state = state.copyWith(medications: updated);
    }
  }

  void addMedication(String name) {
    final updated = List<String>.from(state.medications)..add(name);
    state = state.copyWith(medications: updated);
  }

  void reset() {
    state = const PrescriptionState();
  }
}

final prescriptionProvider =
    StateNotifierProvider<PrescriptionNotifier, PrescriptionState>((ref) {
      final service = ref.watch(prescriptionServiceProvider);
      return PrescriptionNotifier(service);
    });
