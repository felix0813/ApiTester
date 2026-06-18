import 'package:flutter/material.dart';
import '../../data/models/api_response.dart';
import '../../core/constants/app_colors.dart';
import 'status_badge.dart';

class ResponseViewer extends StatefulWidget {
  final ApiResponse? response;
  final bool isLoading;
  final String? error;

  const ResponseViewer({
    super.key,
    this.response,
    this.isLoading = false,
    this.error,
  });

  @override
  State<ResponseViewer> createState() => _ResponseViewerState();
}

class _ResponseViewerState extends State<ResponseViewer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Sending request...'),
          ],
        ),
      );
    }

    if (widget.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 8),
            Text(widget.error!, style: const TextStyle(color: AppColors.error)),
          ],
        ),
      );
    }

    final resp = widget.response;

    if (resp == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.send_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Tap Send to make a request',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              StatusBadge(
                statusCode: resp.statusCode,
                statusText: resp.statusText,
              ),
              const SizedBox(width: 16),
              _InfoChip(
                icon: Icons.timer_outlined,
                label: resp.formattedDuration,
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.data_usage,
                label: resp.formattedSize,
              ),
            ],
          ),
        ),
        // Tab bar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Body'),
            Tab(text: 'Headers'),
          ],
          labelStyle: const TextStyle(fontSize: 13),
          indicatorSize: TabBarIndicatorSize.label,
        ),
        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBodyTab(resp),
              _buildHeadersTab(resp),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBodyTab(ApiResponse resp) {
    if (resp.body.isEmpty) {
      return const Center(child: Text('Empty response body'));
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Pretty', height: 32),
              Tab(text: 'Raw', height: 32),
            ],
            labelStyle: TextStyle(fontSize: 12),
            indicatorSize: TabBarIndicatorSize.label,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPrettyBody(resp),
                _buildRawBody(resp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrettyBody(ApiResponse resp) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: SelectableText(
          resp.prettyBody,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Color(0xFFD4D4D4),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRawBody(ApiResponse resp) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: SelectableText(
          resp.body,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Color(0xFFD4D4D4),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHeadersTab(ApiResponse resp) {
    if (resp.headers.isEmpty) {
      return const Center(child: Text('No response headers'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: resp.headers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = resp.headers.entries.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: SelectableText(
                  entry.value,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
