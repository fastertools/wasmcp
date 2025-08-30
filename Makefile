.PHONY: help sync-versions sync-wit validate-versions validate-wit bump-all-patch bump-all-minor bump-all-major

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

sync-versions: ## Sync versions across the repository
	@echo "Syncing versions..."
	@./scripts/sync-versions.sh

sync-wit: ## Sync WIT files from root to components
	@echo "🔄 Syncing WIT files from /wit to components..."
	@# Sync to components/http-transport
	@if [ -d components/http-transport ]; then \
		echo "  📦 Syncing to components/http-transport/wit"; \
		rm -rf components/http-transport/wit/deps/mcp 2>/dev/null || true; \
		mkdir -p components/http-transport/wit/deps; \
		cp -r wit/deps/mcp components/http-transport/wit/deps/; \
		[ -f wit/world.wit ] && cp wit/world.wit components/http-transport/wit/ || true; \
	fi
	@echo "✨ WIT files synchronized successfully!"

validate-versions: ## Check if versions are in sync
	@echo "Validating versions..."
	@./scripts/sync-versions.sh
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "❌ Version inconsistency detected!"; \
		git status --short; \
		exit 1; \
	else \
		echo "✅ All versions are in sync!"; \
	fi

validate-wit: ## Check if WIT files are in sync
	@echo "Validating WIT files..."
	@$(MAKE) sync-wit > /dev/null 2>&1
	@# Check for any modifications in WIT directories
	@if [ -n "$$(git status --porcelain '*/wit/deps/mcp/*.wit' | grep '^[[:space:]]*M')" ]; then \
		echo "❌ WIT files are out of sync!"; \
		git status --short '*/wit/deps/mcp/*.wit' | grep '^[[:space:]]*M'; \
		echo "Run 'make sync-wit' to fix"; \
		exit 1; \
	else \
		echo "✅ All WIT files are in sync!"; \
	fi

# Individual component bumps
bump-transport-patch: ## Bump mcp-http-transport patch version
	@current=$$(grep 'mcp-http-transport = ' versions.toml | cut -d'"' -f2); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2"."$$3+1}'); \
	./scripts/bump-version.sh mcp-http-transport $$new

bump-transport-minor: ## Bump mcp-http-transport minor version
	@current=$$(grep 'mcp-http-transport = ' versions.toml | cut -d'"' -f2); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2+1".0"}'); \
	./scripts/bump-version.sh mcp-http-transport $$new

bump-mcp-wit: ## Bump MCP WIT package version (breaking changes only)
	@current=$$(grep '^mcp = ' versions.toml | cut -d'"' -f2); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2+1".0"}'); \
	./scripts/bump-version.sh mcp $$new

# Bump all packages
bump-all-patch: ## Bump transport patch version
	@echo "Bumping transport package (patch)..."
	@$(MAKE) bump-transport-patch
	@echo ""
	@echo "✅ Transport package bumped!"
	@echo ""
	@echo "Don't forget to:"
	@echo "  1. Review changes: git diff"
	@echo "  2. Commit: git commit -am 'chore: bump transport patch version'"
	@echo "  3. Create tag:"
	@echo "     git tag mcp-http-transport-v$$(grep 'mcp-http-transport = ' versions.toml | cut -d'"' -f2)"
	@echo "  4. Push: git push origin main --tags"

bump-all-minor: ## Bump transport minor version
	@echo "Bumping transport package (minor)..."
	@$(MAKE) bump-transport-minor
	@echo ""
	@echo "✅ Transport package bumped!"
	@echo ""
	@echo "Note: Minor version bumps should include new features."
	@echo "Make sure your changes warrant a minor version bump."

# Install targets
install-rust-tools: ## Install required Rust tools
	@which cargo-component > /dev/null || { \
		if command -v cargo-binstall >/dev/null 2>&1; then \
			echo "Installing cargo-component with cargo-binstall..."; \
			cargo binstall cargo-component --no-confirm; \
		else \
			echo "Installing cargo-component from source..."; \
			cargo install --locked cargo-component; \
		fi; \
	}
	@which wasm-tools > /dev/null || { \
		if command -v cargo-binstall >/dev/null 2>&1; then \
			echo "Installing wasm-tools with cargo-binstall..."; \
			cargo binstall wasm-tools --no-confirm; \
		else \
			echo "Installing wasm-tools from source..."; \
			cargo install --locked wasm-tools; \
		fi; \
	}
	@which wkg > /dev/null || { \
		if command -v cargo-binstall >/dev/null 2>&1; then \
			echo "Installing wkg with cargo-binstall..."; \
			cargo binstall wkg --no-confirm; \
		else \
			echo "Installing wkg from source..."; \
			cargo install --locked wkg; \
		fi; \
	}

install-deps: install-rust-tools ## Install all dependencies

# Lint targets
lint-rust: ## Run Rust linters (clippy and rustfmt check)
	@echo "Running clippy..."
	cd components/http-transport && cargo clippy -- -D warnings
	@echo "Checking rustfmt..."
	cd components/http-transport && cargo fmt -- --check

lint-rust-fix: ## Fix Rust lint issues
	@echo "Running clippy with fixes..."
	cd components/http-transport && cargo clippy --fix --allow-dirty --allow-staged
	@echo "Running rustfmt..."
	cd components/http-transport && cargo fmt

lint-all: lint-rust ## Run all linters

lint-fix-all: ## Fix all lint and formatting issues
	@echo "Fixing all lint and formatting issues..."
	@$(MAKE) lint-rust-fix
	@echo "✅ All lint and formatting issues fixed!"

# Build targets
build-transport: ## Build mcp-http-transport
	cd components/http-transport && cargo clippy -- -D warnings && cargo component build --release

build-all: build-transport ## Build all components

# Test targets
test-transport: ## Test mcp-http-transport
	cd components/http-transport && cargo test

test-rust: test-transport ## Run all Rust tests

test-all: test-rust ## Run all tests

# CI targets
ci-setup: install-deps ## Setup CI environment

ci-build: ci-setup build-all ## CI build pipeline

ci-test: test-all ## CI test pipeline

ci: ci-build ci-test ## Run full CI pipeline

# Clean targets
clean: ## Clean all build artifacts
	cd components/http-transport && cargo clean

# Release helper
show-versions: ## Show current versions
	@echo "Current versions:"
	@echo "  mcp-http-transport: $$(grep 'mcp-http-transport = ' versions.toml | cut -d'"' -f2)"
	@echo ""
	@echo "WIT packages:"
	@echo "  mcp: $$(grep '^mcp = ' versions.toml | cut -d'"' -f2)"

get-transport-version: ## Get mcp-http-transport version
	@grep 'mcp-http-transport = ' versions.toml | cut -d'"' -f2

# Publishing targets
publish-transport: ## Publish mcp-http-transport to ghcr.io
	@echo "Publishing mcp-http-transport..."
	@version=$$(grep 'mcp-http-transport = ' versions.toml | cut -d'"' -f2); \
	cd components/http-transport && \
	wkg oci push ghcr.io/fastertools/mcp-http-transport:$$version \
		--annotation "org.opencontainers.image.source=https://github.com/fastertools/wasmcp" \
		--annotation "org.opencontainers.image.description=MCP HTTP transport component" \
		--annotation "org.opencontainers.image.licenses=Apache-2.0" \
		target/wasm32-wasip1/release/mcp_transport_http.wasm && \
	wkg oci push ghcr.io/fastertools/mcp-http-transport:latest \
		--annotation "org.opencontainers.image.source=https://github.com/fastertools/wasmcp" \
		--annotation "org.opencontainers.image.description=MCP HTTP transport component" \
		--annotation "org.opencontainers.image.licenses=Apache-2.0" \
		target/wasm32-wasip1/release/mcp_transport_http.wasm
	@echo "✅ Published mcp-http-transport v$$(grep 'mcp-http-transport = ' versions.toml | cut -d'"' -f2)"

publish-all: ## Publish transport component
	@echo "⚠️  Publishing transport component..."
	@echo "This will publish:"
	@echo "  - mcp-http-transport v$$(make get-transport-version) to ghcr.io"
	@echo ""
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read confirm
	@$(MAKE) publish-transport
	@echo ""
	@echo "🎉 Transport component published!"

publish-dry-run: ## Dry run publish
	@echo "Dry run for transport component:"
	@echo ""
	@echo "=== mcp-http-transport ==="
	@echo "Would publish v$$(make get-transport-version) to ghcr.io"

# Release workflow targets
release-patch: ## Full release workflow for patch version
	@echo "Starting patch release..."
	@$(MAKE) bump-all-patch
	@echo ""
	@echo "Changes made. Please:"
	@echo "1. Review: git diff"
	@echo "2. Commit: git commit -am 'chore: release patch version'"
	@echo "3. Tag and push:"
	@echo "   git tag mcp-http-transport-v$$(make get-transport-version)"
	@echo "   git push origin main --tags"
	@echo ""
	@echo "GitHub Actions will handle publishing when tags are pushed."

release-minor: ## Full release workflow for minor version
	@echo "Starting minor release..."
	@$(MAKE) bump-all-minor
	@echo ""
	@echo "Changes made. Please:"
	@echo "1. Review: git diff"
	@echo "2. Commit: git commit -am 'chore: release minor version'"
	@echo "3. Tag and push (same as patch release)"