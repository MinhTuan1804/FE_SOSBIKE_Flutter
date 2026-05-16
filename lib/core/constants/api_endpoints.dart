class ApiEndpoints {
  /// BE deploy (nginx) — HTTP. Emulator local: `http://10.0.2.2:<port>/api`; máy thật: IP LAN hoặc URL này.
  static const String baseUrl = 'http://168.144.38.133:8090/api';

  static const String login = '/Auth/login';
  static const String register = '/Auth/register';
  static const String users = '/users';
}
