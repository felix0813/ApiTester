import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/collection_provider.dart';
import '../../providers/request_provider.dart';
import '../../../data/models/api_request.dart';
import '../../../services/runner_engine.dart';
import '../../../core/constants/app_colors.dart';

class RunnerScreen extends ConsumerStatefulWidget {
  final String collectionId;

  const RunnerScreen({super.key, required this.collectionId});

  @override
  ConsumerState<RunnerScreen> createState() => _RunnerScreenState();
}

class _RunnerScreenState extends ConsumerState<RunnerScreen> {
  bool _isRunning = false;
  RunnerResult? _result;
  int _currentProgress = 0;
  int _totalRequests = 0;

  Future<void> _runCollection() async {
    setState(() {
      _isRunning = true;
      _result = null;
      _currentProgress = 0;
    });

    try {
      final collectionItems = ref.read(collectionTreeProvider).valueOrNull ?? [];
      final requests = ref.read(requestRepositoryProvider);

      final allItems = collectionItems.where((c) => c.parentId == widget.collectionId).toList();
      final requestIds = allItems.where((c) => c.isRequest && c.requestId != null).map((c) => c.requestId!).toList();

      final apiRequests = <ApiRequest>[];
      for (final id in requestIds) {
        final req = await requests.getById(id);
        if (req != null) apiRequests.add(req);
      }

      if (apiRequests.isEmpty) {
        setState(() {
          _isRunning = false;
        });
        return;
      }

      _totalRequests = apiRequests.length;

      final runner = RunnerEngine();
      final result = await runner.runRequests(
        collectionName: 'Collection Run',
        requests: apiRequests,
        onProgress: (current, total, result) {
          setState(() => _currentProgress = current);
        },
      );

      setState(() {
        _result = result;
        _isRunning = false;
      });
    } catch (e) {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : context.go('/collections'),
        ),
        title: const Text('Collection Runner'),
        actions: [
          if (!_isRunning)
            TextButton.icon(
              onPressed: _runCollection,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run'),
            ),
        ],
      ),
      body: _isRunning
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _totalRequests > 0 ? _currentProgress / _totalRequests : null,
                  ),
                  const SizedBox(height: 16),
                  Text('Running request $_currentProgress of $_totalRequests'),
                ],
              ),
            )
          : _result != null
              ? _buildResults()
              : const Center(
                  child: Text('Tap Run to execute all requests in this collection'),
                ),
    );
  }

  Widget _buildResults() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Total',
                  value: _result!.results.length.toString(),
                  color: Colors.blue,
                ),
                _SummaryItem(
                  label: 'Passed',
                  value: _result!.passCount.toString(),
                  color: Colors.green,
                ),
                _SummaryItem(
                  label: 'Failed',
                  value: _result!.failCount.toString(),
                  color: Colors.red,
                ),
                _SummaryItem(
                  label: 'Duration',
                  value: '${_result!.totalDuration.inMilliseconds}ms',
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _result!.results.length,
            itemBuilder: (context, index) {
              final result = _result!.results[index];
              return _ResultTile(result: result);
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final RunnerRequestResult result;

  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final methodColor = AppColors.forMethod(result.request.method);
    final hasError = result.error != null;
    final scriptFailed = result.scriptResult?.passed == false;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: methodColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            result.request.method,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: methodColor,
            ),
          ),
        ),
        title: Text(result.request.name, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          hasError
              ? result.error!
              : scriptFailed
                  ? result.scriptResult!.errorMessage!
                  : '${result.response?.statusCode} - ${result.duration.inMilliseconds}ms',
          style: TextStyle(
            fontSize: 11,
            color: hasError || scriptFailed ? Colors.red : Colors.grey,
          ),
        ),
        trailing: Icon(
          result.passed ? Icons.check_circle : Icons.cancel,
          color: result.passed ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
    );
  }
}
