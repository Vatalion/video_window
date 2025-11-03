# AWS CloudFront CDN Guide - Video Window

**Version:** CloudFront Latest  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Video Delivery (Epic 06)

---

## Overview

CloudFront CDN delivers Video Window's HLS video streams globally with signed URLs for security.

---

## CloudFront Configuration

### Distribution Setup

```yaml
# Infrastructure (Terraform)
resource "aws_cloudfront_distribution" "video_cdn" {
  origin {
    domain_name = aws_s3_bucket.videos.bucket_regional_domain_name
    origin_id   = "S3-videos"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.videos.cloudfront_access_identity_path
    }
  }
  
  enabled             = true
  price_class         = "PriceClass_100"  # US, Canada, Europe
  default_root_object = "index.html"
  
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-videos"
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    min_ttl     = 0
    default_ttl = 86400   # 24 hours
    max_ttl     = 31536000 # 1 year
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn           = aws_acm_certificate.cdn.arn
    ssl_support_method            = "sni-only"
    minimum_protocol_version      = "TLSv1.2_2021"
  }
  
  custom_error_response {
    error_code         = 403
    response_code      = 403
    response_page_path = "/error.html"
  }
}
```

---

## Signed URLs (Security)

### Server-Side Signing

```dart
// video_window_server/lib/src/services/cloudfront_signer.dart
import 'package:cloudfront_signer/cloudfront_signer.dart';
import 'package:rsa_pkcs/rsa_pkcs.dart' as rsa;

class CloudFrontSigner {
  final String _keyPairId;
  final rsa.RSAPrivateKey _privateKey;
  final String _domainName;
  
  CloudFrontSigner({
    required String keyPairId,
    required String privateKeyPem,
    required String domainName,
  })  : _keyPairId = keyPairId,
        _privateKey = rsa.RSAPKCSParser().parsePEM(privateKeyPem).private,
        _domainName = domainName;
  
  String getSignedUrl(
    String resourcePath,
    Duration expiresIn,
  ) {
    final url = 'https://$_domainName/$resourcePath';
    final expiry = DateTime.now().add(expiresIn);
    
    // Create policy
    final policy = {
      'Statement': [
        {
          'Resource': url,
          'Condition': {
            'DateLessThan': {
              'AWS:EpochTime': expiry.millisecondsSinceEpoch ~/ 1000,
            },
          },
        },
      ],
    };
    
    final policyJson = jsonEncode(policy);
    final policyBase64 = base64Url.encode(utf8.encode(policyJson));
    
    // Sign policy
    final signature = _signPolicy(policyBase64);
    
    // Build signed URL
    return '$url?'
        'Expires=${expiry.millisecondsSinceEpoch ~/ 1000}&'
        'Signature=$signature&'
        'Key-Pair-Id=$_keyPairId';
  }
  
  String _signPolicy(String policy) {
    final signer = rsa.RSASigner(rsa.RSASignDigest.SHA1, privateKey: _privateKey);
    final signature = signer.sign(utf8.encode(policy));
    return base64Url.encode(signature).replaceAll('=', '');
  }
}
```

### Usage in Endpoints

```dart
// video_window_server/lib/src/endpoints/media/video_endpoint.dart
@override
Future<String> getVideoPlaybackUrl(Session session, String storyId) async {
  final story = await Story.findById(session, storyId);
  if (story == null) throw StoryNotFoundException();
  
  // Verify user has access
  await _verifyAccess(session, story);
  
  // Generate signed URL (1 hour expiry)
  final signer = CloudFrontSigner(
    keyPairId: _getEnvVar('CLOUDFRONT_KEY_PAIR_ID'),
    privateKeyPem: _getEnvVar('CLOUDFRONT_PRIVATE_KEY'),
    domainName: 'cdn.videowindow.app',
  );
  
  return signer.getSignedUrl(
    'stories/${story.id}/hls/master.m3u8',
    Duration(hours: 1),
  );
}
```

---

## Cache Invalidation

```dart
// video_window_server/lib/src/services/cloudfront_service.dart
import 'package:aws_cloudfront_api/cloudfront-2020-05-31.dart';

class CloudFrontService {
  final CloudFront _cloudfront;
  final String _distributionId;
  
  CloudFrontService(String region, this._distributionId)
      : _cloudfront = CloudFront(
          region: region,
          credentials: AwsClientCredentials(
            accessKey: _getEnvVar('AWS_ACCESS_KEY_ID'),
            secretKey: _getEnvVar('AWS_SECRET_ACCESS_KEY'),
          ),
        );
  
  Future<void> invalidateCache(List<String> paths) async {
    await _cloudfront.createInvalidation(
      distributionId: _distributionId,
      invalidationBatch: InvalidationBatch(
        paths: Paths(
          quantity: paths.length,
          items: paths,
        ),
        callerReference: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    );
  }
  
  // Example: Invalidate story video
  Future<void> invalidateStory(String storyId) async {
    await invalidateCache([
      '/stories/$storyId/*',
    ]);
  }
}
```

---

## Custom Domain (CNAME)

```yaml
# Terraform
resource "aws_route53_record" "cdn" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "cdn.videowindow.app"
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.video_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.video_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
```

---

## HLS-Specific Configuration

### Cache Behaviors

```yaml
# Master playlist - short cache
default_cache_behavior {
  path_pattern     = "*/master.m3u8"
  default_ttl      = 60      # 1 minute
  max_ttl          = 300     # 5 minutes
}

# Media playlists - medium cache
default_cache_behavior {
  path_pattern     = "*/index.m3u8"
  default_ttl      = 3600    # 1 hour
  max_ttl          = 86400   # 24 hours
}

# Video segments - long cache
default_cache_behavior {
  path_pattern     = "*.ts"
  default_ttl      = 86400   # 24 hours
  max_ttl          = 31536000 # 1 year
}
```

---

## Performance Optimization

### Gzip Compression

```yaml
default_cache_behavior {
  compress = true  # Compress .m3u8 playlists
}
```

### Range Requests

```yaml
# Enable byte-range requests for large segments
default_cache_behavior {
  cached_methods = ["GET", "HEAD", "OPTIONS"]
}
```

---

## Monitoring

```dart
Future<CloudFrontStatistics> getStatistics(Duration period) async {
  final response = await _cloudfront.getDistributionStatistics(
    distributionId: _distributionId,
    startTime: DateTime.now().subtract(period),
    endTime: DateTime.now(),
  );
  
  return CloudFrontStatistics(
    requests: response.totalRequests,
    bytesDownloaded: response.bytesDownloaded,
    cacheHitRate: response.cacheHitRate,
  );
}
```

---

## Video Window Conventions

- **Domain:** `cdn.videowindow.app`
- **Signed URLs:** 1-hour expiry for HLS manifests
- **Cache TTL:**
  - Master playlist: 1 minute
  - Media playlists: 1 hour
  - Segments (.ts): 24 hours
- **SSL:** TLS 1.2+ only
- **Origin:** S3 with Origin Access Identity (private bucket)
- **Compression:** Enabled for text files (.m3u8)

---

## Testing

```dart
test('CloudFront signed URL expires in 1 hour', () {
  final signer = CloudFrontSigner(
    keyPairId: 'test-key',
    privateKeyPem: testPrivateKey,
    domainName: 'cdn.test.com',
  );
  
  final url = signer.getSignedUrl(
    'test/video.m3u8',
    Duration(hours: 1),
  );
  
  expect(url, contains('Expires='));
  expect(url, contains('Signature='));
  expect(url, contains('Key-Pair-Id='));
});
```

---

## Reference

- **CloudFront Docs:** https://docs.aws.amazon.com/cloudfront/
- **Signed URLs:** https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-signed-urls.html

---

**Last Updated:** 2025-11-03 by Winston
