# DevOps Platform Troubleshooting & Operations Guide

## 1. Quick Diagnostic Checklist

| Issue Category | First Command to Run | What to Inspect |
| :--- | :--- | :--- |
| **Pod Status** | `kubectl get pods -n project-dashboard -o wide` | Ready state, Restarts, Pod Phase |
| **Pod Crash Logs** | `kubectl logs <pod-name> -n project-dashboard -c dashboard --previous` | Nginx error log, exit code |
| **Pod Events** | `kubectl describe pod <pod-name> -n project-dashboard` | Failed scheduling, probe failures, image pull errors |
| **Nginx Status** | `kubectl exec -it <pod-name> -n project-dashboard -c dashboard -- wget -qO- http://127.0.0.1:8080/nginx_status` | Active connections, status 200 response |
| **Exporter Logs** | `kubectl logs <pod-name> -n project-dashboard -c nginx-exporter` | Scrape errors, 403 Forbidden |
| **HPA Metrics** | `kubectl describe hpa project-dashboard -n project-dashboard` | Current CPU vs target percentage |

---

## 2. Common Scenarios & Verified Solutions

### Scenario 1: Nginx Exporter Returns `403 Forbidden`
- **Cause:** Nginx configuration `/etc/nginx/nginx.conf` blocks access to `/nginx_status` from the scraper IP.
- **Verification:**
  ```bash
  docker logs project-mangement-app-main-nginx-exporter-1
  # Output: error getting stats: expected 200 response, got 403
  ```
- **Solution:**
  In `nginx.conf`, ensure the `/nginx_status` location permits local loopback, IPv6, and private Docker/Kubernetes bridge networks:
  ```nginx
  location = /nginx_status {
    stub_status;
    access_log off;
    allow 127.0.0.1;
    allow ::1;
    allow 172.16.0.0/12;
    deny all;
  }
  ```

---

### Scenario 2: Container Fails Startup under `readOnlyRootFilesystem: true`
- **Cause:** Default Nginx attempts to write its PID to `/var/run/nginx.pid` and create temporary client body directories in `/var/cache/nginx/client_temp`. On a read-only root filesystem, this throws `Permission Denied` or `Read-only file system`.
- **Solution:**
  1. Relocate PID and temp paths to `/tmp` in `nginx.conf`:
     ```nginx
     pid /tmp/nginx.pid;
     client_body_temp_path /tmp/client_temp;
     proxy_temp_path /tmp/proxy_temp;
     fastcgi_temp_path /tmp/fastcgi_temp;
     uwsgi_temp_path /tmp/uwsgi_temp;
     scgi_temp_path /tmp/scgi_temp;
     ```
  2. Mount `/tmp` as an in-memory `emptyDir` volume in `k8s/project-dashboard.yaml`:
     ```yaml
     volumeMounts:
       - name: tmp
         mountPath: /tmp
     volumes:
       - name: tmp
         emptyDir: {}
     ```

---

### Scenario 3: HPA Shows `<unknown>/70%` CPU Utilization
- **Cause:** Metrics Server is not installed in the cluster or cannot communicate securely with Kubelet in local Kind clusters.
- **Solution:**
  1. Check Metrics Server deployment:
     ```bash
     kubectl get pods -n kube-system -l k8s-app=metrics-server
     ```
  2. In Kind clusters, patch Metrics Server with `--kubelet-insecure-tls`:
     ```bash
     kubectl patch -n kube-system deployment metrics-server --type=json \
       -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
     ```
  3. Verify metrics flow:
     ```bash
     kubectl top node
     kubectl top pod -n project-dashboard
     ```

---

### Scenario 4: Port Conflict on Localhost (`8080` or `9113`)
- **Cause:** Running Docker Compose simultaneously while Kind cluster extraPortMappings (`8080` and `9113`) are active.
- **Solution:**
  - Pause the Kind cluster control-plane container when testing Docker Compose:
    ```bash
    docker stop devops-platform-control-plane
    docker compose up -d
    ```
  - Or restart Kind after stopping Compose:
    ```bash
    docker compose down
    docker start devops-platform-control-plane
    ```

---

### Scenario 5: Emergency Rollback of Stalled Deployment
- **Cause:** Deployment updated with a faulty image tag or unverified code causing `ImagePullBackOff` or `CrashLoopBackOff`.
- **Command:**
  ```bash
  # Check revision history
  kubectl rollout history deployment/project-dashboard -n project-dashboard

  # Rollback immediately to previous working revision
  kubectl rollout undo deployment/project-dashboard -n project-dashboard

  # Verify recovery
  kubectl rollout status deployment/project-dashboard -n project-dashboard
  ```
