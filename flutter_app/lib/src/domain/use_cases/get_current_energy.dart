import 'package:energy_monitor_app/src/domain/entities/energy_data.dart';
import 'package:energy_monitor_app/src/domain/repositories/energy_repository.dart';

class GetCurrentEnergy {
  final EnergyRepository repository;

  GetCurrentEnergy(this.repository);

  Future<EnergyData> call() async {
    return await repository.getCurrentEnergy();
  }
}
