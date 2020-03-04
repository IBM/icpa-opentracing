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
export PATH="$PATH:$(PWD)/istio-1.4.4/bin"
istioctl verify-install
istioctl manifest apply  --set profile=demo --set values.tracing.enabled=true --set values.kiali.enabled=true


# step 3
kubectl get namespace tracing || \
kubectl create namespace tracing


# step 4

kubectl get all -n istio-system

cat <<EOF | kubectl apply -n tracing -f -
kind: Service
apiVersion: v1
metadata:
  name: jaeger-collector
spec:
  type: ExternalName
  externalName: jaeger-collector.istio-system.svc.cluster.local
  ports:
  - port: 14268
EOF



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

# step 6
cd "${tutorial_dir}"
kubectl create configmap jaeger-config -n tracing --from-env-file=jaeger.properties

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
        port:
          number: 3000
EOF

for i in {1..50}; do curl -s localhost/node-springboot; sleep 2; curl -s localhost/node-jee; sleep 2; done
