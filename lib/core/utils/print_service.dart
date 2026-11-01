// Conditional import: web'de tarayıcı yazdırma penceresi, diğerlerinde no-op
import 'print_service_stub.dart'
    if (dart.library.js_interop) 'print_service_web.dart' as impl;

/// Sayfayı yazdırma (web: window.print()).
class PrintService {
  static void printPage() => impl.printPage();
}
