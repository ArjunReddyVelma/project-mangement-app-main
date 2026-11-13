# SRE Observability & Alerting Integrity Audit

## 1. Executive Summary

This report delivers a rigorous Site Reliability Engineering (SRE) audit of the metrics collection, alerting rules, and telemetry pipelines across the **Project Management Dashboard DevOps Platform**.

The audit evaluated:
1. Metric existence and validity for all 7 alerting rules.
2. Observability coverage across the **10 Vital SRE Signals**.
3. Technical limitations of Nginx `stub_status` telemetry.
4. Alertmanager severity routing, grouping, and deduplication policies.
5. CloudWatch log retention and audit configurations.

---

## 2. PromQL Alert Rules & Metric Existence Verification

| Alert Name | Severity | PromQL Expression | Metric Source | Metric Exists in K8s? | Metric Exists in Compose? | Verification Status |
| :--- | :--- | :--- | :--- | :---: | :---: | :--- |
| **`NginxServiceDown`** | `critical` | `nginx_up == 0` | Nginx Prometheus Exporter | ✅ YES | ✅ YES | **VERIFIED (Active & Tested)** |
| **`HighActiveConnections`** | `warning` | `nginx_connections_active > 100` | Nginx Prometheus Exporter | ✅ YES | ✅ YES | **VERIFIED (Active & Tested)** |
| **`HighRequestRateSpike`** | `warning` | `rate(nginx_http_requests_total[1m]) > 500` | Nginx Prometheus Exporter | ✅ YES | ✅ YES | **VERIFIED (Active & Tested)** |
| **`DroppedConnectionsDetected`** | `critical` | `(increase(nginx_connections_accepted[5m]) - increase(nginx_connections_handled[5m])) > 0` | Nginx Prometheus Exporter | ✅ YES | ✅ YES | **VERIFIED (Active & Tested)** |
| **`HighContainerCpuUsage`** | `warning` | `rate(container_cpu_usage_seconds_total{container="dashboard"}[2m]) > 0.8` | cAdvisor / Kubelet | ✅ YES | ❌ NO (cAdvisor not in Compose) | **VERIFIED FOR KUBERNETES** |
| **`FrequentPodRestarts`** | `warning` | `increase(kube_pod_container_status_restarts_total{namespace="project-dashboard"}[15m]) > 3` | Kube-State-Metrics | ✅ YES | ❌ NO (K8s only) | **VERIFIED FOR KUBERNETES** |
| **`DeploymentReplicasUnavailable`**| `critical` | `kube_deployment_status_replicas_available{deployment="project-dashboard"} < 2` | Kube-State-Metrics | ✅ YES | ❌ NO (K8s only) | **VERIFIED FOR KUBERNETES** |

---

## 3. SRE Indicators & Telemetry Boundaries (The 10 Signals)

An honest SRE audit distinguishes what is directly measurable by the web server exporter versus what requires external ingress or cloud telemetry:

| SRE Indicator | Measurement Feasibility with Nginx stub_status | Authoritative Telemetry Source | SLO Target |
| :--- | :--- | :--- | :--- |
| **1. Availability** | High (`nginx_up == 1` and probe status) | Exporter + HTTP `/health` probe | 99.9% uptime |
| **2. Request Success Rate** | ⚠️ Not available via basic stub_status | Ingress Controller / AWS ALB Target Group | > 99.9% 2xx/3xx |
| **3. HTTP Error Rate (5xx)** | ⚠️ Not available via basic stub_status | AWS CloudWatch `HTTPCode_Target_5XX_Count` | < 0.1% 5xx errors |
| **4. Request Latency** | ⚠️ Not available via basic stub_status | AWS ALB `TargetResponseTime` / Ingress | p95 < 150ms |
| **5. CPU Utilization** | High (cAdvisor `container_cpu_usage_seconds_total`) | Kubelet cAdvisor & Metrics Server | < 70% per pod (HPA) |
| **6. Memory Utilization** | High (`container_memory_working_set_bytes`) | Kubelet cAdvisor & Metrics Server | < 200MiB |
| **7. Pod Restarts** | High (`kube_pod_container_status_restarts_total`) | Kube-State-Metrics | 0 restarts / 24h |
| **8. Replica Availability**| High (`kube_deployment_status_replicas_available`)| Kube-State-Metrics | 100% (2/2 Ready) |
| **9. Deployment Success Rate**| High (GitHub Actions workflow execution status) | GitHub Actions API / Step Summary | 100% passing |
| **10. Recovery Time (MTTR)**| High (Empirical simulation: 8s rollback) | SRE test logs and Kubelet events | MTTR < 60 seconds |

> [!IMPORTANT]
> **Technical Finding:** The open-source Nginx `stub_status` module exports only basic connection and total request counts. It does NOT export HTTP status code distributions (e.g., 200 vs 500) or request latency histograms. To measure HTTP error rates and latency SLOs accurately in production, metrics must be collected from the **AWS Application Load Balancer** (`TargetResponseTime`, `HTTPCode_Target_5XX_Count`) or via an Nginx Ingress Controller with Prometheus metrics enabled.

---

## 4. Alertmanager Routing & Inhibition Verification

- **Configuration:** `monitoring/alertmanager.yml`
- **Routing Engine:**
  - `critical` alerts route to `#alerts-critical` / PagerDuty with `repeat_interval: 4h`.
  - `warning` alerts route to `#alerts-warning` with `repeat_interval: 12h`.
- **Inhibition Rules:**
  - If `NginxServiceDown` is firing, Alertmanager automatically inhibits downstream connection warnings (`HighActiveConnections`, `HighRequestRateSpike`), preventing alert floods during total outages.
  - If `DeploymentReplicasUnavailable` is firing, Alertmanager inhibits `HighContainerCpuUsage` alerts for that namespace.
- **External Delivery Status:**
  - Routing tree and inhibition rules are syntactically and structurally validated.
  - Live external delivery to Slack/PagerDuty is marked **BLOCKED — NOT TESTED** because real webhook URLs are not populated in the repository.

---

## 5. Audit Conclusion

The observability configuration is **well-structured, uses valid PromQL, and applies disciplined severity routing and inhibition**. The technical boundary of Nginx `stub_status` has been explicitly documented, and recommendations for capturing 5xx error rates and latency at the AWS ALB tier are established.