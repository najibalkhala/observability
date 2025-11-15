# Services Reference Card

Quick reference for all services in the observability stack.

---

## 🌐 Service URLs

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| **Grafana** | http://localhost:3000 | admin / StrongPass123 |
| **Prometheus** | http://localhost:9090 | None |
| **Loki** | http://localhost:3100 | None |
| **Tempo** | http://localhost:3200 | None |
| **Mimir** | http://localhost:8080 | None |
| **Alertmanager** | http://localhost:9093 | None |
| **Node Exporter** | http://localhost:9100/metrics | None |
| **cAdvisor** | http://localhost:8081 | None |

---

## 📡 Telemetry Ingestion Endpoints

| Protocol | Endpoint | Purpose |
|----------|----------|---------|
| **OTLP gRPC** | `localhost:4317` | Send traces, metrics, logs |
| **OTLP HTTP** | `http://localhost:4318` | Send traces, metrics, logs |
| **Loki Push** | `http://localhost:3100/loki/api/v1/push` | Send logs directly |
| **Mimir Remote Write** | `http://localhost:8080/api/v1/push` | Send metrics (Prometheus format) |
| **Tempo** | `http://localhost:3200` | Query traces |

---

## 🔍 Health Check Endpoints

| Service | Health Check URL |
|---------|------------------|
| **Grafana** | http://localhost:3000/api/health |
| **Prometheus** | http://localhost:9090/-/healthy |
| **Loki** | http://localhost:3100/ready |
| **Tempo** | http://localhost:3200/ready |
| **Mimir** | http://localhost:8080/ready |
| **Alertmanager** | http://localhost:9093/-/healthy |
| **OTel Collector** | http://localhost:13133/ |

---

## 📊 Service Details

### Grafana
**Purpose**: Visualization and dashboarding  
**Port**: 3000  
**Container**: `grafana`  
**Data**: `/var/lib/grafana` → `grafana-data` volume  
**Config**: Auto-provisioned from `grafana/provisioning/`  
**Dashboards**: `grafana/dashboards/`  

**Key Features**:
- Auto-configured data sources
- Pre-loaded dashboards
- Unified alerting
- TraceQL and LogQL support
- Trace-to-logs correlation

---

### Prometheus
**Purpose**: Metrics collection and short-term storage  
**Port**: 9090  
**Container**: `prometheus`  
**Data**: `/prometheus` → `prometheus-data` volume  
**Config**: `prometheus/prometheus.yml`  
**Retention**: 15 days  

**Scraping Targets**:
- Self-monitoring (localhost:9090)
- Node Exporter (nodeexporter:9100)
- cAdvisor (cadvisor:8080)
- Mimir (mimir:8080)
- Loki (loki:3100)
- Tempo (tempo:3200)
- OTel Collector (otel-collector:8888)
- Grafana (grafana:3000)

**Remote Write**: Mimir (http://mimir:8080/api/v1/push)

---

### Loki
**Purpose**: Log aggregation system  
**Port**: 3100  
**Container**: `loki`  
**Data**: `/loki` → `loki-data` volume  
**Config**: `loki/loki-config.yaml`  
**Query Language**: LogQL  

**Receives From**:
- Promtail
- OpenTelemetry Collector
- Direct HTTP API

**Storage**:
- Index: BoltDB Shipper
- Chunks: Filesystem

---

### Tempo
**Purpose**: Distributed tracing backend  
**Port**: 3200  
**Container**: `tempo`  
**Data**: `/var/tempo` → `tempo-data` volume  
**Config**: `tempo/tempo.yaml`  
**Query Language**: TraceQL  

**Receives**:
- OTLP traces (via OTel Collector)

**Features**:
- Service graphs
- Trace-to-logs correlation
- TraceQL search

---

### Mimir
**Purpose**: Long-term metrics storage  
**Port**: 8080  
**Container**: `mimir`  
**Data**: `/data/mimir` → `mimir-data` volume  
**Config**: `mimir/mimir.yaml`  
**API**: Prometheus-compatible  

**Receives From**:
- Prometheus (remote_write)
- OpenTelemetry Collector

**Storage**: Filesystem (configurable for S3/GCS)

---

### OpenTelemetry Collector
**Purpose**: Universal telemetry collector and processor  
**Container**: `otel-collector`  
**Config**: `collector/config.yaml`  

**Ports**:
- 4317: OTLP gRPC receiver
- 4318: OTLP HTTP receiver
- 8888: Internal metrics
- 8889: Prometheus exporter
- 13133: Health check
- 1777: pprof profiling (optional)
- 55679: zpages debugging (optional)

**Receives**: Traces, Metrics, Logs (OTLP protocol)  
**Exports To**:
- Tempo (traces)
- Mimir (metrics)
- Loki (logs)

**Features**:
- Batch processing
- Memory limiting (512MB)
- Attribute enrichment
- Health checks

---

### Promtail
**Purpose**: Log collector and shipper  
**Container**: `promtail`  
**Config**: `promtail/config.yml`  

**Collects From**:
- `/var/www/calmo-alkes-stg/storage/logs` (Laravel logs)
- `/var/lib/docker/containers` (Docker logs)

**Exports To**: Loki (http://loki:3100/loki/api/v1/push)

---

### Node Exporter
**Purpose**: System-level metrics exporter  
**Port**: 9100  
**Container**: `node-exporter`  

**Metrics**:
- CPU usage
- Memory usage
- Disk I/O
- Network traffic
- Filesystem usage
- System load

**Scraped By**: Prometheus

---

### cAdvisor
**Purpose**: Container metrics exporter  
**Port**: 8081  
**Container**: `cadvisor`  

**Metrics**:
- Container CPU usage
- Container memory usage
- Container network I/O
- Container disk I/O
- Container filesystem usage

**Scraped By**: Prometheus

---

### Alertmanager
**Purpose**: Alert routing and notification  
**Port**: 9093  
**Container**: `alertmanager`  
**Data**: `/alertmanager` → `alertmanager-data` volume  
**Config**: `alertmanager/config.yml`  

**Receives From**: Prometheus  
**Sends To**: Configurable (Slack, Email, Webhook, etc.)

**Features**:
- Alert grouping
- Deduplication
- Silencing
- Inhibition rules

---

## 🗄️ Data Volumes

| Volume | Service | Path | Purpose | Growth |
|--------|---------|------|---------|--------|
| `grafana-data` | Grafana | `/var/lib/grafana` | Dashboards, settings | Low |
| `prometheus-data` | Prometheus | `/prometheus` | Short-term metrics | Medium |
| `mimir-data` | Mimir | `/data/mimir` | Long-term metrics | High |
| `loki-data` | Loki | `/loki` | Log indexes & chunks | High |
| `tempo-data` | Tempo | `/var/tempo` | Traces | High |
| `alertmanager-data` | Alertmanager | `/alertmanager` | Alert state | Low |

---

## 🔗 Service Dependencies

```
Grafana
  ├─ depends on → Prometheus (healthy)
  ├─ depends on → Loki (healthy)
  ├─ depends on → Tempo (healthy)
  └─ depends on → Mimir (healthy)

OpenTelemetry Collector
  ├─ depends on → Mimir (healthy)
  ├─ depends on → Loki (healthy)
  └─ depends on → Tempo (started)

Prometheus
  └─ depends on → Mimir (healthy)

Promtail
  └─ depends on → Loki (healthy)

Node Exporter, cAdvisor, Alertmanager
  └─ No dependencies (independent)
```

---

## 🏷️ Docker Labels & Networks

**Network**: `observability` (bridge driver)

All services are on the same network and can communicate using service names.

---

## 🔧 Management Commands

### Docker Compose
```bash
docker-compose up -d              # Start all services
docker-compose down               # Stop all services
docker-compose ps                 # Service status
docker-compose logs -f <service>  # View logs
docker-compose restart <service>  # Restart service
docker-compose exec <service> sh  # Shell access
```

### Makefile
```bash
make up          # Start stack
make down        # Stop stack
make logs        # View logs
make health      # Check health
make ps          # Service status
make restart     # Restart all
make clean       # Remove everything
make backup      # Backup volumes
```

### Scripts
```bash
./start.sh             # Automated startup
./test-telemetry.sh    # Test the stack
```

---

## 📝 Configuration Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Main service definitions |
| `collector/config.yaml` | OTel Collector configuration |
| `prometheus/prometheus.yml` | Prometheus scrape configs |
| `loki/loki-config.yaml` | Loki storage and limits |
| `tempo/tempo.yaml` | Tempo storage and receivers |
| `mimir/mimir.yaml` | Mimir storage configuration |
| `promtail/config.yml` | Log collection targets |
| `alertmanager/config.yml` | Alert routing rules |
| `grafana/provisioning/datasources/` | Auto-configured data sources |
| `grafana/provisioning/dashboards/` | Dashboard provisioning |
| `grafana/dashboards/` | Dashboard JSON files |
| `prometheus/alerts/` | Alert rule examples |

---

## 🚀 Quick Actions

### Start Everything
```bash
./start.sh
```

### Check All Services
```bash
make health
```

### View All Logs
```bash
make logs
```

### Access Grafana
```bash
open http://localhost:3000
# Login: admin / StrongPass123
```

### Test Data Ingestion
```bash
./test-telemetry.sh
```

### Backup All Data
```bash
make backup
```

---

## 📚 Documentation Map

- **README.md** - Complete guide
- **QUICKSTART.md** - 5-minute setup
- **ARCHITECTURE.md** - Technical details
- **SERVICES.md** - This file
- **CHANGELOG.md** - What changed
- **SUMMARY.md** - Overview

---

## 🔍 Troubleshooting Quick Reference

### Service Won't Start
```bash
docker-compose logs <service>
docker-compose ps
```

### Check Health
```bash
curl http://localhost:<port>/ready
# or
make health
```

### Restart Service
```bash
docker-compose restart <service>
```

### Check Connectivity
```bash
docker-compose exec <service> ping <other-service>
```

### View Resource Usage
```bash
make stats
# or
docker stats
```

---

## 💡 Tips

1. **Service Names**: Use container names in docker commands
2. **Network Communication**: Services use service names (e.g., `http://loki:3100`)
3. **Health Checks**: Services wait for dependencies to be healthy before starting
4. **Data Persistence**: All important data is in named volumes
5. **Logs**: Use `make logs-<service>` to view specific service logs

---

**Last Updated**: November 15, 2025  
**Stack Version**: Enhanced Full Stack v1.0

