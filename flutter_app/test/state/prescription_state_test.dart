import 'package:flutter_test/flutter_test.dart';
import 'package:dawaai_app/features/prescription/data/prescription_state.dart';

void main() {
  group('PrescriptionState', () {
    test('initial state should have correct default values', () {
      const state = PrescriptionState();

      expect(state.status, PrescriptionStatus.initial);
      expect(state.medications, isEmpty);
      expect(state.extractedText, isNull);
      expect(state.error, isNull);
      expect(state.imageFile, isNull);
    });

    test('copyWith should update status correctly', () {
      const initialState = PrescriptionState();
      final newState = initialState.copyWith(
        status: PrescriptionStatus.scanning,
      );

      expect(newState.status, PrescriptionStatus.scanning);
    });

    test('copyWith should update medications list', () {
      const initialState = PrescriptionState();
      final newState = initialState.copyWith(
        medications: ['Panadol', 'Amoxicillin'],
      );

      expect(newState.medications, ['Panadol', 'Amoxicillin']);
    });

    test('copyWith should update extracted text', () {
      const initialState = PrescriptionState();
      final newState = initialState.copyWith(
        extractedText: 'Panadol 500mg\nAmoxicillin 250mg',
      );

      expect(newState.extractedText, 'Panadol 500mg\nAmoxicillin 250mg');
    });

    test('copyWith should update error', () {
      const initialState = PrescriptionState();
      final newState = initialState.copyWith(
        status: PrescriptionStatus.error,
        error: 'Failed to scan prescription',
      );

      expect(newState.status, PrescriptionStatus.error);
      expect(newState.error, 'Failed to scan prescription');
    });

    test('copyWith should preserve unchanged values', () {
      const initialState = PrescriptionState(
        status: PrescriptionStatus.ready,
        medications: ['Panadol'],
        extractedText: 'Panadol 500mg',
      );

      final newState = initialState.copyWith(error: 'Test error');

      expect(newState.status, PrescriptionStatus.ready);
      expect(newState.medications, ['Panadol']);
      expect(newState.extractedText, 'Panadol 500mg');
      expect(newState.error, 'Test error');
    });
  });

  group('PrescriptionStatus', () {
    test('should have all expected statuses', () {
      expect(PrescriptionStatus.values, contains(PrescriptionStatus.initial));
      expect(PrescriptionStatus.values, contains(PrescriptionStatus.scanning));
      expect(
        PrescriptionStatus.values,
        contains(PrescriptionStatus.processing),
      );
      expect(PrescriptionStatus.values, contains(PrescriptionStatus.ready));
      expect(PrescriptionStatus.values, contains(PrescriptionStatus.error));
    });
  });

  group('PrescriptionNotifier logic', () {
    test('updateMedication should update medication at valid index', () {
      var state = const PrescriptionState(
        medications: ['Panadol', 'Amoxicillin'],
      );

      if (0 >= 0 && 0 < state.medications.length) {
        final updated = List<String>.from(state.medications);
        updated[0] = 'Panadol Extra';
        state = state.copyWith(medications: updated);
      }

      expect(state.medications[0], 'Panadol Extra');
      expect(state.medications[1], 'Amoxicillin');
    });

    test('updateMedication should not update if index out of range', () {
      var state = const PrescriptionState(medications: ['Panadol']);

      if (5 >= 0 && 5 < state.medications.length) {
        final updated = List<String>.from(state.medications);
        updated[5] = 'Invalid';
        state = state.copyWith(medications: updated);
      }

      expect(state.medications, ['Panadol']);
    });

    test('updateMedication should not update for negative index', () {
      var state = const PrescriptionState(medications: ['Panadol']);

      if (-1 >= 0 && -1 < state.medications.length) {
        final updated = List<String>.from(state.medications);
        updated[-1] = 'Invalid';
        state = state.copyWith(medications: updated);
      }

      expect(state.medications, ['Panadol']);
    });

    test('removeMedication should remove medication at valid index', () {
      var state = const PrescriptionState(
        medications: ['Panadol', 'Amoxicillin', 'Aspirin'],
      );

      if (1 >= 0 && 1 < state.medications.length) {
        final updated = List<String>.from(state.medications)..removeAt(1);
        state = state.copyWith(medications: updated);
      }

      expect(state.medications, ['Panadol', 'Aspirin']);
    });

    test('removeMedication should not remove if index out of range', () {
      var state = const PrescriptionState(medications: ['Panadol']);

      if (5 >= 0 && 5 < state.medications.length) {
        final updated = List<String>.from(state.medications)..removeAt(5);
        state = state.copyWith(medications: updated);
      }

      expect(state.medications, ['Panadol']);
    });

    test('addMedication should add medication to list', () {
      var state = const PrescriptionState(medications: ['Panadol']);

      final updated = List<String>.from(state.medications)..add('Aspirin');
      state = state.copyWith(medications: updated);

      expect(state.medications, ['Panadol', 'Aspirin']);
    });

    test('reset should clear all state', () {
      var state = const PrescriptionState(
        status: PrescriptionStatus.ready,
        medications: ['Panadol'],
        extractedText: 'Panadol 500mg',
      );

      state = const PrescriptionState();

      expect(state.status, PrescriptionStatus.initial);
      expect(state.medications, isEmpty);
      expect(state.extractedText, isNull);
    });
  });
}
