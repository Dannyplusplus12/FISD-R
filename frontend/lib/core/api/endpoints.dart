// ── API Endpoint Paths ────────────────────────────────────────────────────────
//
// All URL paths live here.  When the backend renames an endpoint,
// update only this file — every repository picks up the change automatically.
//
// Usage:
//   dio.get(ApiEndpoints.products)
//   dio.get(ApiEndpoints.product(42))
//   dio.put(ApiEndpoints.approveOrder(7))

class ApiEndpoints {
  ApiEndpoints._(); // not instantiable

  // Products
  static const String products = '/products';
  static String product(int id) => '/products/$id';
  static const String productImageUpload = '/product-images/upload';
  static String productImage(String filename) => '/product-images/$filename';

  // Areas
  static const String areas = '/areas';
  static String area(int id) => '/areas/$id';

  // Customers
  static const String customers = '/customers';
  static String customer(int id) => '/customers/$id';
  static String customerHistory(int id) => '/customers/$id/history';
  static String customerHistoryItem(int cid, int logId) => '/customers/$cid/history/$logId';

  // Orders
  static const String orders = '/orders';
  static String order(int id) => '/orders/$id';
  static String orderDate(int id) => '/orders/$id/date';
  static String orderStatus(int id) => '/orders/$id/status';

  static const String checkout = '/checkout';
  static const String checkoutDraft = '/checkout/draft';
  static const String checkoutDesktopDispatch = '/checkout/desktop-dispatch';

  static const String pendingOrders = '/orders/pending';
  static const String approvedOrders = '/orders/approved';
  static const String managementOrders = '/orders/management';

  static String approveOrder(int id) => '/orders/$id/approve';
  static String rejectOrder(int id) => '/orders/$id/reject';
  static String cancelOrder(int id) => '/orders/$id/cancel';
  static String receiveOrder(int id) => '/orders/$id/receive';
  static String deliverOrder(int id) => '/orders/$id/deliver-with-photo';
  static String confirmOrder(int id) => '/orders/$id/confirm';
  static String assignedOrders(int pickerId) => '/orders/assigned?picker_id=$pickerId';

  // Employees
  static const String employees = '/employees';
  static String employee(int id) => '/employees/$id';
  static String employeeDeliveries(int id) => '/employees/$id/deliveries';
  static String employeeActivities(int id) => '/employees/$id/activities';

  // Auth
  static const String pinLogin = '/auth/pin-login';
}
