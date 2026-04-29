import 'package:cadife_smart_travel/core/ports/auth_port.dart';
import 'package:cadife_smart_travel/core/ports/profile_port.dart';
import 'package:cadife_smart_travel/core/theme/theme_mode_provider.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:cadife_smart_travel/features/client/profile/profile.dart';
import 'package:cadife_smart_travel/shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfilePort implements ProfilePort {
  final UserModel? _user;

  _FakeProfilePort({UserModel? user}) : _user = user;

  @override
  Future<UserModel> getCurrentUser() async => _user!;

  @override
  Future<UserModel> updateProfile({
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

class _FakeAuthPort implements AuthPort {
  final UserModel? _user;

  _FakeAuthPort({UserModel? user}) : _user = user;

  @override
  Future<UserModel> login(String email, String password) async => _user!;

  @override
  Future<UserModel> register(String name, String email, String password) async => _user!;

  @override
  Future<void> logout() async {}

  @override
  Future<TokenModel> refreshToken(String refreshToken) async =>
      const TokenModel(accessToken: 'a', refreshToken: 'r', expiresIn: 3600);

  @override
  Future<UserModel?> getCurrentUser() async => _user;

  @override
  Future<bool> isLoggedIn() async => _user != null;

  @override
  Future<void> saveFcmToken(String token) async {}
}

Widget _buildTestableWidget({
  required ProfilePort profilePort,
  required AuthPort authPort,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final isDark = themeMode == ThemeMode.dark;
  return ProviderScope(
    overrides: [
      profilePortProvider.overrideWithValue(profilePort),
      authPortProvider.overrideWithValue(authPort),
      themeModeProvider.overrideWith((ref) => ThemeModeNotifier()..state = themeMode),
    ],
    child: MaterialApp(
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      darkTheme: isDark ? ThemeData.dark() : ThemeData.dark(),
      themeMode: themeMode,
      home: const ProfileScreen(),
    ),
  );
}

void main() {
  group('ProfileScreen', () {
    final mockUser = UserModel(
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

    testWidgets('renderiza nome, email e telefone do usuário', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          profilePort: _FakeProfilePort(user: mockUser),
          authPort: _FakeAuthPort(user: mockUser),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('joao@email.com'), findsAtLeastNWidgets(1));
      expect(find.text('+55 11 91234-5678'), findsOneWidget);
      expect(find.text('15/06/2024'), findsOneWidget);
    });

    testWidgets('renderiza chips de preferências de viagem', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          profilePort: _FakeProfilePort(user: mockUser),
          authPort: _FakeAuthPort(user: mockUser),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Turismo'), findsOneWidget);
      expect(find.text('Lazer'), findsOneWidget);
      expect(find.text('Praia'), findsOneWidget);
      expect(find.text('Calor'), findsOneWidget);
    });

    testWidgets('renderiza toggle de passaporte válido', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          profilePort: _FakeProfilePort(user: mockUser),
          authPort: _FakeAuthPort(user: mockUser),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Passaporte válido'), findsOneWidget);
      expect(find.text('Sim, possui passaporte válido'), findsOneWidget);
    });

    testWidgets('renderiza botão de logout', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          profilePort: _FakeProfilePort(user: mockUser),
          authPort: _FakeAuthPort(user: mockUser),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(OutlinedButton, 'Sair da conta'),
        100,
      );

      expect(find.widgetWithText(OutlinedButton, 'Sair da conta'), findsOneWidget);
    });

    testWidgets('renderiza opções de tema', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          profilePort: _FakeProfilePort(user: mockUser),
          authPort: _FakeAuthPort(user: mockUser),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Padrão do sistema'),
        100,
      );

      expect(find.text('Padrão do sistema'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
    });

    testWidgets('mostra loading quando dados ainda não carregaram', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          profilePort: _FakeProfilePort(user: mockUser),
          authPort: _FakeAuthPort(user: mockUser),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carregando perfil...'), findsOneWidget);
    });

    testWidgets('exibe mensagem quando telefone não está informado', (tester) async {
      const userSemTelefone = UserModel(
        id: 'client-2',
        name: 'Maria Souza',
        email: 'maria@email.com',
        role: UserRole.cliente,
      );

      await tester.pumpWidget(
        _buildTestableWidget(
          profilePort: _FakeProfilePort(user: userSemTelefone),
          authPort: _FakeAuthPort(user: userSemTelefone),
        ),
      );
      await tester.pumpAndSettle();

      // Telefone e passaporte podem mostrar "Não informado"
      expect(find.text('Não informado'), findsAtLeastNWidgets(1));
    });

    testWidgets('adapta cores para tema escuro', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          profilePort: _FakeProfilePort(user: mockUser),
          authPort: _FakeAuthPort(user: mockUser),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF1C1917));
    });

    testWidgets('entra em modo de edição ao tocar no ícone de editar', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          profilePort: _FakeProfilePort(user: mockUser),
          authPort: _FakeAuthPort(user: mockUser),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Após tocar em editar, o TextField de nome deve aparecer
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
