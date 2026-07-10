import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kalorat/services/auth_service.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  test('account deletion is a no-op for guests', () async {
    final client = _MockSupabaseClient();
    final auth = _MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(null);

    await AuthService(client: client).deleteAccount();

    verifyNever(() => client.rpc(any()));
    verifyNever(() => auth.signOut());
  });
}
