# Makefile for Cadife Smart Travel (Frontend)

.PHONY: build-dev build-staging build-prod run-dev run-staging run-prod

# Android builds
build-dev:
	@echo "Building Dev flavor..."
	flutter build apk --flavor dev -t lib/main_dev.dart

build-staging:
	@echo "Building Staging flavor..."
	flutter build apk --flavor staging -t lib/main_staging.dart

build-prod:
	@echo "Building Production flavor..."
	flutter build apk --flavor prod -t lib/main_prod.dart

# iOS builds
build-ios-dev:
	@echo "Building iOS Dev..."
	flutter build ios -t lib/main_dev.dart --scheme DevRunner

build-ios-staging:
	@echo "Building iOS Staging..."
	flutter build ios -t lib/main_staging.dart --scheme StagingRunner

build-ios-prod:
	@echo "Building iOS Production..."
	flutter build ios -t lib/main_prod.dart

# Run local
run-dev:
	flutter run -t lib/main_dev.dart --flavor dev

run-staging:
	flutter run -t lib/main_staging.dart --flavor staging

run-prod:
	flutter run -t lib/main_prod.dart --flavor prod

# CI/CD
ci-build: build-dev build-staging build-prod
	@echo "All flavors built successfully"
