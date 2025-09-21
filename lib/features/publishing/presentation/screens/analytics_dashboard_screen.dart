import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import '../bloc/analytics_bloc.dart';
import '../../domain/entities/analytics_data.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Analytics Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserAnalyticsSummaryLoaded) {
            return _buildSummaryView(context, state.summary);
          } else if state is TrendingContentLoaded) {
            return _buildTrendingContentView(context, state.trendingContent);
          } else if (state is AnalyticsError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }

          // Load initial data
          context.read<AnalyticsBloc>().add(
                LoadUserAnalyticsSummary('user123'), // In a real app, this would be the current user ID
              );

          return const Center(
            child: Text('Loading analytics summary...'),
          );
        },
      ),
    );
  }

  Widget _buildSummaryView(BuildContext context, AnalyticsSummary summary) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildSummaryCard(context, 'Views', summary.totalViews.toString()),
                const SizedBox(width: 16),
                _buildSummaryCard(context, 'Likes', summary.totalLikes.toString()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildSummaryCard(context, 'Shares', summary.totalShares.toString()),
                const SizedBox(width: 16),
                _buildSummaryCard(context, 'Comments', summary.totalComments.toString()),
              ],
            ),
          ),
          
          // Engagement rate
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Average Engagement Rate',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${summary.averageEngagementRate.toStringAsFixed(2)}%',
                      style: const TextStyle(fontSize: 24, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Platform metrics chart
          if (summary.platformMetrics.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Platform Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 200,
              child: _buildPlatformMetricsChart(summary.platformMetrics),
            ),
          ],
          
          // Trending content button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                context.read<AnalyticsBloc>().add(
                      LoadTrendingContent(limit: 10),
                    );
              },
              child: const Text('View Trending Content'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 20, color: Colors.deepPurple),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingContentView(BuildContext context, List<AnalyticsData> trendingContent) {
    return Column(
      children: [
        // Back button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: () {
                context.read<AnalyticsBloc>().add(
                      LoadUserAnalyticsSummary('user123'), // In a real app, this would be the current user ID
                    );
              },
              child: const Text('Back to Summary'),
            ),
          ),
        ),
        
        // Trending content list
        Expanded(
          child: ListView.builder(
            itemCount: trendingContent.length,
            itemBuilder: (context, index) {
              final content = trendingContent[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  title: Text('Content ID: ${content.contentId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Engagement Rate: ${content.engagementRate.toStringAsFixed(2)}%'),
                      Text('Views: ${content.views}, Likes: ${content.likes}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Compare with next item
                      if (index < trendingContent.length - 1) {
                        context.read<AnalyticsBloc>().add(
                              CompareContentPerformance(
                                content.contentId,
                                trendingContent[index + 1].contentId,
                              ),
                            );
                      }
                    },
                    child: const Text('Compare'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformMetricsChart(List<PlatformMetrics> platformMetrics) {
    final data = platformMetrics
        .map((metric) => PlatformMetricChartData(
              platform: metric.platform,
              engagement: metric.engagementRate,
            ))
        .toList();

    final series = [
      charts.Series<PlatformMetricChartData, String>(
        id: 'Engagement',
        domainFn: (PlatformMetricChartData data, _) => data.platform,
        measureFn: (PlatformMetricChartData data, _) => data.engagement,
        data: data,
      ),
    ];

    return charts.BarChart(
      series,
      animate: true,
    );
  }
}

class PlatformMetricChartData {
  final String platform;
  final double engagement;

  PlatformMetricChartData({required this.platform, required this.engagement});
}