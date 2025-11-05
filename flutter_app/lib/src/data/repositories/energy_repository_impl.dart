import 'package:energy_monitor_app/src/data/datatsources/local/sqlite_datasource.dart';
import 'package:energy_monitor_app/src/data/datatsources/remote/api_datasource.dart';
import 'package:energy_monitor_app/src/domain/entities/energy_data.dart';
import 'package:energy_monitor_app/src/domain/repositories/energy_repository.dart';

class EnergyRepositoryImpl implements EnergyRepository {
  final ApiDataSource apiDataSource;
  final SqliteDataSource sqliteDataSource;

  EnergyRepositoryImpl(this.apiDataSource, this.sqliteDataSource);

  @override
  Future<EnergyData> getCurrentEnergy({required int applianceId}) async {
    try {
      return await apiDataSource.getCurrentEnergy(applianceId: applianceId);
    } catch (e) {
      return await sqliteDataSource.getCurrentEnergy(applianceId: applianceId);
    }
  }

  @override
  Future<List<EnergyData>> getEnergyHistory({required int applianceId}) async {
    try {
      return await apiDataSource.getEnergyHistory(applianceId: applianceId);
    } catch (e) {
      return await sqliteDataSource.getEnergyHistory(applianceId: applianceId);
    }
  }
}
