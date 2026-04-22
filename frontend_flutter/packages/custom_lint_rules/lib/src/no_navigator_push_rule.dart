import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Impede Navigator.push/pop direto — deve usar GoRouter (context.go/push)
class NoNavigatorPushRule extends DartLintRule {
  NoNavigatorPushRule()
      : super(
          code: const LintCode(
            name: 'no_navigator_push_direct',
            problemMessage:
                'Navigator.push/pop direto detectado. Use GoRouter (context.go / context.push / context.pop).',
            errorSeverity: ErrorSeverity.ERROR,
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      final target = node.realTarget?.toSource();
      final method = node.methodName.toSource();
      if (target == 'Navigator' &&
          (method == 'push' || method == 'pop' || method == 'pushNamed' || method == 'pushReplacement')) {
        reporter.reportErrorForNode(code, node);
      }
    });
  }
}
