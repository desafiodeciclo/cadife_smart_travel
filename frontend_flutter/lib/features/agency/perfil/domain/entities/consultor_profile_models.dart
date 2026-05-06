import 'package:equatable/equatable.dart';

class ConsultorProfile extends Equatable {
  const ConsultorProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    required this.totalSales,
    required this.conversionRate,
    required this.activeMonths,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String bio;
  final String? phone;
  final String? avatarUrl;
  final int totalSales;
  final double conversionRate;
  final int activeMonths;

  ConsultorProfile copyWith({String? bio}) => ConsultorProfile(
        id: id,
        name: name,
        email: email,
        bio: bio ?? this.bio,
        phone: phone,
        avatarUrl: avatarUrl,
        totalSales: totalSales,
        conversionRate: conversionRate,
        activeMonths: activeMonths,
      );

  factory ConsultorProfile.fromJson(Map<String, dynamic> json) =>
      ConsultorProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        bio: json['bio'] as String? ?? '',
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        totalSales: json['total_sales'] as int? ?? 0,
        conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0.0,
        activeMonths: json['active_months'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        bio,
        phone,
        avatarUrl,
        totalSales,
        conversionRate,
        activeMonths,
      ];
}

class SaleGoal extends Equatable {
  const SaleGoal({
    required this.month,
    required this.year,
    required this.target,
    required this.achieved,
  });

  final int month;
  final int year;
  final int target;
  final int achieved;

  double get progressPct => target == 0 ? 0 : (achieved / target).clamp(0, 1);
  bool get isCompleted => achieved >= target;

  factory SaleGoal.fromJson(Map<String, dynamic> json) => SaleGoal(
        month: json['month'] as int,
        year: json['year'] as int,
        target: json['target'] as int,
        achieved: json['achieved'] as int,
      );

  @override
  List<Object?> get props => [month, year, target, achieved];
}
