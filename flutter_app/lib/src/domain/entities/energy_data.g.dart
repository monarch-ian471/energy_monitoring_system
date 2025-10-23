// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'energy_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$EnergyDataToJson(EnergyData instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'watts': instance.watts,
    };

_$EnergyDataImpl _$$EnergyDataImplFromJson(Map<String, dynamic> json) =>
    _$EnergyDataImpl(
      timestamp: json['timestamp'] as String,
      watts: (json['watts'] as num).toDouble(),
      applianceId: json['applianceId'] as int,
    );

Map<String, dynamic> _$$EnergyDataImplToJson(_$EnergyDataImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'watts': instance.watts,
    };
