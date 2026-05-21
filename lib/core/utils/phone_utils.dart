/// Chuẩn hóa số VN cho API BE (0xxxxxxxxx).
String toLocalVietnamPhone(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('84')) digits = digits.substring(2);
  if (digits.startsWith('0')) return digits;
  return '0$digits';
}

/// Khớp BE: `PhoneHelper` — 10 số, bắt đầu 0, chữ số thứ 2 là 3–9 (03x, 05x, 07x, 08x, 09x…).
bool isValidVietnamPhone(String input) {
  final local = toLocalVietnamPhone(input);
  return RegExp(r'^0[3-9]\d{8}$').hasMatch(local);
}
