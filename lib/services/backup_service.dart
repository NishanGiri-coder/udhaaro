// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/shop.dart';
import '../models/item.dart';
import '../models/app_settings.dart';

class BackupService {
  static Future<void> exportBackup() async {
    final shopBox = Hive.box<Shop>('shops');
    final itemBox = Hive.box<Item>('items');
    final settingsBox = Hive.box<AppSettings>('settings');

    final backupMap = {
      'version': 1,
      'exportDate': DateTime.now().toIso8601String(),
      'shops': shopBox.values.map((s) => s.toJson()).toList(),
      'items': itemBox.values.map((i) => i.toJson()).toList(),
      'settings': settingsBox.get('app_settings')?.toJson(),
    };

    final jsonString = jsonEncode(backupMap);
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/udhaaro_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(filePath)], text: 'Udhaaro Local JSON Backup File');
  }

  static Future<bool> importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupMap = jsonDecode(jsonString);

      final shopBox = Hive.box<Shop>('shops');
      final itemBox = Hive.box<Item>('items');
      final settingsBox = Hive.box<AppSettings>('settings');

      await shopBox.clear();
      await itemBox.clear();

      if (backupMap['shops'] != null) {
        for (var sJson in backupMap['shops']) {
          final shop = Shop.fromJson(Map<String, dynamic>.from(sJson));
          await shopBox.put(shop.id, shop);
        }
      }

      if (backupMap['items'] != null) {
        for (var iJson in backupMap['items']) {
          final item = Item.fromJson(Map<String, dynamic>.from(iJson));
          await itemBox.put(item.id, item);
        }
      }

      if (backupMap['settings'] != null) {
        final settings = AppSettings.fromJson(Map<String, dynamic>.from(backupMap['settings']));
        await settingsBox.put('app_settings', settings);
      }

      return true;
    }
    return false;
  }
}