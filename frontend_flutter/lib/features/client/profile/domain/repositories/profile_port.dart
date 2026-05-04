import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';

/// Port para operaÃ§Ãµes de perfil do usuÃ¡rio cliente.
///
/// Abstrai chamadas HTTP relacionadas ao perfil e preferÃªncias de viagem.
abstract class ProfilePort {
  Future<AuthUser> getCurrentUser();
  Future<AuthUser> updateProfile({
    String? name,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  });
}



