class Constants {
  // Supabase configuration via Cloudflare Worker
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://supabase-proxy.your-worker.workers.dev'
  );
  
  // Direct Supabase fallback if no Worker
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co'
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your_anon_key'
  );
  
  // API endpoints
  static const String designationsEndpoint = '/rest/v1/designations';
  static const String usersEndpoint = '/rest/v1/users';
  static const String quotesEndpoint = '/rest/v1/quotes';
  static const String createQuoteFunction = '/functions/v1/createQuote';
  
  // PDF configuration
  static const String appName = 'Tile Quote App';
  static const String appVersion = '1.0.0';
  
  // Cache configuration
  static const int cacheTimeoutSeconds = 60;
  
  // Rate limiting
  static const int maxRequestsPerMinute = 10;
}