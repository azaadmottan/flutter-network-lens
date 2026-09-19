import 'package:flutter/material.dart';
import 'package:flutter_network_lens/flutter_network_lens.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterNetworkLens.initialize(environment: 'demo');
  runApp(const _DemoApp());
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: _DemoPage(),
      );
}

class _DemoPage extends StatefulWidget {
  const _DemoPage();

  @override
  State<_DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<_DemoPage> {
  final _client = FlutterNetworkLensHttpClient(
    MockClient((request) async => http.Response(
          '{"message":"Hello from FlutterNetworkLens","password":"demo-secret"}',
          200,
          headers: {'content-type': 'application/json'},
        )),
  );

  Future<void> _captureRequest() async {
    await _client.get(Uri.parse('https://example.com/demo'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Demo request captured. Open the inspector.')),
    );
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('FlutterNetworkLens demo')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: _captureRequest,
                child: const Text('Capture demo request'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => FlutterNetworkLens.openInspector(context),
                child: const Text('Open inspector'),
              ),
            ],
          ),
        ),
      );
}
