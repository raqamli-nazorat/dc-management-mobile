class ApiEndpoints {
  ApiEndpoints._();

  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  static const String workers = '/workers';
  static String workerById(String id) => '/workers/$id';

  static const String departments = '/departments';
  static String departmentById(String id) => '/departments/$id';

  static const String expenseRequests = '/expense-requests';
  static String expenseRequestById(String id) => '/expense-requests/$id';
}
