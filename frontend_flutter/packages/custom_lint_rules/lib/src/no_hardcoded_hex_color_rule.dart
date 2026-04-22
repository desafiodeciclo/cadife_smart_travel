import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Impede uso de Color(0x...) hardcoded — deve usar AppColors.*
class NoHardcodedHexColorRule extends DartLintRule {
  NoHardcodedHexColorRule()
      : super(
          code: const LintCode(
            name: 'no_hardcoded_hex_color',
            problemMessage:
                'Cor hexadecimal hardcoded detectada. Use AppColors.* ou AppTheme.* em vez de Color(0xff...).',
            errorSeverity: ErrorSeverity.ERROR,
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final constructorName = node.constructorName.toSource();
      if (constructorName.contains('Color') && node.argumentList.arguments.isNotEmpty) {
        final arg = node.argumentList.arguments.first;
        if (arg is IntegerLiteral) {
          final file = node.toSource();
          if (file.contains('0x') || file.contains('0X')) {
            reporter.reportErrorForNode(code, node);
          }
        }
      }
    });
  }
}
