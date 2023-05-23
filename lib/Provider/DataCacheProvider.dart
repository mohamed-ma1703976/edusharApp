import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class DataCacheProvider with ChangeNotifier {
  Map<String, dynamic> _cacheData = {};

  Map<String, dynamic> get cacheData => _cacheData;

  void updateCacheData(String key, dynamic value) {
    _cacheData[key] = value;
    notifyListeners();
  }

  Future<void> loadDataFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('cacheData');
    if (jsonString != null) {
      Map<String, dynamic> jsonData = jsonDecode(jsonString);
      _cacheData = jsonData;
    }
  }

  Future<void> saveDataToCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(_cacheData);
    await prefs.setString('cacheData', jsonString);
  }
}
