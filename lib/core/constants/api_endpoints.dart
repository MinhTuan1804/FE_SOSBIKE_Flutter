class ApiEndpoints {
  // Thay thế bằng IP máy tính của bạn hoặc domain của BE C#
  // Đối với Android Emulator, 10.0.2.2 trỏ đến localhost của máy host
  static const String baseUrl = 'http://10.0.2.2:5000/api'; 
  
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String users = '/users';
}
