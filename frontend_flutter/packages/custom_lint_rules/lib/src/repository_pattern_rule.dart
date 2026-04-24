import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Detecta chamadas a Dio().get/post diretamente dentro de Notifier/Provider
/// Força uso do Repository pattern: Notifier → Repository → ApiService → Dio
class RepositoryPatternRule extends DartLintRule {
  RepositoryPatternRule()
    : super(
        code: const LintCode(
          name: 'use_repository_pattern',
          problemMessage:
              'Chamada HTTP direta em Notifier/Provider. Use Repository pattern: Notifier → *_Repository → ApiService → Dio.',
          errorSeverity: ErrorSeverity.ERROR,
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final isNotifier =
          className.contains('Notifier') ||
          className.contains('Provider') ||
          className.contains('Cubit');

      if (!isNotifier) return;

      for (final member in node.members) {
        if (member is MethodDeclaration) {
          member.visitChildren(_DioCallVisitor(reporter, code));
        }
      }
    });
  }
}

class _DioCallVisitor extends RecursiveAstVisitor<void> {
  _DioCallVisitor(this.reporter, this.code);
  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final method = node.methodName.toSource();
    final target = node.realTarget?.toSource();
    if ((target == 'Dio' || target == 'dio') &&
        ['get', 'post', 'put', 'delete', 'patch'].contains(method)) {
      reporter.reportErrorForNode(code, node);
    }
    super.visitMethodInvocation(node);
  }
}
