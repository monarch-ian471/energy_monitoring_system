import 'package:freezed_annotation/freezed_annotation.dart';
// import 'package:json_annotation/json_annotation.dart'; // Added: For JSON

part 'energy_data.freezed.dart';
part 'energy_data.g.dart';

@freezed
@JsonSerializable() // Added: Enables JSON methods
class EnergyData with _$EnergyData {
  const factory EnergyData({
    required String timestamp,
    required double watts,
  }) = _EnergyData;

  factory EnergyData.fromJson(Map<String, dynamic> json) =>
      _$EnergyDataFromJson(json);
}
