enum UserRole {
  customer('CUSTOMER', 'Người đi xe'),
  mechanic('MECHANIC', 'Thợ sửa xe');

  const UserRole(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
