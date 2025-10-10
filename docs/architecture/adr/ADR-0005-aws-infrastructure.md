# ADR-0005: AWS Infrastructure Strategy

**Date:** 2025-10-09
**Status:** Accepted
**Decider(s):** Technical Lead, DevOps Engineer, Infrastructure Team
**Reviewers:** Development Team, Security Team, Finance Team

## Context
The video auctions platform requires a robust, scalable, and secure infrastructure that can handle:
- Video processing and storage
- Real-time auction operations
- Payment processing and compliance
- High availability and disaster recovery
- Multi-region deployment (future)
- Cost optimization
- Security and compliance requirements

## Decision
Implement a comprehensive AWS infrastructure strategy using a multi-service approach with VPC, ECS/Fargate, RDS, ElastiCache, S3, CloudFront, and supporting services.

## Options Considered

1. **Option A** - Multi-Cloud Strategy (AWS + GCP)
   - Pros: Vendor diversification, best-of-breed services
   - Cons: Increased complexity, higher operational overhead
   - Risk: Integration challenges, higher costs

2. **Option B** - Google Cloud Platform
   - Pros: Strong data analytics, competitive pricing
   - Cons: Smaller marketplace, fewer specialized services
   - Risk: Limited ecosystem, migration complexity

3. **Option C** - Azure
   - Pros: Enterprise features, hybrid capabilities
   - Cons: Less focused on startups, higher costs
   - Risk: Complex pricing model

4. **Option D** - AWS-Centric Strategy (Chosen)
   - Pros: Comprehensive service offering, mature ecosystem, excellent documentation, competitive pricing
   - Cons: Vendor lock-in, complex pricing structure
   - Risk: Cost management complexity

## Decision Outcome
Chose Option D: AWS-Centric Strategy. This provides:
- Comprehensive service ecosystem
- Excellent scalability options
- Strong security and compliance features
- Mature development and management tools
- Competitive pricing for startups

## Consequences

- **Positive:**
  - Comprehensive service integration
  - Excellent scalability and reliability
  - Strong security and compliance features
  - Mature developer tooling
  - Extensive documentation and community
  - Good startup pricing and credits

- **Negative:**
  - Vendor lock-in to AWS ecosystem
  - Complex pricing structure to manage
  - Learning curve for AWS services
  - Potential for unexpected costs

- **Neutral:**
  - Infrastructure management overhead
  - Team skills development
  - Migration costs from other providers

## Architecture Overview

### Infrastructure Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                           AWS Cloud                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐│
│  │   CloudFront    │    │    API Gateway  │    │   Elastic Bean  ││
│  │      CDN        │    │                 │    │     stalk       ││
│  └─────────────────┘    └─────────────────┘    └─────────────────┘│
│           │                       │                       │       │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐│
│  │      S3         │    │  ECS/Fargate    │    │     RDS         ││
│  │   Object Store  │    │   Container     │    │   PostgreSQL    ││
│  └─────────────────┘    └─────────────────┘    └─────────────────┘│
│           │                       │                       │       │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐│
│  │   ElastiCache   │    │       VPC       │    │   Secrets Mgr   ││
│  │     Redis       │    │     Network     │    │   Secrets       ││
│  └─────────────────┘    └─────────────────┘    └─────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### Core Infrastructure Components

#### 1. Networking (VPC)
```yaml
# VPC Configuration
Resources:
  VideoWindowVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: VideoWindow-VPC

  PublicSubnetA:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VideoWindowVPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: us-east-1a
      MapPublicIpOnLaunch: true

  PrivateSubnetA:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VideoWindowVPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: us-east-1a
```

#### 2. Compute (ECS/Fargate)
```yaml
# ECS Cluster
Resources:
  VideoWindowCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: VideoWindow-Cluster
      CapacityProviders:
        - FARGATE
        - FARGATE_SPOT

  ServerpodService:
    Type: AWS::ECS::Service
    Properties:
      Cluster: !Ref VideoWindowCluster
      TaskDefinition: !Ref ServerpodTaskDefinition
      DesiredCount: 2
      LaunchType: FARGATE
      NetworkConfiguration:
        AwsvpcConfiguration:
          SecurityGroups:
            - !Ref ServerpodSecurityGroup
          Subnets:
            - !Ref PrivateSubnetA
            - !Ref PrivateSubnetB
```

#### 3. Database (RDS PostgreSQL)
```yaml
# RDS Configuration
Resources:
  VideoWindowDB:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceIdentifier: VideoWindow-DB
      DBInstanceClass: db.t3.micro
      Engine: postgres
      EngineVersion: 15.4
      MasterUsername: !Ref DBUsername
      MasterUserPassword: !Ref DBPassword
      AllocatedStorage: 20
      StorageType: gp2
      VPCSecurityGroups:
        - !Ref DatabaseSecurityGroup
      DBSubnetGroupName: !Ref DBSubnetGroup
      BackupRetentionPeriod: 7
      MultiAZ: false
      StorageEncrypted: true
```

#### 4. Cache (ElastiCache Redis)
```yaml
# ElastiCache Configuration
Resources:
  VideoWindowRedis:
    Type: AWS::ElastiCache::CacheCluster
    Properties:
      CacheNodeType: cache.t3.micro
      Engine: redis
      NumCacheNodes: 1
      CacheSubnetGroupName: !Ref RedisSubnetGroup
      VpcSecurityGroupIds:
        - !Ref RedisSecurityGroup
```

#### 5. Storage (S3)
```yaml
# S3 Buckets
Resources:
  VideoBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'videowindow-videos-${AWS::AccountId}'
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      VersioningConfiguration:
        Status: Enabled
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256

  ThumbnailBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'videowindow-thumbnails-${AWS::AccountId}'
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
```

### Service Architecture

#### Application Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layers                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐│
│  │  Load Balancer  │    │  Auto Scaling   │    │   ECS Cluster   ││
│  │    (ALB)        │    │    Groups       │    │   (Fargate)     ││
│  └─────────────────┘    └─────────────────┘    └─────────────────┘│
│           │                       │                       │       │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐│
│  │   Serverpod     │    │   WebSocket     │    │   Video Process ││
│  │   Backend       │    │   Service       │    │     Service     ││
│  └─────────────────┘    └─────────────────┘    └─────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

#### Data Flow Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                        Data Flow                                │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐│
│  │   User Upload   │    │   S3 Storage    │    │   CloudFront    ││
│  │                 │────────────────────►│────────────────────►││
│  └─────────────────┘    └─────────────────┘    └─────────────────┘│
│           │                       │                       │       │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐│
│  │   Database      │    │     Redis       │    │   CDN Cache     ││
│  │   (PostgreSQL)  │    │                 │    │                 ││
│  └─────────────────┘    └─────────────────┘    └─────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## Implementation Strategy

### Phase 1: Core Infrastructure (Week 1-2)
- Set up VPC and networking
- Deploy ECS cluster with basic service
- Configure RDS and ElastiCache
- Set up S3 buckets and CloudFront
- Implement basic monitoring

### Phase 2: Application Deployment (Week 3-4)
- Deploy Serverpod backend
- Configure auto-scaling
- Set up load balancing
- Implement CI/CD pipeline
- Add logging and monitoring

### Phase 3: Security and Compliance (Week 5)
- Configure security groups and NACLs
- Set up encryption at rest and in transit
- Implement IAM roles and policies
- Add security monitoring
- Set up backup and disaster recovery

### Phase 4: Optimization (Week 6)
- Performance tuning
- Cost optimization
- Monitoring and alerting
- Documentation and runbooks

## Security Configuration

### Network Security
```yaml
# Security Groups
Resources:
  WebSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for web services
      VpcId: !Ref VideoWindowVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0

  DatabaseSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for database
      VpcId: !Ref VideoWindowVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          SourceSecurityGroupId: !Ref WebSecurityGroup
```

### IAM Roles
```yaml
# IAM Roles
Resources:
  ECSTaskRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ecs-tasks.amazonaws.com
            Action: sts:AssumeRole
      Policies:
        - PolicyName: ECS-Tasks-Policy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:PutObject
                Resource: !Sub 'arn:aws:s3:::videowindow-videos-${AWS::AccountId}/*'
```

## Monitoring and Logging

### CloudWatch Configuration
```yaml
# CloudWatch Alarms
Resources:
  CPUUtilizationAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: VideoWindow-CPU-High
      AlarmDescription: CPU utilization is too high
      MetricName: CPUUtilization
      Namespace: AWS/ECS
      Statistic: Average
      Period: 300
      EvaluationPeriods: 2
      Threshold: 80
      ComparisonOperator: GreaterThanThreshold
      AlarmActions:
        - !Ref SNSTopicARN
```

### Logging Strategy
- **Application Logs**: CloudWatch Logs
- **Access Logs**: CloudWatch + S3 archival
- **Database Logs**: CloudWatch Logs
- **Security Logs**: CloudTrail
- **Performance Metrics**: CloudWatch Metrics

## Cost Optimization

### Resource Sizing
- **Compute**: Fargate Spot for non-critical workloads
- **Database**: Graviton instances when available
- **Storage**: S3 Intelligent-Tiering for video storage
- **Network**: CloudFront for CDN and caching

### Cost Monitoring
- **AWS Budgets**: Monthly spending limits
- **Cost Explorer**: Detailed cost analysis
- **Trusted Advisor**: Optimization recommendations
- **Instance Rightsizing**: Regular review and optimization

## Disaster Recovery

### Backup Strategy
- **Database**: Automated daily backups with point-in-time recovery
- **S3**: Versioning enabled with cross-region replication
- **Configuration**: Infrastructure as Code in Git
- **Documentation**: Runbooks and recovery procedures

### High Availability
- **Multi-AZ**: Database and cache deployment
- **Auto Scaling**: Automatic scaling based on demand
- **Health Checks**: Automated health monitoring
- **Failover**: Automatic failover for critical services

## Related ADRs
- ADR-0002: Flutter + Serverpod Architecture
- ADR-0003: Database Architecture: PostgreSQL + Redis
- ADR-0004: Payment Processing: Stripe Connect Express

## References
- [AWS Documentation](https://docs.aws.amazon.com/)
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/)
- [Infrastructure Security Best Practices](../security-configuration.md)
- [Cost Optimization Guide](../cost-optimization.md)

## Status Updates
- **2025-10-09**: Accepted - AWS infrastructure strategy confirmed
- **2025-10-09**: Infrastructure planning in progress
- **TBD**: Implementation phase begins

---

*This ADR establishes a comprehensive AWS infrastructure strategy that provides scalability, security, and cost-effectiveness for the video auctions platform.*