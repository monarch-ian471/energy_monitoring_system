import 'package:energy_monitor_app/src/domain/entities/energy_data.dart';
import 'package:energy_monitor_app/src/domain/repositories/energy_repository.dart';

class GetEnergyHistory {
  final EnergyRepository repository;

  GetEnergyHistory(this.repository);

  Future<List<EnergyData>> call({required int applianceId}) async {
    return await repository.getEnergyHistory(applianceId: applianceId);
  }
}
