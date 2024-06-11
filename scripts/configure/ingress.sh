cat <<EOF | tee values_ingress-nginx.yaml
controller:
  config:
    whitelist-source-range: >-
      0.0.0.0/0
    log-format-escape-json: "true"
    large-client-header-buffers: "4 256k"
    proxy-buffer-size: "128k"
    http-snippet: |
      real_ip_header X-Real-IP;
      real_ip_recursive on;
    log-format-upstream: >-
      {"time": "\$time_iso8601", "time_local": "\$time_local", "remote_addr": "\$remote_addr", "x-forward-for": "\$proxy_add_x_forwarded_for", "request_id": "\$req_id",
      "remote_user": "\$remote_user", "bytes_sent": \$bytes_sent, "request_time": \$request_time, "status":"\$status", "vhost": "\$host", "request_proto": "\$server_protocol",
      "path": "\$uri", "request":"\$request", "request_length": \$request_length, "duration": \$request_time,"method": "\$request_method", "http_referrer": "\$http_referer",
      "http_user_agent": "\$http_user_agent",
      "proxy_upstream_name": "\$proxy_upstream_name", "proxy_alternative_upstream_name": "\$proxy_alternative_upstream_name",  "upstream_addr":"\$upstream_addr",
      "upstream_response_length": "\$upstream_response_length",  "upstream_response_time": "\$upstream_response_time", "upstream_status": "\$upstream_status", "req_id": "\$req_id"}
    ssl-protocols: "TLSv1 TLSv1.1 TLSv1.2 TLSv1.3"
    ssl-ciphers: "HIGH:!aNULL:!MD5"
  allowSnippetAnnotations: true
  metrics:
    port: 10254
    enabled: true
  admissionWebhooks:
    enabled: true
  service:
    externalTrafficPolicy: Local
    externalIPs:
    - 10.0.0.10
  kind: DaemonSet
  podAnnotations:
    prometheus.io/path: /metrics
    prometheus.io/port: "10254"
    prometheus.io/scheme: http
    prometheus.io/scrape: "true"
EOF

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx --values values_ingress-nginx.yaml --namespace kube-system --wait

echo "Ожидание старта ingress controller"
kubectl wait --for=condition=available --timeout=120s --all deployments -A
kubectl -n kube-system wait --for=condition=ready --timeout=120s pods -l app.kubernetes.io/component=controller
