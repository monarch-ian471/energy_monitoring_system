import 'package:energy_monitor_app/src/domain/entities/energy_data.dart';

abstract class EnergyRepository {
  Future<EnergyData> getCurrentEnergy({required int applianceId});
  Future<List<EnergyData>> getEnergyHistory({required int applianceId});
}
