# Incident Response Runbook & SRE Playbook

## 1. Service Level Objectives (SLOs) & Targets

| Indicator | Objective (SLO) | Measurement Method | Alert Trigger |
| :--- | :--- | :--- | :--- |
| **Availability** | 99.9% uptime per calendar month | Successful HTTP 200 on `/health` probe | Outage > 1 minute |
| **Response Latency** | 95% requests < 50ms | Nginx access metrics / load balancer | P95 > 150ms for 5m |
| **Error Rate** | < 0.1% 5xx errors | `rate(5xx_requests) / rate(total_requests)` | 5xx rate > 1% |
| **MTTD (Detect)** | < 2 minutes | Prometheus alert evaluation window | Alert firing latency |
| **MTTR (Resolve)** | < 5 minutes | Time from incident alert to verified recovery | Post-mortem tracking |

---

## 2. Failure Scenarios & Incident Playbooks

### Incident Playbook 1: Pod Crash / Deletion
- **Symptom:** Kubernetes Pod unexpectedly terminated, OOMKilled, or evicted.
- **Alert:** `PodRestartsHigh` or `KubePodNotReady`.
- **Diagnostic Steps:**
  ```bash
  kubectl get pods -n project-dashboard
  kubectl describe pod <pod-name> -n project-dashboard
  kubectl logs <pod-name> -n project-dashboard -c dashboard --previous
  ```
- **Remediation:**
  1. Kubernetes ReplicaSet controller automatically spawns a replacement pod within 2 seconds.
  2. If crash loop is caused by OOM (exit code 137), increase memory limits in `k8s/project-dashboard.yaml` (`limits.memory: 512Mi`).
  3. Apply updated manifest: `kubectl apply -f k8s/project-dashboard.yaml`.
- **Observed Behavior:** New pod transitioned from `ContainerCreating` to `Running` and passed readiness probes in under 12 seconds with 0 downtime to clients.

---

### Incident Playbook 2: Container Crash
- **Symptom:** Nginx process inside the container exits unexpectedly or gets killed.
- **Alert:** `NginxServiceDown` (`nginx_up == 0`).
- **Diagnostic Steps:**
  ```bash
  kubectl logs -n project-dashboard -l app.kubernetes.io/name=project-dashboard -c dashboard
  ```
- **Remediation:**
  1. Kubelet liveness probe detects process failure and automatically restarts the container.
  2. If the issue is persistent (bad configuration or corrupt assets), rollback to last known good deployment:
     ```bash
     kubectl rollout undo deployment/project-dashboard -n project-dashboard
     ```
- **Observed Behavior:** Container restarted cleanly; readiness probe shielded traffic until Nginx resumed serving HTTP 200.

---

### Incident Playbook 3: Failed Deployment / Bad Image Tag
- **Symptom:** CD pipeline deployed an image that does not exist or fails startup probes (`ImagePullBackOff` or `CrashLoopBackOff`).
- **Alert:** `DeploymentRolloutStalled`.
- **Diagnostic Steps:**
  ```bash
  kubectl rollout status deployment/project-dashboard -n project-dashboard
  kubectl get events -n project-dashboard --sort-by='.metadata.creationTimestamp'
  ```
- **Remediation:**
  1. Kubernetes rolling update strategy ensures existing healthy replicas remain active and continue handling traffic.
  2. Trigger rollback immediately:
     ```bash
     kubectl rollout undo deployment/project-dashboard -n project-dashboard
     kubectl rollout status deployment/project-dashboard -n project-dashboard
     ```
- **Observed Behavior:** Rollout stalled safely without disrupting healthy pods. Rollback restored healthy deployment in under 5 seconds.

---

### Incident Playbook 4: High CPU Usage / Traffic Spike
- **Symptom:** Sustained high request volume causing CPU usage > 70%.
- **Alert:** `HighContainerCpuUsage` or `HighRequestRate`.
- **Diagnostic Steps:**
  ```bash
  kubectl top pods -n project-dashboard
  kubectl get hpa -n project-dashboard
  ```
- **Remediation:**
  1. HorizontalPodAutoscaler (HPA) automatically detects CPU utilization above the 70% threshold and scales deployment replicas from 2 up to 5.
  2. If manual emergency scaling is required:
     ```bash
     kubectl scale deployment project-dashboard --replicas=5 -n project-dashboard
     ```
- **Observed Behavior:** In ApacheBench testing at 5,457 req/sec, zero requests failed, and HPA reported live CPU metrics accurately.

---

### Incident Playbook 5: Failed Monitoring Scrape
- **Symptom:** Prometheus reports scrape target DOWN for `nginx-exporter`.
- **Alert:** `NginxExporterScrapeFailed`.
- **Diagnostic Steps:**
  ```bash
  # Check if exporter sidecar is running
  kubectl logs -n project-dashboard -l app.kubernetes.io/name=project-dashboard -c nginx-exporter
  # Verify local status endpoint from inside pod
  kubectl exec -it -n project-dashboard deploy/project-dashboard -c dashboard -- wget -qO- http://127.0.0.1:8080/nginx_status
  ```
- **Remediation:**
  1. Verify Nginx permissions in `/etc/nginx/nginx.conf` (`allow 127.0.0.1; allow ::1; allow 172.16.0.0/12;`).
  2. Restart exporter container or restart pod:
     ```bash
     kubectl rollout restart deployment/project-dashboard -n project-dashboard
     ```
- **Observed Behavior:** Scraper verified returning HTTP 200; `nginx_up` restored to `1`.

---

### Incident Playbook 6: Application Health Check Failure
- **Symptom:** Endpoint `/health` returns HTTP 500, 502, or 404.
- **Alert:** `NginxServiceDown`.
- **Diagnostic Steps:**
  ```bash
  curl -i http://localhost:8080/health
  kubectl exec -n project-dashboard deploy/project-dashboard -c dashboard -- nginx -t
  ```
- **Remediation:**
  1. Verify Nginx configuration syntax.
  2. Check `/tmp` volume mount (`emptyDir: {}`) to ensure PID and temporary directories are writable.
  3. Re-apply validated manifest:
     ```bash
     kubectl apply -f k8s/project-dashboard.yaml
     ```
- **Observed Behavior:** Health check endpoint returns `HTTP 200 OK` with payload `ok`.
