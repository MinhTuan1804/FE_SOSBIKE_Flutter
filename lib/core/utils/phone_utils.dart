/// Chuẩn hóa SĐT Việt Nam cho Firebase (E.164) và API BE (0xxxxxxxxx).
abstract final class PhoneUtils {
  /// 0977999888 → +84977999888
  static String toE164(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('84')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '+84$digits';
  }

  /// Giữ format BE: 0977999888
  static String toLocal(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('84')) digits = digits.substring(2);
    if (!digits.startsWith('0')) digits = '0$digits';
    return digits;
  }
}
