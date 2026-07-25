import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
	Env._();

	static String get supabaseUrl {
		final value = dotenv.env['SUPABASE_URL'];
		if (value == null || value.isEmpty) {
			throw StateError('SUPABASE_URL is not set in .env');
		}
		return value;
	}

	static String get baseUrl {
		final value = dotenv.env['BASE_URL'];
		if (value == null || value.isEmpty) {
			throw StateError('BASE_URL is not set in .env');
		}
		return value;
	}

  static String get supabasePublishableKey {
    final value = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];
    if (value == null || value.isEmpty) {
      throw StateError('SUPABASE_ANONKEY is not set in .env');
    }
    return value;
	}
}