/// Centralized configuration for Vayu API keys and environment variables.
class VayuConfig {
  /// The WAQI (World Air Quality Index) token.
  /// Get yours at: https://aqicn.org/data-platform/token/
  static const String waqiToken = 'e1c7e623977a46c20fd28c6a482d55c02d2e140f';

  /// The OpenRouteService API key (for Open Source Routing).
  /// Get yours at: https://openrouteservice.org/dev/#/signup
  static const String orsKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImE5ODM4MTYxYzZmMzQ5MWI4MzgxZTU3NDllNDVjNWQ2IiwiaCI6Im11cm11cjY0In0=';

  /// Mode switcher: Toggle between real networking and simulations.
  static const bool useMockData = false;

  /// Auth switcher: Enable mock login for local testing.
  static const bool useMockAuth = true;
}
