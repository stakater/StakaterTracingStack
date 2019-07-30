# StakaterTracingStack

This document provide guideline regarding the installation and usage of [Istio](https://istio.io/) on kubernetes cluster.

## Installation

This section provides step by step guideline regarding istio installation.

* Create a namespace using the manifest given below in which istio and its dependencies will be installed:

```json
{ 
  "kind": "Namespace", 
  "apiVersion": "v1", 
  "metadata": { 
    "name": "tracing", 
    "labels": { 
      "name": "tracing" 
    }
  }
}
```

Create the namespace using the command given below:
```bash
$ sudo kubectl apply -f namespace-creation-manifest.yaml
```


* Istio can be installed in two ways:

  * `Method 1`: Follow the guidelines given in this [link](https://istio.io/docs/setup/kubernetes/install/kubernetes/) to install istio using kubernetes manifests.

  * `Method 2`: By using HelmRelease, its manifest is given below:

```yaml
apiVersion: flux.weave.works/v1beta1
kind: HelmRelease
metadata:
  name: istio
  namespace: tracing
spec:
  releaseName: istio
  chart:
    repository: https://gcsweb.istio.io/gcs/istio-prerelease/daily-build/release-1.1-latest-daily/charts/
    name: istio
    version: 1.1.0
  values:
    global:
      enableTracing: true
    tracing:
      enabled: true
    pilot:
      traceSampling: 100
    prometheus:
      enabled: false
```

Currently, this [chart](https://github.com/istio/istio/tree/master/install/kubernetes/helm/istio) is being used for Istio deployment.


## Tracing

The above configurations will enable istio tracing. To check whether tracing has been enabled or not, we will use the sample app provided by istio. Following the guidelines given below:

* Tracing for applications will work when the following requirements are fulfilled:

  * Pods and services [requirements](https://istio.io/docs/setup/kubernetes/prepare/requirements/)
  * Application code needs to modified a little bit(example can be found in this [link](https://github.com/istio/istio/blob/master/samples/bookinfo/src/productpage/productpage.py#L130) of istio sample application) so that it can handle the trace information that is part of the request. Details can be found on this [link](https://github.com/istio/istio/issues/14094)  


* Follow these [guidelines](https://istio.io/docs/examples/bookinfo/) to deploy the sample application.

* Deploy the xposer for enabling ingress, its manifest is given below:
```yaml
apiVersion: flux.weave.works/v1beta1
kind: HelmRelease
metadata:
  name: stakater-release-xposer
  namespace: control
spec:
  releaseName: stakater-release-xposer
  chart:
    repository: https://stakater.github.io/stakater-charts 
    name: xposer
    version: 0.0.17
  values:
    xposer:
      configFilePath: /configs/config.yaml
      watchGlobally: false
      exposeServiceURL: globally
      config:
        domain: workshop.stakater.com
        ingressURLTemplate: "{{.Service}}-{{.Namespace}}.{{.Domain}}"
        ingressURLPath: /
        ingressNameTemplate: "{{.Service}}-{{.Namespace}}"
        tlsSecretNameTemplate: "tls-cert"
        tls: true
      tolerations: {}
```

* Use the manifest given below to enable jeager ingress because the default configuration(using the helm chart value parameters) are not working correctly due to invalid documentation: 

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:    
    ingress.kubernetes.io/force-ssl-redirect: "true"
    kubernetes.io/ingress.class: external-ingress
    nginx.ingress.kubernetes.io/service-upstream: "true"
    nginx.ingress.kubernetes.io/upstream-vhost: jaeger-query.istio-system.svc.cluster.local
    forecastle.stakater.com/appName: Jaeger
    forecastle.stakater.com/expose: "true"
    forecastle.stakater.com/icon: https://raw.githubusercontent.com/stakater/ForecastleIcons/master/jaeger.png
    ingress.kubernetes.io/rewrite-target: /
  name: jaeger-ingress
spec:
  rules:
  - host: <host-name>
    http:
      paths:
      - backend:
          serviceName: jaeger-query
          servicePort: 16686
  tls:
  - hosts:
    - <host-name>
    secretName: tls-cert
```

* Ingress will take sometime before it is enabled. Open the ingress link in the browser.

* Each of the application service needs to be visible in the jeager services drop down as well as in the dependencies graph.



## Notes
This section explain the problems that has been faced during installation, deployment and usage of Istio.

### Nginx-ingress Controller

* Initially, we tried to use nginx-ingress controller to enable ingress for istio services(like jaeger) but the problem was with the traces because the requests done through nginx-ingress was not able to generate traces and no way was found on how to configure nginx-ingress controller with Istio. 

  Although, we were able to get traces by using Istio ingress gateway on jaeger.

### Proxy(sidecar) Container Injection
There are two ways to inject sidecar(proxy) container:

* To manually inject sidecar use the instruction given on this [link](https://istio.io/docs/setup/kubernetes/additional-setup/sidecar-injection/#manual-sidecar-injection).  

* Istio by default monitors all namespaces but it only add sidecars(envoy) to those namespaces that have this label `istio-injection:enabled` assigned. To assign this label to a namespace use the command given below:

#### Disable sidecar injection in a pod
* By default istio inserts sidecar containers in each pods(only if namespace has `istio-injection: enabled`) automatically, to disable sidecar injection in a pod add this annotation `sidecarInjectorWebhook.enabled: "false"` to pod annotations of a deployment.

```bash
$ sudo kubectl label namespace <namespace-name> istio-injection=enabled
```

### CRD deletion issue

* Sometimes due to ungraceful deletion of istio helm release CRDs will not be removed. There are two ways to delete remaining CRDs. 

  * `Method-1`: Use the command given below to get all the CRDs and delete them one by one:
  ```bash
  $ sudo kubectl get crd

  $ sudo kubectl delete crd <crd-name>
  ```

  * `Method-2`: In this method we will use the manifest for crd creation to delete all the corresponding CRDs. First of all down the istio release. Move inside this folder (istio-X/install/kubernetes/helm/istio-init/files/) and run the command given below on each file:
  ```bash
  $ sudo kubectl delete -f <filename>.yaml
  ```

