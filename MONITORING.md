# Observability & Monitoring Guide

## 1. Monitoring Stack Architecture

The observability stack comprises **Prometheus v2.54.1**, **Grafana v11.5.2**, and the **Nginx Prometheus Exporter v1.4.1**:

```
[ Nginx Web Server ] (:8080/nginx_status)
        │ (local scrape)
[ Nginx Prometheus Exporter ] (:9113/metrics)
        ▲
        │ (15s scrape interval)
[ Prometheus Server ] (:9090) ──> [ Alert Rules Engine ]
        ▲
        │ (PromQL queries)
[ Grafana Dashboard ] (:3000)
```

---

## 2. Key Metrics Reference

| Metric Name | Type | Description | Alerting Threshold |
| :--- | :--- | :--- | :--- |
| `nginx_up` | Gauge | Status of last scrape (`1` = healthy, `0` = down) | `nginx_up == 0` for 1m (Critical) |
| `nginx_http_requests_total` | Counter | Cumulative HTTP requests served | Rate spike > 500 req/s |
| `nginx_connections_active` | Gauge | Current active client connections | > 100 connections for 2m |
| `nginx_connections_reading` | Gauge | Connections reading client request headers | Tracked in Grafana |
| `nginx_connections_writing` | Gauge | Connections writing response back to client | Tracked in Grafana |
| `nginx_connections_waiting` | Gauge | Idle keep-alive connections waiting for requests | Tracked in Grafana |
| `container_cpu_usage_seconds_total` | Counter | CPU core seconds consumed by container | > 80% utilization for 3m |
| `kube_pod_container_status_restarts_total` | Counter | Number of container restarts | > 3 restarts in 15m |

---

## 3. Grafana Dashboards

The pre-provisioned dashboard **DevOps Platform Overview** (`uid: devops-platform-overview`) visualizes:

1. **Service Availability & Health:**
   - Single-stat availability badge (UP / DOWN).
   - Active client connection gauge.
   - Desired vs available pod replica counter.
   - Container restart frequency indicator.
2. **Traffic & Performance Metrics:**
   - Real-time HTTP request throughput (`rate(nginx_http_requests_total[1m])`).
   - Detailed connection state breakdown (Reading, Writing, Waiting).
3. **Resource Utilization:**
   - Container CPU core consumption over time.
   - Container resident memory footprint (`container_memory_usage_bytes`).

### Accessing Grafana
When running locally via Docker Compose:
- **URL:** `http://localhost:3000`
- **Username:** `admin`
- **Password:** `admin`
- **Datasource:** Automated Prometheus provisioned at `http://prometheus:9090`.

---

## 4. Alert Rules Configuration

Alert rules are defined in `monitoring/alert_rules.yml`:

```yaml
groups:
  - name: project-dashboard-alerts
    rules:
      - alert: NginxServiceDown
        expr: nginx_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Nginx web server is down"
          description: "Nginx exporter cannot scrape Nginx status endpoint on project-dashboard."

      - alert: HighActiveConnections
        expr: nginx_connections_active > 100
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High number of active connections"
          description: "Active connections to Nginx exceeded 100 for more than 2 minutes."

      - alert: HighRequestRate
        expr: rate(nginx_http_requests_total[1m]) > 500
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Unusual request spike detected"
          description: "HTTP request rate is higher than 500 req/sec."

      - alert: HighContainerCpuUsage
        expr: rate(container_cpu_usage_seconds_total[2m]) > 0.8
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "High container CPU utilization"
          description: "Container CPU utilization exceeded 80% for 3 minutes."

      - alert: PodRestartsHigh
        expr: increase(kube_pod_container_status_restarts_total[15m]) > 3
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Frequent container restarts"
          description: "Pod in namespace project-dashboard restarted more than 3 times in 15 minutes."
```

---

## 5. Metric Scrape Health Verification

```bash
# Verify Prometheus target status via API
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health, lastScrape: .lastScrape}'

# Query active alert states
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts'
```
