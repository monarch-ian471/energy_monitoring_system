// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'energy_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnergyData _$EnergyDataFromJson(Map<String, dynamic> json) => EnergyData(
      timestamp: json['timestamp'] as String,
      watts: (json['watts'] as num).toDouble(),
    );

Map<String, dynamic> _$EnergyDataToJson(EnergyData instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'watts': instance.watts,
    };

_$EnergyDataImpl _$$EnergyDataImplFromJson(Map<String, dynamic> json) =>
    _$EnergyDataImpl(
      timestamp: json['timestamp'] as String,
      watts: (json['watts'] as num).toDouble(),
    );

Map<String, dynamic> _$$EnergyDataImplToJson(_$EnergyDataImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'watts': instance.watts,
    };
