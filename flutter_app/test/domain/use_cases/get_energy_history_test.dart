import 'package:energy_monitor_app/src/domain/entities/energy_data.dart';
import 'package:energy_monitor_app/src/domain/repositories/energy_repository.dart';
import 'package:energy_monitor_app/src/domain/use_cases/get_energy_history.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockEnergyRepository extends Mock implements EnergyRepository {}

void main() {
  test('GetEnergyHistory calls repository', () async {
    final mockRepo = MockEnergyRepository();
    final useCase = GetEnergyHistory(mockRepo);
    final mockData = [
      EnergyData(timestamp: '2025-10-22 12:00:00', watts: 50.0)
    ];

    when(mockRepo.getEnergyHistory()).thenAnswer((_) async => mockData);

    final result = await useCase.call();

    expect(result, mockData);
    verify(mockRepo.getEnergyHistory()).called(1);
  });
}
