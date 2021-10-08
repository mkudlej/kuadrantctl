module github.com/kuadrant/kuadrantctl

go 1.16

require (
	github.com/getkin/kin-openapi v0.76.0
	github.com/kuadrant/kuadrant-controller v0.1.1
	github.com/kuadrant/limitador-operator v0.2.0
	github.com/mitchellh/go-homedir v1.1.0
	github.com/spf13/cobra v1.2.1
	github.com/spf13/viper v1.8.1
	istio.io/client-go v1.10.1
	k8s.io/api v0.21.2
	k8s.io/apiextensions-apiserver v0.21.2
	k8s.io/apimachinery v0.21.2
	k8s.io/client-go v0.21.2
	sigs.k8s.io/controller-runtime v0.9.2
	sigs.k8s.io/gateway-api v0.3.0
	sigs.k8s.io/yaml v1.2.0
)
