import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_state.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_bloc_provider.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/i_profile_repository.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/pages/profile_page.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/providers/profile_provider.dart';
import 'package:cadife_smart_travel/features/settings/application/theme_notifier.dart';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _FakeProfileRepository implements IProfileRepository {
  final AuthUser? _user;
  _FakeProfileRepository({AuthUser? user}) : _user = user;

  @override
  Future<Either<Failure, AuthUser>> getCurrentUser() async => Right(_user!);

  @override
  Future<Either<Failure, AuthUser>> updateProfile({
    String? name,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  }) async {
    return Right(_user!.copyWith(
      name: name,
      tipoViagem: tipoViagem,
      preferencias: preferencias,
      temPassaporte: temPassaporte,
    ));
  }
}

class MockAuthBloc extends Mock implements AuthBloc {
  @override
  Future<void> close() async {}
}

Widget _buildTestableWidget({
  required IProfileRepository profileRepository,
  required MockAuthBloc authBloc,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final isDark = themeMode == ThemeMode.dark;
  return ProviderScope(
    overrides: [
      iProfileRepositoryProvider.overrideWithValue(profileRepository),
      authBlocProvider.overrideWithValue(authBloc),
      themeNotifierProvider.overrideWith(() => _MockThemeNotifier(themePreference: ThemePreference.values.byName(themeMode.name))),
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
          profileRepository: _FakeProfileRepository(user: mockUser),
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
          profileRepository: _FakeProfileRepository(user: mockUser),
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
class _MockThemeNotifier extends ThemeNotifier {
  final ThemePreference themePreference;
  _MockThemeNotifier({required this.themePreference});

  @override
  Stream<ThemePreference> build() => Stream.value(themePreference);

  @override
  Future<void> setTheme(ThemePreference preference) async {}
}
