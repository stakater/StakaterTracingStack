# Stakater Tracing Stack

## Overview

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