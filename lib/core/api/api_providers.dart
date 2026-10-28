import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/repositories/nursery_repository.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final connectionStatusProvider = StreamProvider<AppConnectionStatus>((ref) {
  final client = ref.watch(apiClientProvider);
  return Stream<AppConnectionStatus>.multi((controller) {
    controller.add(client.connectionStatus);
    final subscription = client.connectionChanges.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });
});

final nurseryRepositoryProvider = Provider<NurseryRepository>((ref) {
  return NurseryRepository(ref.watch(apiClientProvider));
});
