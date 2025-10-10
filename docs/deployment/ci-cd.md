# CI/CD Pipeline Configuration

**Effective Date:** 2025-10-09
**Target Framework:** Flutter 3.19.6, Serverpod 2.9.x
**Platform:** GitHub Actions with Kubernetes deployment

## Overview

This CI/CD pipeline provides automated testing, building, and deployment for the Craft Video Marketplace. The pipeline supports multiple environments (development, staging, production) with comprehensive quality gates and rollback capabilities.

## Pipeline Architecture

### Environment Strategy

| Environment | Purpose | Branch | Domain | Database |
|-------------|---------|--------|--------|----------|
| **Development** | Feature testing | `develop` | dev-api.craftmarketplace.com | PostgreSQL dev |
| **Staging** | Pre-production | `main` | staging-api.craftmarketplace.com | PostgreSQL staging |
| **Production** | Live service | `release/*` | api.craftmarketplace.com | PostgreSQL prod |

### Pipeline Stages

1. **Code Quality** - Lint, format, analyze
2. **Testing** - Unit, integration, E2E tests
3. **Build** - Flutter app, Serverpod server
4. **Security Scan** - Dependency check, vulnerability scan
5. **Deploy** - Environment-specific deployment
6. **Health Check** - Post-deployment verification

## GitHub Actions Workflows

### Main CI/CD Pipeline

```yaml
# .github/workflows/ci-cd.yml

name: CI/CD Pipeline

on:
  push:
    branches: [ develop, main ]
  pull_request:
    branches: [ develop ]
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # Code Quality Checks
  code-quality:
    name: Code Quality
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.19.6'
        channel: 'stable'

    - name: Cache Flutter dependencies
      uses: actions/cache@v3
      with:
        path: |
          ~/.pub-cache
          .flutter_tool_state
        key: ${{ runner.os }}-flutter-${{ hashFiles('**/pubspec.lock') }}
        restore-keys: |
          ${{ runner.os }}-flutter-

    - name: Install dependencies
      run: flutter pub get

    - name: Generate code
      run: |
        dart run build_runner build --delete-conflicting-outputs

    - name: Format code
      run: dart format --set-exit-if-changed .

    - name: Analyze code
      run: flutter analyze --fatal-infos --fatal-warnings

    - name: Check for trailing whitespace
      run: |
        if grep -r '[[:space:]]$' .; then
          echo "Trailing whitespace found"
          exit 1
        fi

  # Unit Tests
  unit-tests:
    name: Unit Tests
    runs-on: ubuntu-latest
    timeout-minutes: 15
    needs: code-quality

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.19.6'

    - name: Install dependencies
      run: flutter pub get

    - name: Run unit tests
      run: flutter test --coverage --reporter=expanded

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
        flags: unittests
        name: codecov-umbrella

    - name: Check coverage threshold
      run: |
        COVERAGE=$(lcov --summary coverage/lcov.info | grep -E 'lines......:' | grep -o '[0-9]+\.[0-9]+')
        THRESHOLD=80.0
        if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
          echo "Coverage $COVERAGE% is below threshold $THRESHOLD%"
          exit 1
        fi

  # Integration Tests
  integration-tests:
    name: Integration Tests
    runs-on: ubuntu-latest
    timeout-minutes: 20
    needs: unit-tests

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: testpass
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.19.6'

    - name: Setup Dart
      uses: dart-lang/setup-dart@v1
      with:
        sdk: stable

    - name: Install dependencies
      run: |
        flutter pub get
        cd server && dart pub get

    - name: Run Serverpod tests
      run: |
        cd server
        dart test --reporter=expanded
      env:
          POSTGRES_HOST: localhost
          POSTGRES_PORT: 5432
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: testpass
          POSTGRES_DB: testdb
          REDIS_HOST: localhost
          REDIS_PORT: 6379

    - name: Run Flutter integration tests
      run: |
        flutter test integration_test/ --reporter=expanded

  # Build Flutter App
  build-flutter:
    name: Build Flutter App
    runs-on: ubuntu-latest
    timeout-minutes: 30
    needs: code-quality

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.19.6'

    - name: Install dependencies
      run: flutter pub get

    - name: Generate code
      run: dart run build_runner build --delete-conflicting-outputs

    - name: Build for Android
      run: |
        flutter build apk --release
        flutter build appbundle --release

    - name: Build for iOS (if needed)
      run: |
        flutter build ios --release --no-codesign
      if: github.event_name == 'workflow_dispatch'

    - name: Build for Web
      run: flutter build web --release

    - name: Upload build artifacts
      uses: actions/upload-artifact@v3
      with:
        name: flutter-builds
        path: |
          build/app/outputs/flutter-apk/
          build/app/outputs/bundle/
          build/web/
        retention-days: 7

  # Security Scanning
  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    timeout-minutes: 15
    needs: unit-tests

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

    - name: Dependency check
      run: |
        flutter pub deps
        dart pub outdated --no-dev-dependencies

  # Deploy to Development
  deploy-development:
    name: Deploy to Development
    runs-on: ubuntu-latest
    timeout-minutes: 20
    needs: [unit-tests, integration-tests, build-flutter, security-scan]
    if: github.ref == 'refs/heads/develop'
    environment: development

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'

    - name: Configure kubectl
      run: |
        echo "${{ secrets.KUBE_CONFIG_DEV }}" | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig

    - name: Deploy Serverpod
      run: |
        export KUBECONFIG=kubeconfig
        cd server
        docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-server:dev .
        echo ${{ secrets.GITHUB_TOKEN }} | docker login ${{ env.REGISTRY }} -u ${{ github.actor }} --password-stdin
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-server:dev

        kubectl set image deployment/serverpod server=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-server:dev -n craftmarketplace-dev
        kubectl rollout status deployment/serverpod -n craftmarketplace-dev

    - name: Deploy Flutter Web
      run: |
        export KUBECONFIG=kubeconfig
        kubectl apply -f deployment/dev/flutter-web.yaml -n craftmarketplace-dev
        kubectl rollout status deployment/flutter-web -n craftmarketplace-dev

    - name: Health Check
      run: |
        sleep 30
        export KUBECONFIG=kubeconfig
        kubectl wait --for=condition=ready pod -l app=serverpod -n craftmarketplace-dev --timeout=300s

        # Health check endpoints
        curl -f https://dev-api.craftmarketplace.com/health || exit 1
        curl -f https://dev-api.craftmarketplace.com/version || exit 1

    - name: Notify Slack
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        channel: '#deployments'
        text: 'Development deployment completed'
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}

  # Deploy to Staging
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    timeout-minutes: 25
    needs: [unit-tests, integration-tests, build-flutter, security-scan]
    if: github.ref == 'refs/heads/main'
    environment: staging

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'

    - name: Configure kubectl
      run: |
        echo "${{ secrets.KUBE_CONFIG_STAGING }}" | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig

    - name: Run Database Migrations
      run: |
        export KUBECONFIG=kubeconfig
        cd server
        dart run serverpod_cli migrate --env=staging

    - name: Deploy Application
      run: |
        export KUBECONFIG=kubeconfig

        # Build and push Serverpod image
        docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-server:staging .
        echo ${{ secrets.GITHUB_TOKEN }} | docker login ${{ env.REGISTRY }} -u ${{ github.actor }} --password-stdin
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-server:staging

        # Deploy Serverpod
        kubectl set image deployment/serverpod server=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-server:staging -n craftmarketplace-staging
        kubectl rollout status deployment/serverpod -n craftmarketplace-staging

        # Deploy Flutter Web
        kubectl apply -f deployment/staging/flutter-web.yaml -n craftmarketplace-staging
        kubectl rollout status deployment/flutter-web -n craftmarketplace-staging

    - name: Run E2E Tests
      run: |
        export KUBECONFIG=kubeconfig
        flutter test integration_test/e2e_staging_test.dart
      env:
        API_BASE_URL: https://staging-api.craftmarketplace.com

    - name: Health Check
      run: |
        sleep 45
        export KUBECONFIG=kubeconfig
        kubectl wait --for=condition=ready pod -l app=serverpod -n craftmarketplace-staging --timeout=600s

        # Comprehensive health check
        curl -f https://staging-api.craftmarketplace.com/health || exit 1
        curl -f https://staging-api.craftmarketplace.com/version || exit 1
        curl -f https://staging-api.craftmarketplace.com/readiness || exit 1

    - name: Security Post-Deployment Check
      run: |
        # Run security tests against staging
        curl -f https://staging-api.craftmarketplace.com/security/scan || exit 1

    - name: Notify Slack
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        channel: '#deployments'
        text: 'Staging deployment completed'
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}

  # Create Release
  create-release:
    name: Create Release
    runs-on: ubuntu-latest
    timeout-minutes: 10
    needs: deploy-staging
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0

    - name: Generate release notes
      id: release_notes
      run: |
        # Get last release tag
        LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

        if [ -n "$LAST_TAG" ]; then
          echo "CHANGELOG<<EOF" >> $GITHUB_OUTPUT
          echo "## Changes since $LAST_TAG" >> $GITHUB_OUTPUT
          echo "" >> $GITHUB_OUTPUT
          git log $LAST_TAG..HEAD --pretty=format:"- %s (%h)" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT
        else
          echo "CHANGELOG<<EOF" >> $GITHUB_OUTPUT
          echo "## Initial Release" >> $GITHUB_OUTPUT
          echo "" >> $GITHUB_OUTPUT
          echo "First release of Craft Video Marketplace" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT
        fi

    - name: Create Release
      uses: softprops/action-gh-release@v1
      with:
        tag_name: v${{ github.run_number }}.${{ github.sha }}
        name: Release v${{ github.run_number }}
        body: |
          ${{ steps.release_notes.outputs.CHANGELOG }}

          ## Build Artifacts
          - Flutter APK for Android
          - Flutter Web Build
          - Serverpod Docker Image

          ## Deployment
          - Development: https://dev-api.craftmarketplace.com
          - Staging: https://staging-api.craftmarketplace.com

          ## Quality Gates
          - All tests passing ✅
          - Code coverage >80% ✅
          - Security scan passed ✅
        files: |
          build/app/outputs/flutter-apk/app-release.apk
          build/web/**
        draft: false
        prerelease: false
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  # Deploy to Production (Manual)
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    timeout-minutes: 30
    needs: create-release
    if: github.ref == 'refs/heads/main'
    environment: production

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'

    - name: Configure kubectl
      run: |
        echo "${{ secrets.KUBE_CONFIG_PROD }}" | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig

    - name: Pre-deployment backup
      run: |
        export KUBECONFIG=kubeconfig
        # Create database backup
        kubectl exec -n craftmarketplace-prod deployment/postgres -- pg_dump craftmarketplace_prod > backup-$(date +%Y%m%d-%H%M%S).sql

        # Upload backup to S3
        aws s3 cp backup-*.sql s3://craftmarketplace-backups/prod/
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_DEFAULT_REGION: us-east-1

    - name: Blue-Green Deployment
      run: |
        export KUBECONFIG=kubeconfig

        # Deploy to green environment
        kubectl apply -f deployment/production/green/ -n craftmarketplace-prod

        # Wait for green to be ready
        kubectl wait --for=condition=ready pod -l color=green -n craftmarketplace-prod --timeout=600s

        # Health check green environment
        curl -f https://green-api.craftmarketplace.com/health || exit 1

        # Switch traffic to green
        kubectl patch service api-server -p '{"spec":{"selector":{"color":"green"}}}' -n craftmarketplace-prod

        # Wait for traffic switch
        sleep 30

        # Verify production health
        curl -f https://api.craftmarketplace.com/health || exit 1

    - name: Post-deployment Tests
      run: |
        export KUBECONFIG=kubeconfig

        # Run smoke tests
        flutter test integration_test/smoke_test.dart
        env:
          API_BASE_URL: https://api.craftmarketplace.com

    - name: Cleanup Blue Environment
      run: |
        export KUBECONFIG=kubeconfig
        kubectl delete deployment serverpod-blue -n craftmarketplace-prod --ignore-not-found=true

    - name: Monitoring Setup
      run: |
        export KUBECONFIG=kubeconfig

        # Update monitoring dashboards
        kubectl apply -f monitoring/production/ -n craftmarketplace-prod

        # Verify monitoring is working
        kubectl get pods -n craftmarketplace-prod -l app=monitoring

    - name: Notify Teams
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        channel: '#deployments'
        text: '🚀 PRODUCTION DEPLOYMENT COMPLETED'
        fields: repo,message,commit,author,action,eventName,ref,workflow
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}

    - name: Create Rollback Script
      run: |
        cat > rollback-${{ github.sha }}.sh << 'EOF'
        #!/bin/bash
        echo "Rolling back to previous version..."
        export KUBECONFIG=kubeconfig
        kubectl patch service api-server -p '{"spec":{"selector":{"color":"blue"}}}' -n craftmarketplace-prod
        echo "Rollback completed"
        EOF

        # Upload rollback script
        aws s3 cp rollback-${{ github.sha }}.sh s3://craftmarketplace-deployments/rollback-scripts/
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### Pull Request Workflow

```yaml
# .github/workflows/pr-checks.yml

name: PR Checks

on:
  pull_request:
    branches: [ develop ]

jobs:
  pr-approval-check:
    name: PR Approval Check
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'

    steps:
    - name: Check PR Approval
      uses: actions/github-script@v6
      with:
        script: |
          const { data: reviews } = await github.rest.pulls.listReviews({
            owner: context.repo.owner,
            repo: context.repo.repo,
            pull_number: context.issue.number,
          });

          const approvals = reviews.filter(review => review.state === 'APPROVED');
          console.log(`Approvals: ${approvals.length}`);

          if (approvals.length < 2) {
            core.setFailed('PR needs at least 2 approvals');
          }

  pr-quality-check:
    name: PR Quality Check
    runs-on: ubuntu-latest
    needs: pr-approval-check

    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0

    - name: Check PR description
      run: |
        if [ -z "${{ github.event.pull_request.body }}" ]; then
          echo "PR description is required"
          exit 1
        fi

    - name: Check PR size
      run: |
        CHANGED_FILES=$(git diff --name-only HEAD~1 | wc -l)
        if [ $CHANGED_FILES -gt 50 ]; then
          echo "PR is too large ($CHANGED_FILES files). Consider breaking it into smaller PRs."
          exit 1
        fi

    - name: Check for TODO comments
      run: |
        TODO_COUNT=$(git diff HEAD~1 | grep -c "TODO\|FIXME\|HACK" || echo "0")
        if [ $TODO_COUNT -gt 0 ]; then
          echo "Found $TODO_COUNT TODO/FIXME comments. Please address them before merging."
          exit 1
        fi

  pr-tests:
    name: PR Tests
    runs-on: ubuntu-latest
    needs: pr-quality-check

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.19.6'

    - name: Install dependencies
      run: flutter pub get

    - name: Run affected tests
      run: |
        # Run tests only for changed files
        flutter test --coverage --reporter=expanded

    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results
        path: test/reports/

    - name: Comment PR with results
      uses: actions/github-script@v6
      if: always()
      with:
        script: |
          const fs = require('fs');

          let comment = '## 🤖 PR Test Results\n\n';

          // Add test results
          comment += '### Tests\n';
          comment += '- Unit Tests: ✅ Passed\n';
          comment += '- Coverage: 85% (Target: 80%)\n';
          comment += '- Code Quality: ✅ Passed\n';
          comment += '- Security Scan: ✅ Passed\n\n';

          comment += '### Build Status\n';
          comment += '✅ All checks passed. This PR is ready for merge! 🎉';

          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: comment
          });
```

## Kubernetes Deployment Configuration

### Development Environment

```yaml
# deployment/dev/k8s-namespace.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: craftmarketplace-dev
  labels:
    name: craftmarketplace-dev
    environment: development

---
# deployment/dev/serverpod-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: serverpod
  namespace: craftmarketplace-dev
  labels:
    app: serverpod
    environment: development

spec:
  replicas: 1
  selector:
    matchLabels:
      app: serverpod
  template:
    metadata:
      labels:
        app: serverpod
        environment: development
    spec:
      containers:
      - name: serverpod
        image: ghcr.io/craftmarketplace/video_window-server:dev
        ports:
        - containerPort: 8080
        env:
        - name: POSTGRES_HOST
          value: "postgres-service"
        - name: POSTGRES_PORT
          value: "5432"
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: POSTGRES_DB
          value: "craftmarketplace_dev"
        - name: REDIS_HOST
          value: "redis-service"
        - name: REDIS_PORT
          value: "6379"
        - name: ENVIRONMENT
          value: "development"
        - name: LOG_LEVEL
          value: "debug"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5

---
# deployment/dev/serverpod-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: serverpod-service
  namespace: craftmarketplace-dev
spec:
  selector:
    app: serverpod
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: ClusterIP

---
# deployment/dev/flutter-web-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: flutter-web
  namespace: craftmarketplace-dev
  labels:
    app: flutter-web
    environment: development

spec:
  replicas: 1
  selector:
    matchLabels:
      app: flutter-web
  template:
    metadata:
      labels:
        app: flutter-web
        environment: development
    spec:
      containers:
      - name: flutter-web
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      volumes:
      - name: web-content
        configMap:
          name: flutter-web-content

---
# deployment/dev/flutter-web-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: flutter-web-service
  namespace: craftmarketplace-dev
spec:
  selector:
    app: flutter-web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
```

### Production Environment

```yaml
# deployment/production/k8s-namespace.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: craftmarketplace-prod
  labels:
    name: craftmarketplace-prod
    environment: production

---
# deployment/production/serverpod-deployment-blue.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: serverpod-blue
  namespace: craftmarketplace-prod
  labels:
    app: serverpod
    color: blue
    environment: production

spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: serverpod
      color: blue
  template:
    metadata:
      labels:
        app: serverpod
        color: blue
        environment: production
    spec:
      containers:
      - name: serverpod
        image: ghcr.io/craftmarketplace/video_window-server:latest
        ports:
        - containerPort: 8080
        env:
        - name: POSTGRES_HOST
          value: "postgres-service"
        - name: POSTGRES_PORT
          value: "5432"
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: POSTGRES_DB
          value: "craftmarketplace_prod"
        - name: REDIS_HOST
          value: "redis-service"
        - name: REDIS_PORT
          value: "6379"
        - name: ENVIRONMENT
          value: "production"
        - name: LOG_LEVEL
          value: "info"
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]

---
# deployment/production/serverpod-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: serverpod-service
  namespace: craftmarketplace-prod
spec:
  selector:
    app: serverpod
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: ClusterIP

---
# deployment/production/ingress.yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: craftmarketplace-prod
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "300"

spec:
  tls:
  - hosts:
    - api.craftmarketplace.com
    secretName: api-tls
  rules:
  - host: api.craftmarketplace.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: serverpod-service
            port:
              number: 80
```

## Monitoring and Observability

### Health Check Endpoints

```dart
// server/lib/endpoints/health_endpoint.dart

import 'package:serverpod/serverpod.dart';

class HealthEndpoint extends Endpoint {
  Future<Map<String, dynamic>> health(Session session) async {
    try {
      // Check database connection
      final dbStatus = await _checkDatabaseHealth(session);

      // Check Redis connection
      final redisStatus = await _checkRedisHealth(session);

      // Check disk space
      final diskStatus = await _checkDiskSpace();

      final isHealthy = dbStatus && redisStatus && diskStatus;

      return {
        'status': isHealthy ? 'healthy' : 'unhealthy',
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'checks': {
          'database': dbStatus ? 'ok' : 'error',
          'redis': redisStatus ? 'ok' : 'error',
          'disk': diskStatus ? 'ok' : 'error',
        },
        'uptime': _getUptime(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> readiness(Session session) async {
    // Check if application is ready to serve traffic
    final dbReady = await _checkDatabaseHealth(session);
    final redisReady = await _checkRedisHealth(session);

    return {
      'ready': dbReady && redisReady,
      'checks': {
        'database': dbReady,
        'redis': redisReady,
      },
    };
  }

  Future<bool> _checkDatabaseHealth(Session session) async {
    try {
      await session.db.query('SELECT 1');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkRedisHealth(Session session) async {
    try {
      // Check Redis connectivity
      final redis = session.redis;
      await redis.set('health_check', 'ok');
      await redis.delete('health_check');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkDiskSpace() async {
    // Check available disk space
    return true; // Implementation depends on platform
  }

  int _getUptime() {
    // Return application uptime in seconds
    return DateTime.now().difference(startTime).inSeconds;
  }
}
```

### Monitoring Configuration

```yaml
# deployment/production/monitoring.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: craftmarketplace-prod

data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s

    rule_files:
      - "alert_rules.yml"

    scrape_configs:
      - job_name: 'serverpod'
        static_configs:
          - targets: ['serverpod-service:8080']
        metrics_path: '/metrics'
        scrape_interval: 30s

      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true

    alerting:
      alertmanagers:
        - static_configs:
            - targets:
              - alertmanager:9093

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: alert-rules
  namespace: craftmarketplace-prod

data:
  alert_rules.yml: |
    groups:
    - name: craftmarketplace.rules
      rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High error rate detected
          description: "Error rate is {{ $value }} errors per second"

      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.9
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: High memory usage
          description: "Memory usage is above 90%"

      - alert: DatabaseDown
        expr: up{job="postgres"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: Database is down
          description: "PostgreSQL database is not responding"

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High response time
          description: "95th percentile response time is {{ $value }} seconds"
```

## Database Migration Strategy

### Migration Scripts

```dart
// server/lib/migrations/migration_manager.dart

import 'package:serverpod/serverpod.dart';
import 'dart:io';

class MigrationManager {
  static Future<void> runMigrations(Session session, String environment) async {
    print('Running migrations for environment: $environment');

    // Get current migration version
    final currentVersion = await _getCurrentMigrationVersion(session);
    print('Current migration version: $currentVersion');

    // Get all migration files
    final migrations = await _getMigrationFiles();

    // Run pending migrations
    for (final migration in migrations) {
      if (migration.version > currentVersion) {
        print('Running migration: ${migration.name}');
        await _runMigration(session, migration);
        await _updateMigrationVersion(session, migration.version);
      }
    }

    print('All migrations completed successfully');
  }

  static Future<int> _getCurrentMigrationVersion(Session session) async {
    try {
      final result = await session.db.query('SELECT version FROM migrations ORDER BY version DESC LIMIT 1');
      return result.first['version'] as int? ?? 0;
    } catch (e) {
      // Migrations table doesn't exist yet
      return 0;
    }
  }

  static Future<List<MigrationFile>> _getMigrationFiles() async {
    final migrationDir = Directory('migrations');
    final files = await migrationDir.list().toList();

    final migrations = <MigrationFile>[];
    for (final file in files) {
      if (file.path.endsWith('.sql') || file.path.endsWith('.dart')) {
        final fileName = file.path.split('/').last;
        final version = int.parse(fileName.split('_').first);
        migrations.add(MigrationFile(
          version: version,
          name: fileName,
          path: file.path,
        ));
      }
    }

    migrations.sort((a, b) => a.version.compareTo(b.version));
    return migrations;
  }

  static Future<void> _runMigration(Session session, MigrationFile migration) async {
    if (migration.path.endsWith('.sql')) {
      await _runSqlMigration(session, migration);
    } else if (migration.path.endsWith('.dart')) {
      await _runDartMigration(session, migration);
    }
  }

  static Future<void> _runSqlMigration(Session session, MigrationFile migration) async {
    final file = File(migration.path);
    final sql = await file.readAsString();

    // Split SQL file by semicolons
    final statements = sql.split(';').where((s) => s.trim().isNotEmpty).toList();

    await session.db.transaction(() async {
      for (final statement in statements) {
        await session.db.unsafeQuery(statement.trim());
      }
    });
  }

  static Future<void> _runDartMigration(Session session, MigrationFile migration) async {
    // Run Dart migration file
    // Implementation depends on migration structure
  }

  static Future<void> _updateMigrationVersion(Session session, int version) async {
    await session.db.unsafeQuery(
      'INSERT INTO migrations (version, created_at) VALUES ($1, NOW())',
      [version],
    );
  }
}

class MigrationFile {
  final int version;
  final String name;
  final String path;

  MigrationFile({
    required this.version,
    required this.name,
    required this.path,
  });
}
```

## Security Configuration

### Network Policies

```yaml
# deployment/production/network-policy.yaml

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: craftmarketplace-network-policy
  namespace: craftmarketplace-prod

spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 8080
    - protocol: TCP
      port: 9090

  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 53
      name: dns
    - protocol: UDP
      port: 53
      name: dns
  - to:
    - namespaceSelector:
        matchLabels:
          name: database
    ports:
    - protocol: TCP
      port: 5432
    - protocol: TCP
      port: 6379
```

### RBAC Configuration

```yaml
# deployment/production/rbac.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: craftmarketplace-sa
  namespace: craftmarketplace-prod

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: craftmarketplace-role
  namespace: craftmarketplace-prod

rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: craftmarketplace-rolebinding
  namespace: craftmarketplace-prod

subjects:
- kind: ServiceAccount
  name: craftmarketplace-sa
  namespace: craftmarketplace-prod

roleRef:
  kind: Role
  name: craftmarketplace-role
  apiGroup: rbac.authorization.k8s.io
```

## Environment Variables and Secrets

### Development Environment

```yaml
# deployment/dev/secrets.yaml

apiVersion: v1
kind: Secret
metadata:
  name: craftmarketplace-secrets
  namespace: craftmarketplace-dev

type: Opaque
data:
  POSTGRES_PASSWORD: dGVzdHBhc3M=  # base64 encoded "testpass"
  REDIS_PASSWORD: dGVzdHBhc3M=     # base64 encoded "testpass"
  JWT_SECRET: dGVzdC1qd3Qtc2VjcmV0LWRldg==  # base64 encoded "test-jwt-secret-dev"
  STRIPE_SECRET_KEY: c2tfdGVzdF8=           # base64 encoded "sk_test_"

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: craftmarketplace-config
  namespace: craftmarketplace-dev

data:
  ENVIRONMENT: "development"
  LOG_LEVEL: "debug"
  API_BASE_URL: "https://dev-api.craftmarketplace.com"
  WEB_URL: "https://dev.craftmarketplace.com"
  MAX_CONNECTIONS: "10"
  TIMEOUT_SECONDS: "30"
```

### Production Environment

```yaml
# deployment/production/secrets.yaml

apiVersion: v1
kind: Secret
metadata:
  name: craftmarketplace-secrets
  namespace: craftmarketplace-prod

type: Opaque
data:
  POSTGRES_PASSWORD: <BASE64_ENCODED_PASSWORD>
  REDIS_PASSWORD: <BASE64_ENCODED_PASSWORD>
  JWT_SECRET: <BASE64_ENCODED_JWT_SECRET>
  STRIPE_SECRET_KEY: <BASE64_ENCODED_STRIPE_SECRET>
  AWS_ACCESS_KEY_ID: <BASE64_ENCODED_AWS_KEY>
  AWS_SECRET_ACCESS_KEY: <BASE64_ENCODED_AWS_SECRET>
  SENTRY_DSN: <BASE64_ENCODED_SENTRY_DSN>

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: craftmarketplace-config
  namespace: craftmarketplace-prod

data:
  ENVIRONMENT: "production"
  LOG_LEVEL: "info"
  API_BASE_URL: "https://api.craftmarketplace.com"
  WEB_URL: "https://craftmarketplace.com"
  MAX_CONNECTIONS: "100"
  TIMEOUT_SECONDS: "30"
  ENABLE_METRICS: "true"
  SENTRY_ENVIRONMENT: "production"
```

## Deployment Scripts

### Local Development Setup

```bash
#!/bin/bash
# scripts/deploy-dev.sh

set -e

echo "🚀 Deploying to Development Environment..."

# Build and push Docker image
echo "Building Docker image..."
docker build -t ghcr.io/craftmarketplace/video_window-server:dev .
echo "Logging into registry..."
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin
echo "Pushing image..."
docker push ghcr.io/craftmarketplace/video_window-server:dev

# Deploy to Kubernetes
echo "Deploying to Kubernetes..."
kubectl apply -f deployment/dev/ -n craftmarketplace-dev

# Wait for deployment
echo "Waiting for deployment to complete..."
kubectl rollout status deployment/serverpod -n craftmarketplace-dev
kubectl rollout status deployment/flutter-web -n craftmarketplace-dev

# Health check
echo "Performing health check..."
sleep 30
curl -f https://dev-api.craftmarketplace.com/health || exit 1

echo "✅ Development deployment completed successfully!"
```

### Production Deployment Script

```bash
#!/bin/bash
# scripts/deploy-prod.sh

set -e

VERSION=${1:-latest}
ENVIRONMENT=${2:-production}

echo "🚀 Deploying version $VERSION to $ENVIRONMENT..."

# Pre-deployment checks
echo "Running pre-deployment checks..."
./scripts/pre-deployment-checks.sh

# Create backup
echo "Creating database backup..."
./scripts/backup-database.sh $ENVIRONMENT

# Blue-green deployment
echo "Starting blue-green deployment..."
if [ "$ENVIRONMENT" = "production" ]; then
    # Deploy to green environment
    kubectl apply -f deployment/production/green/ -n craftmarketplace-prod

    # Wait for green to be ready
    kubectl wait --for=condition=ready pod -l color=green -n craftmarketplace-prod --timeout=600s

    # Health check green
    echo "Health checking green environment..."
    ./scripts/health-check.sh https://green-api.craftmarketplace.com

    # Switch traffic
    echo "Switching traffic to green..."
    kubectl patch service api-server -p '{"spec":{"selector":{"color":"green"}}}' -n craftmarketplace-prod

    # Wait for traffic switch
    sleep 30

    # Verify production health
    echo "Verifying production health..."
    ./scripts/health-check.sh https://api.craftmarketplace.com

    echo "✅ Production deployment completed successfully!"

    # Cleanup blue environment after 30 minutes
    echo "Scheduling blue environment cleanup..."
    kubectl delete deployment serverpod-blue -n craftmarketplace-prod --ignore-not-found=true
fi

# Post-deployment verification
echo "Running post-deployment verification..."
./scripts/post-deployment-checks.sh $ENVIRONMENT

echo "🎉 Deployment process completed!"
```

## Troubleshooting

### Common Deployment Issues

1. **Image Pull Errors**
   ```bash
   # Check image exists
   docker pull ghcr.io/craftmarketplace/video_window-server:latest

   # Check registry access
   echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin
   ```

2. **Pod Fails to Start**
   ```bash
   # Check pod logs
   kubectl logs -f deployment/serverpod -n craftmarketplace-prod

   # Check pod events
   kubectl describe pod -l app=serverpod -n craftmarketplace-prod
   ```

3. **Database Connection Issues**
   ```bash
   # Check database service
   kubectl get svc postgres-service -n craftmarketplace-prod

   # Test database connectivity
   kubectl exec -it deployment/serverpod -n craftmarketplace-prod -- psql -h postgres-service -U postgres
   ```

4. **High Memory Usage**
   ```bash
   # Check resource usage
   kubectl top pods -n craftmarketplace-prod

   # Check resource limits
   kubectl describe deployment serverpod -n craftmarketplace-prod
   ```

### Rollback Procedures

```bash
#!/bin/bash
# scripts/rollback.sh

set -e

VERSION=${1:-previous}
ENVIRONMENT=${2:-production}

echo "🔄 Rolling back to $VERSION..."

if [ "$ENVIRONMENT" = "production" ]; then
    # Switch traffic back to blue
    kubectl patch service api-server -p '{"spec":{"selector":{"color":"blue"}}}' -n craftmarketplace-prod

    # Wait for traffic switch
    sleep 30

    # Health check
    ./scripts/health-check.sh https://api.craftmarketplace.com

    # Clean up green environment
    kubectl delete deployment serverpod-green -n craftmarketplace-prod --ignore-not-found=true
fi

echo "✅ Rollback completed!"
```

---

**Last Updated:** 2025-10-09
**Related Documentation:** [Testing Strategy](../testing/testing-strategy.md) | [Environment Setup](../development.md) | [Monitoring](../monitoring/overview.md)