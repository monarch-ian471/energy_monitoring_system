import 'package:freezed_annotation/freezed_annotation.dart';

part 'energy_data.freezed.dart';
part 'energy_data.g.dart';

@freezed
class EnergyData with _$EnergyData {
  const factory EnergyData({
    required String timestamp,
    required double watts,
    @Default(1) int applianceId,
  }) = _EnergyData;

  factory EnergyData.fromJson(Map<String, dynamic> json) =>
      _$EnergyDataFromJson(json);
}
