// lib/providers/shop_provider.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/shop.dart';
import '../models/item.dart';
import '../models/app_settings.dart';
import '../services/notification_service.dart';

class ShopProvider extends ChangeNotifier {
  late Box<Shop> _shopBox;
  late Box<Item> _itemBox;
  late Box<AppSettings> _settingsBox;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  ShopProvider() {
    _shopBox = Hive.box<Shop>('shops');
    _itemBox = Hive.box<Item>('items');
    _settingsBox = Hive.box<AppSettings>('settings');
  }

  // ============================================================
  // SHOPS
  // ============================================================

  List<Shop> get shops {
    final list = _shopBox.values.toList();

    if (_searchQuery.isEmpty) {
      return list;
    }

    return list.where((s) {
      final q = _searchQuery.toLowerCase();

      return s.name.toLowerCase().contains(q) ||
          s.ownerName.toLowerCase().contains(q) ||
          s.address.toLowerCase().contains(q);
    }).toList();
  }

  List<Item> get allItems => _itemBox.values.toList();

  AppSettings get settings =>
      _settingsBox.get('app_settings') ?? AppSettings();

  double get grandTotalOutstanding {
    return _itemBox.values
        .where((item) => !item.isPaid)
        .fold(0.0, (sum, item) => sum + item.price);
  }

  int get totalUnpaidItemsCount {
    return _itemBox.values.where((item) => !item.isPaid).length;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ============================================================
  // ADD SHOP
  // ============================================================

  Future<void> addShop(
    String name,
    String owner,
    String phone,
    String address,
    String notes, {
    String photoPath = '',
  }) async {
    final newShop = Shop(
      id: const Uuid().v4(),
      name: name,
      ownerName: owner,
      phone: phone,
      address: address,
      notes: notes,
      createdAt: DateTime.now(),
      photoPath: photoPath,
    );

    await _shopBox.put(newShop.id, newShop);

    notifyListeners();
  }

  // ============================================================
  // EDIT SHOP
  // ============================================================

  Future<void> editShop(
    String id,
    String name,
    String owner,
    String phone,
    String address,
    String notes, {
    String? photoPath,
  }) async {
    final shop = _shopBox.get(id);

    if (shop != null) {
      shop.name = name;
      shop.ownerName = owner;
      shop.phone = phone;
      shop.address = address;
      shop.notes = notes;

      // Only change photo if a new value was supplied.
      if (photoPath != null) {
        shop.photoPath = photoPath;
      }

      await shop.save();

      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE SHOP PHOTO ONLY
  // ============================================================

  Future<void> updateShopPhoto(
    String shopId,
    String photoPath,
  ) async {
    final shop = _shopBox.get(shopId);

    if (shop != null) {
      shop.photoPath = photoPath;

      await shop.save();

      notifyListeners();
    }
  }

  // ============================================================
  // REMOVE SHOP PHOTO
  // ============================================================

  Future<void> removeShopPhoto(String shopId) async {
    final shop = _shopBox.get(shopId);

    if (shop != null) {
      shop.photoPath = '';

      await shop.save();

      notifyListeners();
    }
  }

  // ============================================================
  // DELETE SHOP
  // ============================================================

  Future<void> deleteShop(String shopId) async {
    await _shopBox.delete(shopId);

    final itemsToDelete = _itemBox.values
        .where((item) => item.shopId == shopId)
        .map((e) => e.id)
        .toList();

    for (var id in itemsToDelete) {
      await _itemBox.delete(id);
    }

    _checkThresholdAndNotify();

    notifyListeners();
  }

  // ============================================================
  // ITEM OPERATIONS
  // ============================================================

  List<Item> getItemsForShop(
    String shopId, {
    String sortBy = 'Newest first',
  }) {
    final list =
        _itemBox.values.where((i) => i.shopId == shopId).toList();

    if (sortBy == 'Newest first') {
      list.sort(
        (a, b) => b.purchaseDate.compareTo(a.purchaseDate),
      );
    } else if (sortBy == 'Oldest first') {
      list.sort(
        (a, b) => a.purchaseDate.compareTo(b.purchaseDate),
      );
    } else if (sortBy == 'Highest amount') {
      list.sort(
        (a, b) => b.price.compareTo(a.price),
      );
    } else if (sortBy == 'Lowest amount') {
      list.sort(
        (a, b) => a.price.compareTo(b.price),
      );
    }

    return list;
  }

  double getShopTotal(String shopId) {
    return _itemBox.values
        .where(
          (i) => i.shopId == shopId && !i.isPaid,
        )
        .fold(
          0.0,
          (sum, i) => sum + i.price,
        );
  }

  int getShopUnpaidCount(String shopId) {
    return _itemBox.values
        .where(
          (i) => i.shopId == shopId && !i.isPaid,
        )
        .length;
  }

  DateTime? getShopLastPurchaseDate(String shopId) {
    final items = _itemBox.values
        .where((i) => i.shopId == shopId)
        .toList();

    if (items.isEmpty) {
      return null;
    }

    items.sort(
      (a, b) => b.purchaseDate.compareTo(a.purchaseDate),
    );

    return items.first.purchaseDate;
  }

  // ============================================================
  // ADD ITEM
  // ============================================================

  Future<void> addItem(
    String shopId,
    String name,
    double price,
    DateTime date,
    String note,
  ) async {
    final newItem = Item(
      id: const Uuid().v4(),
      shopId: shopId,
      name: name,
      price: price,
      purchaseDate: date,
      note: note,
    );

    await _itemBox.put(newItem.id, newItem);

    _checkThresholdAndNotify();

    notifyListeners();
  }

  // ============================================================
  // EDIT ITEM
  // ============================================================

  Future<void> editItem(
    String itemId,
    String name,
    double price,
    DateTime date,
    String note,
  ) async {
    final item = _itemBox.get(itemId);

    if (item != null) {
      item.name = name;
      item.price = price;
      item.purchaseDate = date;
      item.note = note;

      await item.save();

      _checkThresholdAndNotify();

      notifyListeners();
    }
  }

  // ============================================================
  // TOGGLE PAID STATUS
  // ============================================================

  Future<void> toggleItemPaidStatus(String itemId) async {
    final item = _itemBox.get(itemId);

    if (item != null) {
      item.isPaid = !item.isPaid;

      item.paidDate = item.isPaid
          ? DateTime.now()
          : null;

      await item.save();

      _checkThresholdAndNotify();

      notifyListeners();
    }
  }

  // ============================================================
  // DELETE ITEM
  // ============================================================

  Future<void> deleteItem(String itemId) async {
    await _itemBox.delete(itemId);

    _checkThresholdAndNotify();

    notifyListeners();
  }

  // ============================================================
  // SETTINGS & NOTIFICATIONS
  // ============================================================

  Future<void> updateSettings(
    AppSettings newSettings,
  ) async {
    await _settingsBox.put(
      'app_settings',
      newSettings,
    );

    if (newSettings.unpaidReminderEnabled) {
      NotificationService.instance.schedulePeriodicReminder(
        newSettings.reminderFrequencyDays,
        newSettings.reminderHour,
        newSettings.reminderMinute,
        totalUnpaidItemsCount,
        grandTotalOutstanding,
      );
    } else {
      NotificationService.instance.cancelReminder();
    }

    notifyListeners();
  }

  // ============================================================
  // THRESHOLD NOTIFICATION
  // ============================================================

  void _checkThresholdAndNotify() async {
    final st = settings;

    if (!st.outstandingAlertEnabled) {
      return;
    }

    final currentTotal = grandTotalOutstanding;

    if (currentTotal >= st.thresholdAmount &&
        !st.thresholdNotified) {
      await NotificationService.instance.showThresholdNotification(
        currentTotal,
        totalUnpaidItemsCount,
      );

      st.thresholdNotified = true;

      await st.save();
    } else if (currentTotal < st.thresholdAmount &&
        st.thresholdNotified) {
      st.thresholdNotified = false;

      await st.save();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  void refreshFromStorage() {
    notifyListeners();
  }
}