abstract interface class AutomationProvider {
  Future<String> planAutomation(String command);
}
