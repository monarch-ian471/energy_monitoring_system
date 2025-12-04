import 'package:energy_monitor_app/src/data/datatsources/local/sqlite_datasource.dart';
import 'package:energy_monitor_app/src/data/datatsources/remote/api_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/energy_repository_impl.dart';
import '../../domain/use_cases/get_current_energy.dart';
import '../../domain/use_cases/get_energy_history.dart';
import '../../domain/entities/energy_data.dart';

final apiDataSourceProvider = Provider<ApiDataSource>((ref) => ApiDataSource());
final sqliteDataSourceProvider =
    Provider<SqliteDataSource>((ref) => SqliteDataSource());

final energyRepositoryProvider = Provider<EnergyRepositoryImpl>((ref) {
  return EnergyRepositoryImpl(
    ref.watch(apiDataSourceProvider),
    ref.watch(sqliteDataSourceProvider),
  );
});

final getCurrentEnergyProvider = Provider<GetCurrentEnergy>((ref) {
  return GetCurrentEnergy(ref.watch(energyRepositoryProvider));
});

final getEnergyHistoryProvider = Provider<GetEnergyHistory>((ref) {
  return GetEnergyHistory(ref.watch(energyRepositoryProvider));
});

final currentEnergyProvider = FutureProvider<EnergyData>((ref) async {
  return ref.watch(getCurrentEnergyProvider).call(applianceId: 1);
});

final energyHistoryProvider = FutureProvider<List<EnergyData>>((ref) async {
  return ref.watch(getEnergyHistoryProvider).call(applianceId: 1);
});

final selectedApplianceProvider = StateProvider<int>((ref) => 1);
