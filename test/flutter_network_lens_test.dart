import 'package:flutter_network_lens/flutter_network_lens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('records a completed network transaction', () async {
    await FlutterNetworkLens.initialize(storage: _MemoryStorage());
    FlutterNetworkLens.clear();

    FlutterNetworkLens.record(
      NetworkTransaction(
        id: 'request-1',
        request: NetworkRequest(
          method: 'GET',
          url: Uri.parse('https://api.example.com/profile'),
        ),
        response: NetworkResponse(statusCode: 200),
        timestamp: DateTime.utc(2026),
        duration: const Duration(milliseconds: 120),
      ),
    );

    expect(FlutterNetworkLens.transactions.single.statusCode, 200);
  });
}

final class _MemoryStorage implements NetworkStorage {
  List<NetworkTransaction> transactions = [];

  @override
  Future<void> clear() async => transactions = [];

  @override
  Future<List<NetworkTransaction>> readAll() async => transactions;

  @override
  Future<void> writeAll(List<NetworkTransaction> value) async => transactions = value;
}
