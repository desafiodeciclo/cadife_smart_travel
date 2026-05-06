import 'package:flutter/material.dart';

enum ComponentCategory {
  buttons,
  inputs,
  cards,
  feedback,
  navigation,
  typography,
  colors,
}

extension ComponentCategoryName on ComponentCategory {
  String get displayName {
    return switch (this) {
      ComponentCategory.buttons => 'Botões',
      ComponentCategory.inputs => 'Inputs',
      ComponentCategory.cards => 'Cards',
      ComponentCategory.feedback => 'Feedback',
      ComponentCategory.navigation => 'Navegação',
      ComponentCategory.typography => 'Tipografia',
      ComponentCategory.colors => 'Cores',
    };
  }
  
  IconData get icon {
    return switch (this) {
      ComponentCategory.buttons => Icons.touch_app,
      ComponentCategory.inputs => Icons.input,
      ComponentCategory.cards => Icons.rectangle,
      ComponentCategory.feedback => Icons.notifications,
      ComponentCategory.navigation => Icons.menu,
      ComponentCategory.typography => Icons.text_fields,
      ComponentCategory.colors => Icons.palette,
    };
  }
}

class ComponentShowcaseData {
  final String name;
  final String description;
  final ComponentCategory category;
  final Widget Function(BuildContext) builder;
  final String codeSnippet;
  final List<String>? notes;
  
  ComponentShowcaseData({
    required this.name,
    required this.description,
    required this.category,
    required this.builder,
    required this.codeSnippet,
    this.notes,
  });
}
