import 'package:equatable/equatable.dart';

enum BriefingFlagType { incerto, incorreto }

extension BriefingFlagTypeX on BriefingFlagType {
  String get label => switch (this) {
        BriefingFlagType.incerto => 'Incerto',
        BriefingFlagType.incorreto => 'Incorreto',
      };

  String get emoji => switch (this) {
        BriefingFlagType.incerto => '⚠️',
        BriefingFlagType.incorreto => '🚫',
      };
}

class BriefingFlag extends Equatable {
  const BriefingFlag({required this.field, required this.type});

  final String field;
  final BriefingFlagType type;

  Map<String, dynamic> toJson() => {'field': field, 'type': type.name};

  factory BriefingFlag.fromJson(Map<String, dynamic> json) => BriefingFlag(
        field: json['field'] as String,
        type: BriefingFlagType.values.byName(json['type'] as String),
      );

  @override
  List<Object?> get props => [field, type];
}
