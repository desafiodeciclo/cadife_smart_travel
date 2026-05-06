import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_event.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider temporário para expor o repositório — alinhado com o rename feito anteriormente
final authBlocProvider = Provider<AuthBloc>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final bloc = AuthBloc(repository)..add(const AuthEvent.authCheckRequested());
  
  ref.onDispose(bloc.close);
  return bloc;
});
