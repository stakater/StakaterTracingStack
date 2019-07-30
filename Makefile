.ONESHELL:
SHELL := /bin/bash
FOLDER_NAME ?= manifests

install:
	cd $(FOLDER_NAME)
	kubectl apply -f namespace.yaml
	kubectl apply -f istio-init.yaml
	kubectl apply -f .
install-dry-run: 
	cd $(FOLDER_NAME)
	kubectl apply -f namespace.yaml --dry-run
	kubectl apply -f istio-init.yaml --dry-run
	kubectl apply -f . --dry-run

delete:
	cd $(FOLDER_NAME)
	kubectl delete -f .