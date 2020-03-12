cd ~
mkdir -p workspace/opentracing-tutorial-part1
cd workspace/opentracing-tutorial-part1
tutorial_dir=~/workspace/opentracing-tutorial-part1
cd "${tutorial_dir}"

# step 1
cat > jaeger.properties << EOF
JAEGER_ENDPOINT=http://jaeger-collector.istio-system.svc.cluster.local:14268/api/traces
JAEGER_REPORTER_LOG_SPANS=true
JAEGER_SAMPLER_TYPE=const
JAEGER_SAMPLER_PARAM=1
JAEGER_PROPAGATION=b3
EOF


# step 2
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH="$PATH:$(PWD)/bin"

istioctl verify-install

istioctl manifest apply \
  --set profile=demo \
  --set values.tracing.enabled=true \
  --set values.grafana.enabled=true \
  --set values.kiali.enabled=true


# step 3
kubectl get namespace tracing || \
kubectl create namespace tracing


# step 4

kubectl get all -n istio-system


# step 5

cd "${tutorial_dir}"
cd nodejs-tracing
appsody build

cd "${tutorial_dir}"
cd springboot-tracing
appsody build

cd "${tutorial_dir}"
cd jee-tracing
appsody build

docker images dev.local/*

### Edits to app-deploy.yaml (try and use YQ for it)

# step 6
cd "${tutorial_dir}"
cat <<EOF | kubectl apply -n tracing -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: jaeger-config
data:
  JAEGER_ENDPOINT: http://jaeger-collector.istio-system.svc.cluster.local:14268/api/traces
  JAEGER_PROPAGATION: b3
  JAEGER_REPORTER_LOG_SPANS: "true"
  JAEGER_SAMPLER_PARAM: "1"
  JAEGER_SAMPLER_TYPE: const
EOF

kubectl get configmap jaeger-config -n tracing -o yaml

# step 7
kubectl label namespace tracing istio-injection=enabled

kubectl get namespace -L istio-injection


# step 8
# no commands in the shell


# step 9

cd "${tutorial_dir}"
cd nodejs-tracing
appsody deploy delete
appsody deploy --namespace tracing &

cd "${tutorial_dir}"
cd springboot-tracing
appsody deploy delete
appsody deploy --namespace tracing &

cd "${tutorial_dir}"
cd jee-tracing
appsody deploy delete
appsody deploy --namespace tracing &


# step 10

cat <<EOF | kubectl apply -n tracing -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: nodejs-tracing-v1
spec:
  host: nodejs-tracing
  subsets:
  - name: v1
    labels:
      version: v1
EOF

      
cat <<EOF | kubectl apply -n tracing -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: tracing-tutorial-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: tracing-tutorialinfo
spec:
  hosts:
  - "*"
  gateways:
  - tracing-tutorial-gateway
  http:
  - match:
    - uri:
        exact: /node-springboot
    - uri:
        exact: /node-jee
    route:
    - destination:
        host: nodejs-tracing
        subset: v1
        port:
          number: 3000
      weight: 100
EOF


# Step 12 (removed)

cat <<EOF | kubectl apply -n tracing -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: nodejs-tracing-v1
spec:
  host: nodejs-tracing
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: jee-tracing-v1
spec:
  host: jee-tracing
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: nodejs-tracing-v2
spec:
  host: nodejs-tracing-v2
  subsets:
  - name: v2
    labels:
      version: v2
EOF

      
cat <<EOF | kubectl apply -n tracing -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: tracing-tutorial-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: tracing-tutorialinfo
spec:
  hosts:
  - "*"
  gateways:
  - tracing-tutorial-gateway
  http:
  - match:
    - uri:
        exact: /node-springboot
    - uri:
        exact: /node-jee
    route:
    - destination:
        host: nodejs-tracing
        subset: v1
        port:
          number: 3000
      weight: 30
EOF

cat <<EOF | kubectl apply -n tracing -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: tracing-tutorialinfo2
spec:
  hosts:
  - jee-tracing
  gateways:
  - tracing-tutorial-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: jee-tracing
        subset: v1
        port:
          number: 3000
EOF

while true ; do curl -s localhost/node-springboot; sleep 2; curl -s localhost/node-jee; sleep 2; done
