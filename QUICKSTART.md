# Quick Start Guide

Get your full observability stack running in 5 minutes!

## Prerequisites

- Docker Desktop installed and running
- At least 4GB of free RAM
- Ports 3000, 3100, 3200, 4317, 4318, 8080, 8081, 9090, 9093, 9100 available

## Step 1: Start the Stack

### Option A: Using the start script (Recommended)

```bash
./start.sh
```

### Option B: Using Make

```bash
make up
```

### Option C: Using Docker Compose directly

```bash
docker-compose up -d
```

## Step 2: Verify Services

Check that all services are running:

```bash
docker-compose ps
```

All services should show as "healthy" or "running".

## Step 3: Access Grafana

1. Open your browser to http://localhost:3000
2. Login with:
   - **Username:** `admin`
   - **Password:** `StrongPass123`

## Step 4: Explore Data Sources

All data sources are automatically configured! Navigate to:

**Configuration** → **Data Sources**

You should see:
- ✅ Mimir (default) - Long-term metrics
- ✅ Prometheus - Short-term metrics
- ✅ Loki - Logs
- ✅ Tempo - Traces
- ✅ Alertmanager - Alerts

## Step 5: Test the Stack

Run the test script to send sample telemetry:

```bash
./test-telemetry.sh
```

## Step 6: View Your Data

### View Logs in Loki

1. Go to **Explore** in Grafana
2. Select **Loki** as the data source
3. Try this query:
   ```logql
   {job="test"}
   ```

### View Metrics in Prometheus/Mimir

1. Go to **Explore** in Grafana
2. Select **Mimir** as the data source
3. Try these queries:
   ```promql
   # CPU usage
   100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
   
   # Memory usage
   (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100
   
   # Container CPU
   rate(container_cpu_usage_seconds_total{name!=""}[5m])
   ```

### View Traces in Tempo

1. Go to **Explore** in Grafana
2. Select **Tempo** as the data source
3. Click **Search** to see recent traces
4. Use TraceQL queries:
   ```traceql
   { duration > 100ms }
   ```

## Step 7: Import Dashboards

### System Overview Dashboard

The stack includes a pre-configured system overview dashboard showing:
- CPU Usage
- Memory Usage
- Disk Usage
- Network Traffic
- Container Metrics

### Import More Dashboards

1. Go to **Dashboards** → **Import**
2. Popular dashboard IDs:
   - **1860** - Node Exporter Full
   - **14282** - cAdvisor exporter
   - **13639** - Loki & Promtail

## Common Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f grafana
```

### Check Health
```bash
make health
# or
curl http://localhost:3000/api/health
curl http://localhost:9090/-/healthy
curl http://localhost:3100/ready
curl http://localhost:3200/ready
curl http://localhost:8080/ready
```

### Restart Services
```bash
make restart
# or
docker-compose restart
```

### Stop Services
```bash
make down
# or
docker-compose down
```

### Clean Everything (removes data!)
```bash
make clean
# or
docker-compose down -v
```

## Next Steps

### 1. Instrument Your Application

#### Python
```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)
span_processor = BatchSpanProcessor(
    OTLPSpanExporter(endpoint="localhost:4317", insecure=True)
)
trace.get_tracer_provider().add_span_processor(span_processor)
```

#### Node.js
```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'localhost:4317',
  }),
});

sdk.start();
```

#### Go
```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/sdk/trace"
)

exporter, _ := otlptracegrpc.New(
    context.Background(),
    otlptracegrpc.WithEndpoint("localhost:4317"),
    otlptracegrpc.WithInsecure(),
)

tp := trace.NewTracerProvider(
    trace.WithBatcher(exporter),
)
otel.SetTracerProvider(tp)
```

### 2. Configure Alerts

Edit `alertmanager/config.yml` to add your notification channels (Slack, email, etc.)

### 3. Create Custom Dashboards

Build dashboards in Grafana and save them to `grafana/dashboards/`

### 4. Adjust Retention

Modify retention periods in:
- `prometheus/prometheus.yml` (default: 15 days)
- `loki/loki-config.yaml` (configure retention)
- `tempo/tempo.yaml` (default: 24 hours)

## Troubleshooting

### Services not starting?

```bash
# Check logs
docker-compose logs

# Check individual service
docker-compose logs grafana
```

### Port already in use?

Edit `docker-compose.yml` to change port mappings:
```yaml
ports:
  - "3001:3000"  # Changed from 3000:3000
```

### Out of memory?

Increase Docker Desktop memory allocation:
- Docker Desktop → Settings → Resources → Memory → Increase

### Data sources not appearing?

```bash
# Restart Grafana
docker-compose restart grafana

# Check provisioning
docker-compose exec grafana ls -la /etc/grafana/provisioning/datasources/
```

### Cannot send telemetry?

Verify OTLP endpoints are accessible:
```bash
curl http://localhost:4318/v1/traces
curl http://localhost:13133/  # Health check
```

## Learn More

- [Full Documentation](./README.md)
- [Grafana Docs](https://grafana.com/docs/)
- [OpenTelemetry Docs](https://opentelemetry.io/docs/)
- [Prometheus Query Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [LogQL Guide](https://grafana.com/docs/loki/latest/logql/)
- [TraceQL Guide](https://grafana.com/docs/tempo/latest/traceql/)

## Support

For issues or questions:
1. Check the logs: `docker-compose logs`
2. Verify health: `make health`
3. Review the [README](./README.md)

---

Happy Observing! 🚀

