# Architecture Documentation

## Overview

This observability stack provides complete monitoring, logging, and tracing capabilities using the Grafana LGTM stack with OpenTelemetry integration.

## Components

### Data Collection Layer

#### OpenTelemetry Collector
- **Purpose**: Universal telemetry data receiver and processor
- **Port**: 4317 (gRPC), 4318 (HTTP)
- **Receives**: Traces, Metrics, Logs via OTLP protocol
- **Exports to**: Tempo (traces), Mimir (metrics), Loki (logs)
- **Features**:
  - Batch processing
  - Memory limiting
  - Attribute enrichment
  - Health checking

#### Promtail
- **Purpose**: Log collection and shipping
- **Collects from**:
  - Application log files (Laravel)
  - Docker container logs
- **Exports to**: Loki
- **Features**:
  - Log parsing and labeling
  - Pipeline processing
  - Multi-target collection

#### Node Exporter
- **Purpose**: System-level metrics
- **Port**: 9100
- **Metrics**: CPU, Memory, Disk, Network, System stats
- **Scraped by**: Prometheus

#### cAdvisor
- **Purpose**: Container-level metrics
- **Port**: 8081
- **Metrics**: Container CPU, Memory, Network, Disk I/O
- **Scraped by**: Prometheus

### Storage Layer

#### Grafana Mimir
- **Purpose**: Long-term metrics storage (TSDB)
- **Port**: 8080
- **API**: Prometheus-compatible
- **Receives from**:
  - Prometheus (remote_write)
  - OpenTelemetry Collector
- **Storage**: Filesystem-backed (configurable for S3/GCS)
- **Features**:
  - Multi-tenancy support
  - Horizontal scalability
  - Query federation
  - Long-term retention

#### Grafana Loki
- **Purpose**: Log aggregation and storage
- **Port**: 3100
- **Query Language**: LogQL
- **Receives from**:
  - Promtail
  - OpenTelemetry Collector
  - Direct HTTP API
- **Storage**: BoltDB + Filesystem
- **Features**:
  - Label-based indexing
  - Cost-effective storage
  - LogQL queries
  - Trace correlation

#### Grafana Tempo
- **Purpose**: Distributed tracing backend
- **Port**: 3200
- **Query Language**: TraceQL
- **Receives**: OTLP traces via OpenTelemetry Collector
- **Storage**: Local filesystem
- **Features**:
  - TraceQL search
  - Service graphs
  - Trace-to-logs correlation
  - Trace-to-metrics correlation

#### Prometheus
- **Purpose**: Short-term metrics storage and scraping
- **Port**: 9090
- **Query Language**: PromQL
- **Scrapes**:
  - Node Exporter
  - cAdvisor
  - All observability services (self-monitoring)
- **Exports to**: Mimir (remote_write)
- **Retention**: 15 days (configurable)

### Alert Management

#### Alertmanager
- **Purpose**: Alert routing and notification
- **Port**: 9093
- **Receives from**: Prometheus
- **Supports**:
  - Slack notifications
  - Email notifications
  - Webhook notifications
  - PagerDuty integration
  - Alert grouping and deduplication
  - Silencing and inhibition

### Visualization Layer

#### Grafana
- **Purpose**: Unified observability UI
- **Port**: 3000
- **Data Sources** (auto-configured):
  - Mimir (metrics)
  - Prometheus (metrics)
  - Loki (logs)
  - Tempo (traces)
  - Alertmanager (alerts)
- **Features**:
  - Dashboard creation
  - Explore interface
  - Alerting
  - Trace-to-logs correlation
  - Metrics-to-traces correlation
  - Service graphs

## Data Flow

### Metrics Flow

```
Application Metrics
        ↓
  OTLP Protocol
        ↓
OpenTelemetry Collector ─────→ Mimir (Long-term)
                                  ↑
System/Container Metrics          │
        ↓                         │
  Node Exporter / cAdvisor        │
        ↓                         │
    Prometheus ──────────────────┘
        ↓                        (remote_write)
      Grafana
```

### Logs Flow

```
Application Logs          Docker Container Logs
        ↓                         ↓
    Promtail ────────────────────┘
        ↓
      Loki ←──── OpenTelemetry Collector
        ↓                (OTLP logs)
      Grafana
```

### Traces Flow

```
Application Spans
        ↓
  OTLP Protocol
        ↓
OpenTelemetry Collector
        ↓
      Tempo
        ↓
      Grafana
```

## Network Architecture

All services run in a shared Docker network called `observability`:

```
┌─────────────────────────────────────────────────────────────┐
│                   observability network                      │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Grafana │  │Prometheus│  │   Loki   │  │  Tempo   │   │
│  │  :3000   │  │  :9090   │  │  :3100   │  │  :3200   │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │             │              │             │          │
│  ┌────┴─────────────┴──────────────┴─────────────┴──────┐  │
│  │                    Mimir :8080                        │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────┐  ┌────────────┐  ┌──────────────┐   │
│  │ OTel Collector    │  │  Promtail  │  │ Alertmanager │   │
│  │ :4317/:4318       │  │            │  │   :9093      │   │
│  └───────────────────┘  └────────────┘  └──────────────┘   │
│                                                              │
│  ┌───────────────────┐  ┌────────────┐                      │
│  │  Node Exporter    │  │  cAdvisor  │                      │
│  │     :9100         │  │   :8081    │                      │
│  └───────────────────┘  └────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

## Service Dependencies

Services start in the following order (enforced by health checks):

1. **Core Storage Services** (parallel):
   - Mimir
   - Loki
   - Tempo

2. **Collection Services** (after storage is healthy):
   - Prometheus
   - Promtail
   - OpenTelemetry Collector

3. **Visualization** (after all data sources are ready):
   - Grafana

4. **Exporters** (no dependencies):
   - Node Exporter
   - cAdvisor

5. **Alert Management** (independent):
   - Alertmanager

## Storage Architecture

### Volume Mapping

| Volume | Service | Purpose | Size Considerations |
|--------|---------|---------|-------------------|
| `mimir-data` | Mimir | Metrics storage | Grows with metric volume |
| `loki-data` | Loki | Log storage | Grows with log volume |
| `tempo-data` | Tempo | Trace storage | Grows with trace volume |
| `prometheus-data` | Prometheus | Short-term metrics | Limited by retention (15d) |
| `grafana-data` | Grafana | Dashboards, users, settings | Small, mostly static |
| `alertmanager-data` | Alertmanager | Alert state | Very small |

### Retention Policies

| Service | Default Retention | Configurable |
|---------|------------------|--------------|
| Prometheus | 15 days | Yes (via command args) |
| Mimir | Unlimited | Yes (via config) |
| Loki | Unlimited | Yes (via config) |
| Tempo | 24 hours | Yes (via config) |

## Security Architecture

### Current State (Development)
- No TLS/SSL encryption
- Basic authentication on Grafana only
- Services accessible on localhost
- Insecure OTLP connections

### Production Recommendations

1. **Enable TLS**:
   - Add reverse proxy (nginx/traefik)
   - Use Let's Encrypt certificates
   - Configure service-to-service TLS

2. **Authentication**:
   - Enable authentication on all services
   - Use OAuth/LDAP for Grafana
   - Implement API key authentication for data ingestion

3. **Network Security**:
   - Use Docker network policies
   - Expose only necessary ports
   - Implement firewall rules

4. **Secrets Management**:
   - Use Docker secrets or external vaults
   - Rotate credentials regularly
   - Never commit credentials to git

## Scalability

### Current Architecture
- Single-node deployment
- Suitable for small to medium workloads
- Limited by single host resources

### Scaling Options

#### Horizontal Scaling (Kubernetes)
- Deploy each component as StatefulSet/Deployment
- Use external storage (S3, GCS)
- Implement load balancing
- Scale OTel Collectors independently

#### Vertical Scaling
- Increase Docker resource limits
- Optimize retention periods
- Tune batch sizes and buffer limits

#### Storage Scaling
- Move to object storage (S3/GCS/Azure Blob)
- Implement data lifecycle policies
- Use compression and deduplication

## Monitoring the Monitor

The stack monitors itself:

- Prometheus scrapes all observability services
- Grafana dashboards for stack health
- Alertmanager alerts for service failures
- OTel Collector exposes its own metrics

## Integration Points

### Application Integration

1. **OpenTelemetry** (Recommended):
   - gRPC: `localhost:4317`
   - HTTP: `http://localhost:4318`

2. **Direct Integration**:
   - Loki HTTP API: `http://localhost:3100/loki/api/v1/push`
   - Mimir Remote Write: `http://localhost:8080/api/v1/push`
   - Tempo OTLP: `http://localhost:3200`

### External Systems

- **CI/CD**: Send build metrics to Mimir
- **Load Balancers**: Forward access logs to Loki
- **Cloud Services**: Integrate cloud monitoring
- **Third-party Services**: Use webhook exporters

## Performance Considerations

### Resource Requirements

**Minimum**:
- 4 CPU cores
- 8GB RAM
- 50GB disk

**Recommended**:
- 8 CPU cores
- 16GB RAM
- 200GB SSD

### Tuning Parameters

1. **OpenTelemetry Collector**:
   - Batch size: 1024
   - Memory limit: 512MB
   - Queue size: 5000

2. **Prometheus**:
   - Scrape interval: 15s
   - Retention: 15d
   - Memory: ~2GB per million samples

3. **Loki**:
   - Ingestion rate: 10MB/s
   - Chunk size: 1MB
   - Cache: 100MB

## Backup and Recovery

### Backup Strategy

1. **Regular Backups** (use `make backup`):
   - Grafana dashboards and config
   - Prometheus data
   - Mimir data
   - Loki indexes

2. **Configuration as Code**:
   - All configs in git
   - Dashboard JSON exports
   - Data source provisioning

### Recovery Procedures

1. **Service Failure**:
   ```bash
   docker-compose restart <service>
   ```

2. **Data Corruption**:
   - Stop service
   - Restore from backup
   - Restart service

3. **Complete Failure**:
   ```bash
   docker-compose down
   # Restore volumes from backup
   docker-compose up -d
   ```

## Troubleshooting Guide

### High Memory Usage
- Reduce retention periods
- Decrease batch sizes
- Limit scrape frequency

### High Disk Usage
- Clean old data
- Reduce retention
- Enable compression

### Slow Queries
- Optimize label cardinality
- Use recording rules
- Add query caching

### Missing Data
- Check service health
- Verify network connectivity
- Review exporter configs
- Check OTLP endpoints

## Future Enhancements

1. **Kubernetes Deployment**: Helm charts for K8s
2. **High Availability**: Multi-replica deployments
3. **Geo-distribution**: Multi-region setup
4. **Advanced Alerting**: ML-based anomaly detection
5. **Cost Optimization**: Sampling and data reduction
6. **Compliance**: Audit logging and data governance

