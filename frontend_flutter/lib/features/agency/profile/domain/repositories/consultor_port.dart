import 'package:cadife_smart_travel/features/agency/profile/consultor_profile_models.dart';

abstract class ConsultorPort {
  Future<ConsultorProfile> getProfile();
  Future<ConsultorProfile> updateBio(String bio);
  Future<List<SaleGoal>> getGoals();
}
