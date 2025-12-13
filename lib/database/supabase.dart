import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_config.dart';

loadSupabase() async {
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: true,
      // PKCE flow enables proper deep link handling and auto-closes the auth webview
      // This is needed for linkIdentity (upgrading anonymous users)
      // Native OAuth (signInWithIdToken) is unaffected as it doesn't use URL callbacks
      authFlowType: AuthFlowType.pkce,
    ),
  );
}
