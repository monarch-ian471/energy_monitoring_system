import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../core/constants.dart';
import '../../../domain/entities/energy_data.dart';

class ApiDataSource {
  Future<EnergyData> getCurrentEnergy({int applianceId = 1}) async {
    debugPrint('ApiDataSource.getCurrentEnergy -> $apiBaseUrl/energy?appliance_id=$applianceId');
    final response = await http
        .get(Uri.parse('$apiBaseUrl/energy?appliance_id=$applianceId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return EnergyData.fromJson(data);
    } else {
      throw Exception('Failed to load current energy');
    }
  }

  Future<List<EnergyData>> getEnergyHistory({int applianceId = 1}) async {
    debugPrint('ApiDataSource.getEnergyHistory -> $apiBaseUrl/energy/history?appliance_id=$applianceId');
    final response = await http
        .get(Uri.parse('$apiBaseUrl/energy/history?appliance_id=$applianceId'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] as List;
      return data.map((item) => EnergyData.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load history');
    }
  }
}
