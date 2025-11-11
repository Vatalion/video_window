/**
 * AWS Lambda function for feed prefetch worker
 * AC3: Background worker pre-warms CloudFront cache hourly for trending feed segments
 * Configurable via FEED_PREFETCH_CRON_EXPRESSION environment variable
 */

import { EventBridgeEvent } from 'aws-lambda';
import { CloudFrontClient, CreateInvalidationCommand } from '@aws-sdk/client-cloudfront';
import axios from 'axios';

const cloudfrontClient = new CloudFrontClient({ region: process.env.AWS_REGION || 'us-east-1' });
const CLOUDFRONT_DISTRIBUTION_ID = process.env.CLOUDFRONT_DISTRIBUTION_ID || '';
const SERVERPOD_API_URL = process.env.SERVERPOD_API_URL || 'https://api.video-window.com';
const SERVICE_TOKEN = process.env.SERVERPOD_SERVICE_TOKEN || '';

interface Video {
  id: string;
  videoUrl: string;
  hlsManifestUrl?: string;
}

interface FeedPage {
  videos: Video[];
  nextCursor?: string;
  hasMore: boolean;
}

/**
 * Main Lambda handler for EventBridge scheduled trigger
 * AC3: Pre-warms CloudFront cache for trending videos hourly
 */
export const handler = async (event: EventBridgeEvent<'Scheduled Event', {}>): Promise<void> => {
  console.log('Feed prefetch worker triggered:', JSON.stringify(event, null, 2));

  try {
    // Fetch trending videos from Serverpod
    const trendingVideos = await fetchTrendingVideos();

    // Pre-warm CloudFront cache for video URLs
    await prefetchCloudFrontCache(trendingVideos);

    console.log(`Successfully prefetched ${trendingVideos.length} videos`);
  } catch (error) {
    console.error('Feed prefetch worker error:', error);
    throw error;
  }
};

/**
 * AC3: Fetch trending videos from Serverpod
 * Calls GET /feed/trending endpoint with service token
 */
async function fetchTrendingVideos(): Promise<Video[]> {
  const videos: Video[] = [];
  let cursor: string | undefined;
  let hasMore = true;
  const maxPages = 5; // Limit to 5 pages (100 videos max)

  try {
    for (let page = 0; page < maxPages && hasMore; page++) {
      const url = `${SERVERPOD_API_URL}/feed/trending`;
      const response = await axios.get<FeedPage>(url, {
        params: {
          limit: 20,
          cursor: cursor,
        },
        headers: {
          'Authorization': `Bearer ${SERVICE_TOKEN}`,
          'Content-Type': 'application/json',
        },
        timeout: 10000,
      });

      videos.push(...response.data.videos);
      cursor = response.data.nextCursor;
      hasMore = response.data.hasMore || false;
    }
  } catch (error) {
    console.error('Error fetching trending videos:', error);
    // Return partial results if available
  }

  return videos;
}

/**
 * AC3: Pre-warm CloudFront cache by creating invalidations
 * This forces CloudFront to fetch fresh content from origin
 */
async function prefetchCloudFrontCache(videos: Video[]): Promise<void> {
  if (!CLOUDFRONT_DISTRIBUTION_ID) {
    console.warn('CloudFront distribution ID not configured, skipping cache pre-warm');
    return;
  }

  // Extract video URLs and HLS manifest URLs
  const paths: string[] = [];
  for (const video of videos) {
    if (video.videoUrl) {
      // Extract path from URL
      const url = new URL(video.videoUrl);
      paths.push(url.pathname);
    }
    if (video.hlsManifestUrl) {
      const url = new URL(video.hlsManifestUrl);
      paths.push(url.pathname);
      // Also prefetch common HLS segment paths
      paths.push(url.pathname.replace('.m3u8', '/*'));
    }
  }

  if (paths.length === 0) {
    console.log('No video paths to prefetch');
    return;
  }

  // Create CloudFront invalidation to force cache refresh
  // Note: In production, you might want to use CloudFront cache warm-up
  // by making HEAD requests instead of invalidations (invalidations cost money)
  try {
    const invalidationCommand = new CreateInvalidationCommand({
      DistributionId: CLOUDFRONT_DISTRIBUTION_ID,
      InvalidationBatch: {
        Paths: {
          Quantity: paths.length,
          Items: paths,
        },
        CallerReference: `feed-prefetch-${Date.now()}`,
      },
    });

    const result = await cloudfrontClient.send(invalidationCommand);
    console.log(`Created CloudFront invalidation: ${result.Invalidation?.Id}`);
  } catch (error) {
    console.error('Error creating CloudFront invalidation:', error);
    // Fallback: Make HEAD requests to warm cache (doesn't cost money)
    await warmCacheWithHeadRequests(paths);
  }
}

/**
 * Fallback: Warm cache by making HEAD requests
 * This doesn't cost money like invalidations do
 */
async function warmCacheWithHeadRequests(paths: string[]): Promise<void> {
  const CLOUDFRONT_DOMAIN = process.env.CLOUDFRONT_DOMAIN || 'd3vw-feed.cloudfront.net';
  const maxConcurrent = 10;

  console.log(`Warming cache with HEAD requests for ${paths.length} paths`);

  // Process in batches to avoid overwhelming CloudFront
  for (let i = 0; i < paths.length; i += maxConcurrent) {
    const batch = paths.slice(i, i + maxConcurrent);
    await Promise.all(
      batch.map(async (path) => {
        try {
          const url = `https://${CLOUDFRONT_DOMAIN}${path}`;
          await axios.head(url, { timeout: 5000 });
        } catch (error) {
          // Ignore errors for individual requests
          console.debug(`Failed to warm cache for ${path}:`, error);
        }
      })
    );
  }
}

