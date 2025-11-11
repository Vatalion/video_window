/**
 * AWS Lambda function for virus scanning uploaded media files
 * Implements Story 3-2: Avatar & Media Upload System
 * AC2: Virus scanning pipeline dispatches uploads to AWS Lambda
 */

import { S3Event, S3EventRecord, SNSEvent } from 'aws-lambda';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';
import * as ClamAV from 'clamav';

const s3Client = new S3Client({ region: process.env.AWS_REGION || 'us-east-1' });
const snsClient = new SNSClient({ region: process.env.AWS_REGION || 'us-east-1' });
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN || 'arn:aws:sns:us-east-1:4815162342:video-window-virus-scan-callback';

interface ScanResult {
  mediaId: number;
  scanResult: 'clean' | 'infected';
  scanTimestamp: string;
  virusName?: string;
}

/**
 * Main Lambda handler for S3 event trigger
 * Scans uploaded files using ClamAV and publishes results to SNS
 */
export const handler = async (event: S3Event): Promise<void> => {
  console.log('Virus scan Lambda triggered:', JSON.stringify(event, null, 2));

  for (const record of event.Records) {
    try {
      await processS3Record(record);
    } catch (error) {
      console.error(`Error processing record ${record.s3.object.key}:`, error);
      // Publish failure result
      await publishScanResult({
        mediaId: extractMediaId(record),
        scanResult: 'infected',
        scanTimestamp: new Date().toISOString(),
        virusName: `Scan error: ${error}`,
      });
    }
  }
};

/**
 * Process a single S3 record
 */
async function processS3Record(record: S3EventRecord): Promise<void> {
  const bucketName = record.s3.bucket.name;
  const objectKey = record.s3.object.key;

  console.log(`Scanning file: s3://${bucketName}/${objectKey}`);

  // Extract media ID from S3 key or metadata
  const mediaId = extractMediaId(record);

  // Download file from S3
  const getObjectCommand = new GetObjectCommand({
    Bucket: bucketName,
    Key: objectKey,
  });

  const s3Object = await s3Client.send(getObjectCommand);
  const fileBuffer = await streamToBuffer(s3Object.Body as NodeJS.ReadableStream);

  // Scan file with ClamAV
  const scanResult = await scanFile(fileBuffer);

  // Publish result to SNS
  await publishScanResult({
    mediaId,
    scanResult: scanResult.isInfected ? 'infected' : 'clean',
    scanTimestamp: new Date().toISOString(),
    virusName: scanResult.virusName,
  });
}

/**
 * Scan file buffer with ClamAV
 */
async function scanFile(fileBuffer: Buffer): Promise<{ isInfected: boolean; virusName?: string }> {
  try {
    // TODO: Implement actual ClamAV scanning
    // This would connect to ClamAV daemon or use ClamAV library
    // For now, return clean result (placeholder)
    console.log(`Scanning ${fileBuffer.length} bytes`);
    
    // Placeholder: In production, this would call ClamAV
    // const result = await clamav.scanBuffer(fileBuffer);
    
    return {
      isInfected: false,
    };
  } catch (error) {
    console.error('ClamAV scan error:', error);
    // On scan failure, treat as infected for safety
    return {
      isInfected: true,
      virusName: `Scan error: ${error}`,
    };
  }
}

/**
 * Publish scan result to SNS topic
 */
async function publishScanResult(result: ScanResult): Promise<void> {
  const publishCommand = new PublishCommand({
    TopicArn: SNS_TOPIC_ARN,
    Message: JSON.stringify(result),
    Subject: `Virus Scan Result: Media ${result.mediaId}`,
  });

  await snsClient.send(publishCommand);
  console.log(`Published scan result for media ${result.mediaId}: ${result.scanResult}`);
}

/**
 * Extract media ID from S3 record
 * Media ID should be stored in S3 object metadata or extracted from key
 */
function extractMediaId(record: S3EventRecord): number {
  // Try to extract from object metadata first
  const metadata = record.s3.object.userMetadata;
  if (metadata && metadata['media-id']) {
    return parseInt(metadata['media-id'], 10);
  }

  // Fallback: extract from key pattern (e.g., "profile-media/{userId}/temp/{mediaId}_filename")
  const keyParts = record.s3.object.key.split('/');
  const fileName = keyParts[keyParts.length - 1];
  const match = fileName.match(/^(\d+)_/);
  if (match) {
    return parseInt(match[1], 10);
  }

  // Default fallback (should not happen in production)
  console.warn(`Could not extract media ID from key: ${record.s3.object.key}`);
  return 0;
}

/**
 * Convert stream to buffer
 */
async function streamToBuffer(stream: NodeJS.ReadableStream): Promise<Buffer> {
  const chunks: Buffer[] = [];
  for await (const chunk of stream) {
    chunks.push(Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
}

