import 'package:cadife_smart_travel/design_system/theme/theme_provider.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_state.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_bloc_provider.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/profile_port.dart';
import 'package:cadife_smart_travel/features/client/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeProfilePort implements ProfilePort {
  final AuthUser? _user;
  _FakeProfilePort({AuthUser? user}) : _user = user;

  @override
  Future<AuthUser> getCurrentUser() async => _user!;

  @override
  Future<AuthUser> updateProfile({
    String? name,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  }) async {
    return _user!.copyWith(
      name: name,
      tipoViagem: tipoViagem,
      preferencias: preferencias,
      temPassaporte: temPassaporte,
    );
  }
}

class MockAuthBloc extends Mock implements AuthBloc {
  @override
  Future<void> close() async {}
}

Widget _buildTestableWidget({
  required ProfilePort profilePort,
  required MockAuthBloc authBloc,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final isDark = themeMode == ThemeMode.dark;
  return ProviderScope(
    overrides: [
      profilePortProvider.overrideWithValue(profilePort),
      authBlocProvider.overrideWithValue(authBloc),
      themeModeProvider.overrideWith((ref) => ThemeModeNotifier()..state = themeMode),
    ],
    child: BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp(
        theme: isDark ? ThemeData.dark() : ThemeData.light(),
        themeMode: themeMode,
        home: const ProfileScreen(),
      ),
    ),
  );
}

void main() {
  group('ProfileScreen', () {
    final mockUser = AuthUser(
      id: 'client-1',
      name: 'João Silva',
      email: 'joao@email.com',
      role: UserRole.cliente,
      phone: '+55 11 91234-5678',
      createdAt: DateTime(2024, 6, 15),
      tipoViagem: const ['turismo', 'lazer'],
      preferencias: const ['praia', 'calor'],
      temPassaporte: true,
    );

    late MockAuthBloc authBloc;

    setUp(() {
      authBloc = MockAuthBloc();
      when(() => authBloc.state).thenReturn(AuthAuthenticated(mockUser));
      when(() => authBloc.stream).thenAnswer((_) => Stream.value(AuthAuthenticated(mockUser)));
    });

    testWidgets('renderiza nome, email e telefone do usuário', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          profilePort: _FakeProfilePort(user: mockUser),
          authBloc: authBloc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('joao@email.com'), findsAtLeastNWidgets(1));
      expect(find.text('+55 11 91234-5678'), findsOneWidget);
    });

    testWidgets('renderiza botões de logout', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          profilePort: _FakeProfilePort(user: mockUser),
          authBloc: authBloc,
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(OutlinedButton, 'Sair da conta'),
        100,
      );

      expect(find.widgetWithText(OutlinedButton, 'Sair da conta'), findsOneWidget);
    });
  });
}
