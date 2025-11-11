import 'package:flutter/material.dart';

/// Footer widget for infinite scroll states
/// AC3: Displays loading, error, and end-of-feed states with retry capability
enum InfiniteScrollFooterState {
  loading,
  error,
  endOfFeed,
}

class InfiniteScrollFooter extends StatelessWidget {
  final InfiniteScrollFooterState state;
  final VoidCallback? onRetry;
  final String? errorMessage;

  const InfiniteScrollFooter({
    super.key,
    required this.state,
    this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case InfiniteScrollFooterState.loading:
        return _buildLoadingState();
      case InfiniteScrollFooterState.error:
        return _buildErrorState(context);
      case InfiniteScrollFooterState.endOfFeed:
        return _buildEndOfFeedState();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white70,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Failed to load more videos',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndOfFeedState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.white54,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'You\'ve reached the end',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
