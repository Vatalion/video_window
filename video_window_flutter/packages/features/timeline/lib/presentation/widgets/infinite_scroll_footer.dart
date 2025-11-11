import 'package:flutter/material.dart';

/// Footer widget for infinite scroll loading state
/// AC2: Shows loading indicator when fetching next page
class InfiniteScrollFooter extends StatelessWidget {
  const InfiniteScrollFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}
