import 'package:cadife_smart_travel/core/network/dio_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiServiceProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider);
});
