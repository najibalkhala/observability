# Grafana Observability Stack

A comprehensive observability solution using the Grafana LGTM stack (Loki, Grafana, Tempo, Mimir) with OpenTelemetry Collector, Prometheus, and monitoring exporters.

## 🚀 Stack Components

### Core Observability (LGTM)
- **Grafana** - Visualization and dashboarding platform
- **Loki** - Log aggregation system
- **Tempo** - Distributed tracing backend
- **Mimir** - Long-term metrics storage

### Data Collection & Processing
- **OpenTelemetry Collector** - Vendor-agnostic telemetry collection
- **Prometheus** - Metrics collection and short-term storage
- **Promtail** - Log collector and shipper to Loki
- **Alertmanager** - Alert routing and management

### Exporters & Monitoring
- **Node Exporter** - Hardware and OS metrics
- **cAdvisor** - Container and resource usage metrics

## 📊 Architecture

```
                                    ┌─────────────┐
                                    │   Grafana   │
                                    │   :3000     │
                                    └──────┬──────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
            ┌───────▼────────┐    ┌───────▼────────┐    ┌───────▼────────┐
            │     Mimir      │    │      Loki      │    │     Tempo      │
            │  (Metrics)     │    │     (Logs)     │    │    (Traces)    │
            │     :8080      │    │     :3100      │    │     :3200      │
            └───────▲────────┘    └───────▲────────┘    └───────▲────────┘
                    │                     │                      │
        ┌───────────┴───────────┐         │                      │
        │                       │         │                      │
┌───────▼────────┐    ┌────────▼─────────▼──────────────────────▼────────┐
│   Prometheus   │    │          OpenTelemetry Collector                 │
│     :9090      │    │      :4317 (gRPC)  :4318 (HTTP)                 │
└───────▲────────┘    └──────────────────────────────────────────────────┘
        │                                  ▲
        │                                  │
┌───────┴────────┬──────────────┬─────────┴──────┐
│                │              │                 │
│  Node Exporter │   cAdvisor   │    Promtail    │  Your Applications
│     :9100      │    :8081     │                │  (OTLP instrumented)
└────────────────┴──────────────┴────────────────┘
```

## 🔧 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- At least 4GB of available RAM
- Ports 3000, 3100, 3200, 4317, 4318, 8080, 8081, 9090, 9093, 9100 available

### Start the Stack

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f

# Stop the stack
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v
```

## 🌐 Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin / StrongPass123 |
| Prometheus | http://localhost:9090 | - |
| Alertmanager | http://localhost:9093 | - |
| Mimir | http://localhost:8080 | - |
| Loki | http://localhost:3100 | - |
| Tempo | http://localhost:3200 | - |
| Node Exporter | http://localhost:9100/metrics | - |
| cAdvisor | http://localhost:8081 | - |
| OTLP gRPC | localhost:4317 | - |
| OTLP HTTP | http://localhost:4318 | - |

## 📈 Features

### Automatic Data Source Configuration
All data sources are automatically configured in Grafana:
- ✅ Prometheus (short-term metrics)
- ✅ Mimir (long-term metrics, set as default)
- ✅ Loki (logs)
- ✅ Tempo (traces)
- ✅ Alertmanager (alerts)

### Trace-to-Logs Correlation
Traces in Tempo are automatically correlated with logs in Loki via trace IDs.

### Metrics-to-Traces Correlation
Metrics in Mimir can be correlated with traces in Tempo.

### Service Graph & Node Graph
Tempo provides automatic service dependency graphs from trace data.

### Health Checks
All services include health checks for reliable startup ordering and monitoring.

### Container Monitoring
- Node Exporter: System-level metrics (CPU, memory, disk, network)
- cAdvisor: Container-level metrics (per-container resource usage)

## 🔍 Monitoring Your Applications

### Option 1: OpenTelemetry (Recommended)

Send telemetry data to the OpenTelemetry Collector:

**gRPC Endpoint:** `localhost:4317`  
**HTTP Endpoint:** `http://localhost:4318`

#### Example: Python Application

```python
from opentelemetry import trace, metrics
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader

# Traces
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)
span_processor = BatchSpanProcessor(OTLPSpanExporter(endpoint="localhost:4317", insecure=True))
trace.get_tracer_provider().add_span_processor(span_processor)

# Metrics
metric_reader = PeriodicExportingMetricReader(
    OTLPMetricExporter(endpoint="localhost:4317", insecure=True)
)
metrics.set_meter_provider(MeterProvider(metric_readers=[metric_reader]))
meter = metrics.get_meter(__name__)
```

#### Example: Node.js Application

```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-grpc');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'localhost:4317',
  }),
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({
      url: 'localhost:4317',
    }),
  }),
});

sdk.start();
```

### Option 2: Direct Integration

#### Logs → Loki
Use Promtail or send logs directly to Loki:

```bash
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [
      {
        "stream": { "app": "myapp", "level": "info" },
        "values": [
          ["'$(date +%s)000000000'", "This is a log message"]
        ]
      }
    ]
  }'
```

#### Metrics → Mimir
Use Prometheus client libraries and configure remote_write to Mimir:

```yaml
remote_write:
  - url: "http://localhost:8080/api/v1/push"
```

## 🔔 Alerting

### Configure Alertmanager

Edit `alertmanager/config.yml` to add notification channels:

```yaml
receivers:
  - name: 'critical'
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK'
        channel: '#alerts'
    email_configs:
      - to: 'alerts@example.com'
```

### Add Prometheus Alert Rules

Create `prometheus/alerts/rules.yml`:

```yaml
groups:
  - name: example
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
```

## 📚 Sample Queries

### Loki (LogQL)
```logql
# All logs from Laravel application
{job="laravel"}

# Error logs only
{job="laravel"} |= "error" | json

# Logs with trace correlation
{job="laravel"} | json | trace_id != ""
```

### Tempo (TraceQL)
```traceql
# Find slow traces
{ duration > 1s }

# Traces with errors
{ status = error }

# Traces from specific service
{ resource.service.name = "api-service" }
```

### Prometheus (PromQL)
```promql
# CPU usage by container
rate(container_cpu_usage_seconds_total[5m])

# Memory usage
container_memory_usage_bytes

# Request rate
rate(http_requests_total[5m])
```

## 🛠 Customization

### Add Custom Dashboards

1. Create dashboard JSON files in `grafana/dashboards/`
2. Restart Grafana: `docker-compose restart grafana`

### Modify Retention

**Prometheus:**
```yaml
command:
  - '--storage.tsdb.retention.time=30d'
```

**Loki:**
Edit `loki/loki-config.yaml`:
```yaml
limits_config:
  retention_period: 744h  # 31 days
```

**Tempo:**
Edit `tempo/tempo.yaml`:
```yaml
compactor:
  compaction:
    block_retention: 168h  # 7 days
```

## 🔒 Security Recommendations

For production use:
1. Change default Grafana password
2. Enable authentication for all services
3. Use TLS/SSL certificates
4. Implement network policies
5. Use secrets management
6. Enable audit logging
7. Regular backups of persistent volumes

## 📦 Data Persistence

The following volumes persist data:
- `grafana-data` - Grafana dashboards and settings
- `prometheus-data` - Prometheus short-term metrics
- `mimir-data` - Mimir long-term metrics
- `loki-data` - Loki log data
- `tempo-data` - Tempo trace data
- `alertmanager-data` - Alertmanager state

## 🐛 Troubleshooting

### Services not starting
```bash
# Check logs
docker-compose logs <service-name>

# Check health status
docker-compose ps
```

### Out of memory
Increase Docker memory allocation or reduce retention periods.

### Port conflicts
Modify port mappings in `docker-compose.yml`.

### Data sources not appearing in Grafana
```bash
# Check provisioning
docker-compose exec grafana ls -la /etc/grafana/provisioning/datasources/

# Restart Grafana
docker-compose restart grafana
```

## 📝 Additional Resources

- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [Tempo Documentation](https://grafana.com/docs/tempo/)
- [Mimir Documentation](https://grafana.com/docs/mimir/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This configuration is provided as-is for use in your observability infrastructure.

