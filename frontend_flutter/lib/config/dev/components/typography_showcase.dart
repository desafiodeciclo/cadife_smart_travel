import 'package:cadife_smart_travel/config/dev/component_library_models.dart';
import 'package:flutter/material.dart';

final typographyShowcases = [
  ComponentShowcaseData(
    name: 'Display Large',
    description: 'Headline style for landing pages.',
    category: ComponentCategory.typography,
    builder: (context) => Text(
      'Display Large',
      style: Theme.of(context).textTheme.displayLarge,
    ),
    codeSnippet: '''Text(
  'Display Large',
  style: Theme.of(context).textTheme.displayLarge,
)''',
  ),
  
  ComponentShowcaseData(
    name: 'Headline Large',
    description: 'Headline for main sections.',
    category: ComponentCategory.typography,
    builder: (context) => Text(
      'Headline Large',
      style: Theme.of(context).textTheme.headlineLarge,
    ),
    codeSnippet: '''Text(
  'Headline Large',
  style: Theme.of(context).textTheme.headlineLarge,
)''',
  ),

  ComponentShowcaseData(
    name: 'Title Large',
    description: 'Title for cards or list items.',
    category: ComponentCategory.typography,
    builder: (context) => Text(
      'Title Large',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    codeSnippet: '''Text(
  'Title Large',
  style: Theme.of(context).textTheme.titleLarge,
)''',
  ),

  ComponentShowcaseData(
    name: 'Body Large',
    description: 'Main body text.',
    category: ComponentCategory.typography,
    builder: (context) => Text(
      'Body Large',
      style: Theme.of(context).textTheme.bodyLarge,
    ),
    codeSnippet: '''Text(
  'Body Large',
  style: Theme.of(context).textTheme.bodyLarge,
)''',
  ),

  ComponentShowcaseData(
    name: 'Label Large',
    description: 'Label for buttons or small tags.',
    category: ComponentCategory.typography,
    builder: (context) => Text(
      'Label Large',
      style: Theme.of(context).textTheme.labelLarge,
    ),
    codeSnippet: '''Text(
  'Label Large',
  style: Theme.of(context).textTheme.labelLarge,
)''',
  ),
];
