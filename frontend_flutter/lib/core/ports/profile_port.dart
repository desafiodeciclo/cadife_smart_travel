import 'package:cadife_smart_travel/shared/models/user_model.dart';

/// Port para operações de perfil do usuário cliente.
///
/// Abstrai chamadas HTTP relacionadas ao perfil e preferências de viagem.
abstract class ProfilePort {
  Future<UserModel> getCurrentUser();
  Future<UserModel> updateProfile({
    String? name,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  });
}
