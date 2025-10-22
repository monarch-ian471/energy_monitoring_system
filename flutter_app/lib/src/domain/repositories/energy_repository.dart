import 'package:energy_monitor_app/src/domain/entities/energy_data.dart';

abstract class EnergyRepository {
  Future<EnergyData> getCurrentEnergy();
  Future<List<EnergyData>> getEnergyHistory();
}
