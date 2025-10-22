import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../domain/entities/energy_data.dart';

class ApiDataSource {
  Future<EnergyData> getCurrentEnergy() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/energy'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return EnergyData.fromJson(data);
    } else {
      throw Exception('Failed to load current energy');
    }
  }

  Future<List<EnergyData>> getEnergyHistory() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/energy/history'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] as List;
      return data.map((item) => EnergyData.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load history');
    }
  }
}
