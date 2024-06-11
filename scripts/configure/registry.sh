URL_REGISTRY=registry.ingress.local
URL_REGISTRY_NIP=registry-10.0.0.10.nip.io

cat <<EOF | kubectl apply -n kube-system -f -
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: registry-storage-data-pv-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: standard
---
apiVersion: v1
kind: ReplicationController
metadata:
  labels:
    kubernetes.io/minikube-addons: registry
  name: registry
  namespace: kube-system
spec:
  replicas: 1
  selector:
    kubernetes.io/minikube-addons: registry
  template:
    metadata:
      labels:
        actual-registry: "true"
        kubernetes.io/minikube-addons: registry
    spec:
      containers:
      - image: registry.hub.docker.com/library/registry:2
        imagePullPolicy: IfNotPresent
        name: registry
        ports:
        - containerPort: 5000
          protocol: TCP
        env:
        - name: REGISTRY_STORAGE_DELETE_ENABLED
          value: "true"
        volumeMounts:
        - mountPath: /var/lib/registry
          name: pg-data          
      volumes:
      - name: pg-data
        persistentVolumeClaim:
          claimName: registry-storage-data-pv-claim
---
apiVersion: v1
kind: Service
metadata:
  labels:
    kubernetes.io/minikube-addons: registry
  name: registry
  namespace: kube-system
spec:
  type: ClusterIP
  ports:
  - port: 80
    name: http
    targetPort: 5000
  - port: 443
    name: https
    targetPort: 443
  selector:
    actual-registry: "true"
    kubernetes.io/minikube-addons: registry
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: registry-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/proxy-body-size: 2048m
spec:
  ingressClassName: nginx
  rules:
  - host: "$URL_REGISTRY"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: registry
            port:
              number: 80
  - host: "$URL_REGISTRY_NIP"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: registry
            port:
              number: 80
EOF
kubectl -n kube-system wait --for=condition=ready --timeout=120s pods -l actual-registry=true

echo "for test registry [[curl  https://$URL_REGISTRY/v2/_catalog --insecure]]"
echo "for login [[docker login $URL_REGISTRY -u admin -p admin]]"
echo "for test registry [[curl  http://$URL_REGISTRY_NIP/v2/_catalog --insecure]]"
echo "for login [[docker login $URL_REGISTRY_NIP -u admin -p admin]]"

sudo sed -i '/$URL_REGISTRY/d' /etc/hosts
echo "10.0.0.10 $URL_REGISTRY" | sudo tee -a /etc/hosts
