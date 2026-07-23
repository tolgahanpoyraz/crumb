class ApiConfig {
  // Defaults target the shared droplet. Override per-run without editing code:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5001/api \
  //               --dart-define=IMAGE_BASE_URL=https://my-bucket.s3.amazonaws.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5001/api',
  );

  static const String imageBaseUrl = String.fromEnvironment(
    'IMAGE_BASE_URL',
    defaultValue:
        'https://free-food-uploads-379604374199.s3.us-east-1.amazonaws.com',
  );
}
