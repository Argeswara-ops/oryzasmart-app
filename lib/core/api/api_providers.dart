import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/repositories/nursery_repository.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final nurseryRepositoryProvider = Provider<NurseryRepository>((ref) {
  return NurseryRepository(ref.watch(apiClientProvider));
});
