import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/app_empty_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/error_state/app_error_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/error_state/error_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StateContainer<T> extends StatelessWidget {
  final AsyncValue<T> state;
  final Widget Function(T data) dataBuilder;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final bool isEmpty;
  final ErrorType? customErrorType;
  final EmptyType? customEmptyType;
  final VoidCallback? onRetry;
  
  const StateContainer({
    required this.state,
    required this.dataBuilder,
    this.loadingWidget,
    this.emptyWidget,
    this.isEmpty = false,
    this.customErrorType,
    this.customEmptyType,
    this.onRetry,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (data) {
        if (isEmpty) {
          return emptyWidget ??
            AppEmptyState(
              type: customEmptyType ?? EmptyType.emptyList,
            );
        }
        return dataBuilder(data);
      },
      loading: () =>
        loadingWidget ?? const _DefaultLoadingWidget(),
      error: (error, stackTrace) => AppErrorState(
        type: customErrorType ?? ErrorType.genericError,
        onRetry: onRetry,
      ),
    );
  }
}

class _DefaultLoadingWidget extends StatelessWidget {
  const _DefaultLoadingWidget();
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: context.cadife.primary),
          const SizedBox(height: 16),
          Text('Carregando...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

// Wrapper tipo ListView com suporte a estados
class StateListView<T> extends StatelessWidget {
  final AsyncValue<List<T>> state;
  final Widget Function(T, int) itemBuilder;
  final bool Function(List<T>)? isEmpty;
  final VoidCallback? onRetry;
  final EmptyType emptyType;
  final ErrorType? customErrorType;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  
  const StateListView({
    required this.state,
    required this.itemBuilder,
    this.isEmpty,
    this.onRetry,
    this.emptyType = EmptyType.emptyList,
    this.customErrorType,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (items) {
        final empty = isEmpty?.call(items) ?? items.isEmpty;
        
        if (empty) {
          return AppEmptyState(type: emptyType);
        }
        
        return ListView.builder(
          padding: padding,
          physics: physics,
          shrinkWrap: shrinkWrap,
          itemCount: items.length,
          itemBuilder: (context, index) =>
            itemBuilder(items[index], index),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => AppErrorState(
        type: customErrorType ?? ErrorType.genericError,
        onRetry: onRetry,
      ),
    );
  }
}
