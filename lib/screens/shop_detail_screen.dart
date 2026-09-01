import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as picker;

import '../models/shop.dart';
import '../models/item.dart';
import '../providers/shop_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/nepali_date_utils.dart';
import '../services/pdf_service.dart';

class ShopDetailScreen extends StatefulWidget {
  final String shopId;

  const ShopDetailScreen({
    Key? key,
    required this.shopId,
  }) : super(key: key);

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  String _selectedSort = 'Newest first';
  final ImagePicker _imagePicker = ImagePicker();

  // ============================================================
  // SHOP PHOTO PICKER
  // ============================================================

  Future<void> _pickShopPhoto(
    BuildContext context,
    ShopProvider provider,
    Shop shop,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  'Update Shop Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _photoSourceButton(
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera',
                        onTap: () => Navigator.pop(ctx, ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _photoSourceButton(
                        icon: Icons.photo_library_rounded,
                        title: 'Gallery',
                        onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                if (shop.photoPath.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE11D48),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: Color(0xFFFECDD3)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text(
                        'Remove Photo',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await provider.removeShopPhoto(shop.id);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) return;
      await provider.updateShopPhoto(shop.id, image.path);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to select the shop photo.')),
      );
    }
  }

  Widget _photoSourceButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 26),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopPhoto(
    BuildContext context,
    ShopProvider provider,
    Shop shop,
  ) {
    final hasPhoto = shop.photoPath.isNotEmpty && File(shop.photoPath).existsSync();

    return GestureDetector(
      onTap: () => _pickShopPhoto(context, provider, shop),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: hasPhoto
              ? Image.file(
                  File(shop.photoPath),
                  fit: BoxFit.cover,
                )
              : const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 36,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, provider, _) {
        final shopList = provider.shops.where((s) => s.id == widget.shopId).toList();

        if (shopList.isEmpty) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: Text(
                "Shop not found",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        final shop = shopList.first;
        final items = provider.getItemsForShop(widget.shopId, sortBy: _selectedSort);
        final shopTotal = provider.getShopTotal(widget.shopId);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),

          // ========================================================
          // APP BAR
          // ========================================================
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFFF8FAFC),
            surfaceTintColor: Colors.transparent,
            title: Text(
              shop.name,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              _AppBarActionButton(
                icon: Icons.edit_outlined,
                tooltip: "Edit Shop",
                onTap: () => _showAddOrEditShopSheet(context, shop: shop),
              ),
              const SizedBox(width: 8),
              _AppBarActionButton(
                icon: Icons.delete_outline_rounded,
                tooltip: "Delete Shop",
                iconColor: const Color(0xFFE11D48),
                backgroundColor: const Color(0xFFFFF1F2),
                onTap: () => _confirmDeleteShop(context, provider, shop),
              ),
              const SizedBox(width: 16),
            ],
          ),

          body: Column(
            children: [
              // ======================================================
              // SHOP SUMMARY CARD
              // ======================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary,
                        AppTheme.primary.withBlue(160),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildShopPhoto(context, provider, shop),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (shop.address.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          color: Colors.white.withOpacity(0.8),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            shop.address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.85),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  Text(
                                    "TOTAL OUTSTANDING DUE",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      CurrencyFormatter.formatNPR(shopTotal),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ======================================================
              // SORT BAR
              // ======================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Purchases (${items.length})",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.02),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSort,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                          icon: const Icon(
                            Icons.sort_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Newest first', child: Text("Newest first")),
                            DropdownMenuItem(value: 'Oldest first', child: Text("Oldest first")),
                            DropdownMenuItem(value: 'Highest amount', child: Text("Highest amount")),
                            DropdownMenuItem(value: 'Lowest amount', child: Text("Lowest amount")),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedSort = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ======================================================
              // PURCHASE LIST
              // ======================================================
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 40,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No unpaid items",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Add a purchase item to start tracking.",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withOpacity(0.03),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: item.isPaid
                                          ? const Color(0xFFF0FDF4)
                                          : const Color(0xFFFFF1F2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      item.isPaid
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.pending_actions_rounded,
                                      color: item.isPaid
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFE11D48),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: const Color(0xFF0F172A),
                                            decoration: item.isPaid
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              NepaliDateHelper.formatBsDate(
                                                item.purchaseDate,
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item.note.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            item.note,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                        if (item.isPaid && item.paidDate != null) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            "✓ Paid on ${NepaliDateHelper.formatBsDate(item.paidDate!)}",
                                            style: const TextStyle(
                                              color: Color(0xFF16A34A),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        CurrencyFormatter.formatNPR(item.price),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: item.isPaid
                                              ? const Color(0xFF16A34A)
                                              : AppTheme.outstandingRed,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        icon: const Icon(
                                          Icons.more_vert_rounded,
                                          size: 20,
                                          color: Color(0xFF64748B),
                                        ),
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showAddOrEditItemSheet(context, item: item);
                                          } else if (value == 'toggle_paid') {
                                            provider.toggleItemPaidStatus(item.id);
                                          } else if (value == 'delete') {
                                            _confirmDeleteItem(context, provider, item);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'toggle_paid',
                                            child: Text(
                                              item.isPaid ? "Mark as Unpaid" : "Mark as Paid",
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text("Edit"),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text("Delete"),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // ======================================================
              // BOTTOM ACTION BAR
              // ======================================================
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(
                            Icons.picture_as_pdf_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            "Generate Bill PDF",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: () async {
                            final pdfFile = await PdfService.generateShopPdf(
                              shop,
                              provider.getItemsForShop(widget.shopId),
                            );

                            if (context.mounted) {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(28),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF0FDF4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Color(0xFF16A34A),
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        "PDF Generated Successfully",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primary,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.share_outlined,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            "Share Bill PDF",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            PdfService.shareFile(pdfFile);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FloatingActionButton(
                          heroTag: 'addItemFab',
                          backgroundColor: AppTheme.primary,
                          elevation: 0,
                          highlightElevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onPressed: () => _showAddOrEditItemSheet(context),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // DELETE SHOP
  // ============================================================

  void _confirmDeleteShop(
    BuildContext context,
    ShopProvider provider,
    Shop shop,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Delete Shop?",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          "This action will remove \"${shop.name}\" and all attached records permanently.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              provider.deleteShop(shop.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE ITEM
  // ============================================================

  void _confirmDeleteItem(
    BuildContext context,
    ShopProvider provider,
    Item item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Delete Item?",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          "Are you sure you want to delete \"${item.name}\" worth ${CurrencyFormatter.formatNPR(item.price)}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              provider.deleteItem(item.id);
              Navigator.pop(ctx);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDIT SHOP SHEET
  // ============================================================

  void _showAddOrEditShopSheet(
    BuildContext context, {
    Shop? shop,
  }) {
    final nameCtrl = TextEditingController(text: shop?.name ?? '');
    final ownerCtrl = TextEditingController(text: shop?.ownerName ?? '');
    final phoneCtrl = TextEditingController(text: shop?.phone ?? '');
    final addressCtrl = TextEditingController(text: shop?.address ?? '');
    final notesCtrl = TextEditingController(text: shop?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 14,
          left: 24,
          right: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                shop == null ? "Add Shop" : "Edit Shop Details",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              if (shop != null) ...[
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      final provider = Provider.of<ShopProvider>(
                        context,
                        listen: false,
                      );
                      _pickShopPhoto(context, provider, shop);
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: shop.photoPath.isNotEmpty && File(shop.photoPath).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.file(
                                File(shop.photoPath),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.storefront_rounded,
                              size: 42,
                              color: Color(0xFF94A3B8),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    "Tap to change shop photo",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _buildModernTextField(
                controller: nameCtrl,
                label: "Shop Name *",
                icon: Icons.storefront_rounded,
              ),
              const SizedBox(height: 14),
              _buildModernTextField(
                controller: ownerCtrl,
                label: "Owner Name",
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              _buildModernTextField(
                controller: phoneCtrl,
                label: "Phone Number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildModernTextField(
                controller: addressCtrl,
                label: "Address",
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 14),
              _buildModernTextField(
                controller: notesCtrl,
                label: "Notes",
                icon: Icons.note_alt_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;

                        final provider = Provider.of<ShopProvider>(
                          context,
                          listen: false,
                        );

                        if (shop == null) {
                          provider.addShop(
                            nameCtrl.text.trim(),
                            ownerCtrl.text.trim(),
                            phoneCtrl.text.trim(),
                            addressCtrl.text.trim(),
                            notesCtrl.text.trim(),
                          );
                        } else {
                          provider.editShop(
                            shop.id,
                            nameCtrl.text.trim(),
                            ownerCtrl.text.trim(),
                            phoneCtrl.text.trim(),
                            addressCtrl.text.trim(),
                            notesCtrl.text.trim(),
                          );
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        "Save Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD / EDIT ITEM
  // ============================================================

  void _showAddOrEditItemSheet(
    BuildContext context, {
    Item? item,
  }) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(0) : '',
    );
    final noteCtrl = TextEditingController(text: item?.note ?? '');
    DateTime selectedDate = item?.purchaseDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 14,
              left: 24,
              right: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    item == null ? "Add Purchase Item" : "Edit Purchase Item",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildModernTextField(
                    controller: nameCtrl,
                    label: "Item Name *",
                    icon: Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildModernTextField(
                    controller: priceCtrl,
                    label: "Price (NPR) *",
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: const Icon(
                        Icons.calendar_today_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      title: const Text(
                        "Purchased Date (B.S.)",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        NepaliDateHelper.formatBsDate(selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Color(0xFF64748B),
                      ),
                      onTap: () async {
                        final NepaliDateTime? picked = await picker.showNepaliDatePicker(
                          context: context,
                          initialDate: NepaliDateHelper.toBs(selectedDate),
                          firstDate: NepaliDateTime(2070),
                          lastDate: NepaliDateTime(2090),
                          initialDatePickerMode: DatePickerMode.day,
                        );

                        if (picked != null) {
                          setSheetState(() => selectedDate = picked.toDateTime());
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildModernTextField(
                    controller: noteCtrl,
                    label: "Note (e.g., 25 kg, 2 packets)",
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            final price = double.tryParse(priceCtrl.text.trim());
                            if (nameCtrl.text.trim().isEmpty || price == null) return;

                            final provider = Provider.of<ShopProvider>(
                              context,
                              listen: false,
                            );

                            if (item == null) {
                              provider.addItem(
                                widget.shopId,
                                nameCtrl.text.trim(),
                                price,
                                selectedDate,
                                noteCtrl.text.trim(),
                              );
                            } else {
                              provider.editItem(
                                item.id,
                                nameCtrl.text.trim(),
                                price,
                                selectedDate,
                                noteCtrl.text.trim(),
                              );
                            }

                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            "Save Item",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }
}

class _AppBarActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const _AppBarActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          border: backgroundColor == null ? Border.all(color: const Color(0xFFE2E8F0)) : null,
          boxShadow: backgroundColor == null
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor ?? const Color(0xFF475569),
        ),
      ),
    );
  }
}