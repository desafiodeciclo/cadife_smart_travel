import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'src/no_hardcoded_hex_color_rule.dart';
import 'src/no_navigator_push_rule.dart';
import 'src/repository_pattern_rule.dart';

PluginBase createPlugin() => _CadifeLinterPlugin();

class _CadifeLinterPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    NoHardcodedHexColorRule(),
    NoNavigatorPushRule(),
    RepositoryPatternRule(),
  ];
}
