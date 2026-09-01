// lib/core/utils/nepali_date_utils.dart
import 'package:nepali_utils/nepali_utils.dart';

class NepaliDateHelper {
  static String formatBsDate(DateTime dateTime) {
    NepaliDateTime bsDate = dateTime.toNepaliDateTime();
    return NepaliDateFormat('dd MMMM yyyy', Language.nepali).format(bsDate);
  }

  static String formatBsDateEnglish(DateTime dateTime) {
    NepaliDateTime bsDate = dateTime.toNepaliDateTime();
    return NepaliDateFormat('dd MMMM yyyy', Language.english).format(bsDate);
  }

  static NepaliDateTime toBs(DateTime dateTime) {
    return dateTime.toNepaliDateTime();
  }
}