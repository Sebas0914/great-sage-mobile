abstract interface class OverlayService {
  Future<bool> isSupported();
  Future<bool> requestPermission();
  Future<void> showRaphael();
  Future<void> hideRaphael();
}
