class AppConfig {
  // LOCAL DEVELOPMENT — change back to Azure URL for production builds
  static const bool _isLocal = false;

  // Android Emulator: 10.0.2.2 maps to host's localhost
  // Physical device: use your PC's local IP (e.g. 192.168.x.x)
  static const String _localUrl = 'http://10.131.111.146:8000/api';
  static const String _azureUrl =
      'https://nutrientplus-backend.kindplant-de7a2df8.germanywestcentral.azurecontainerapps.io/api';

  static const String baseUrl = _isLocal ? _localUrl : _azureUrl;
}
