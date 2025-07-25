.PHONY: help sync-versions sync-wit validate-versions validate-wit bump-all-patch bump-all-minor bump-all-major

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

sync-versions: ## Sync versions across the repository
	@echo "Syncing versions..."
	@./scripts/sync-versions.sh

sync-wit: ## Sync WIT files from root to all templates
	@echo "Syncing WIT files to templates..."
	@cp wit/mcp.wit templates/rust/content/handler/wit/mcp.wit
	@cp wit/mcp.wit templates/javascript/content/handler/wit/mcp.wit
	@cp wit/mcp.wit templates/typescript/content/handler/wit/mcp.wit
	@echo "✅ WIT files synced to all templates"

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
	@# Check only for modifications (M), not additions (A) or untracked (??)
	@if [ -n "$$(git status --porcelain templates/*/content/handler/wit/mcp.wit | grep '^[[:space:]]*M')" ]; then \
		echo "❌ WIT files are out of sync!"; \
		git status --short templates/*/content/handler/wit/mcp.wit | grep '^[[:space:]]*M'; \
		echo "Run 'make sync-wit' to fix"; \
		exit 1; \
	else \
		echo "✅ All WIT files are in sync!"; \
	fi

# Individual component bumps
bump-gateway-patch: ## Bump wasmcp-spin patch version
	@current=$$(grep 'wasmcp-spin = ' versions.toml | cut -d'"' -f2); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2"."$$3+1}'); \
	./scripts/bump-version.sh wasmcp-spin $$new

bump-gateway-minor: ## Bump wasmcp-spin minor version
	@current=$$(grep 'wasmcp-spin = ' versions.toml | cut -d'"' -f2); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2+1".0"}'); \
	./scripts/bump-version.sh wasmcp-spin $$new

bump-rust-patch: ## Bump wasmcp-rust patch version
	@current=$$(grep 'wasmcp-rust = ' versions.toml | cut -d'"' -f2); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2"."$$3+1}'); \
	./scripts/bump-version.sh wasmcp-rust $$new

bump-rust-minor: ## Bump wasmcp-rust minor version
	@current=$$(grep 'wasmcp-rust = ' versions.toml | cut -d'"' -f2); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2+1".0"}'); \
	./scripts/bump-version.sh wasmcp-rust $$new

bump-ts-patch: ## Bump wasmcp-typescript patch version
	@current=$$(grep 'wasmcp-typescript = ' versions.toml | cut -d'"' -f2); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2"."$$3+1}'); \
	./scripts/bump-version.sh wasmcp-typescript $$new

bump-ts-minor: ## Bump wasmcp-typescript minor version
	@current=$$(grep 'wasmcp-typescript = ' versions.toml | cut -d'"' -f2); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2+1".0"}'); \
	./scripts/bump-version.sh wasmcp-typescript $$new

bump-mcp-wit: ## Bump MCP WIT package version (breaking changes only)
	@current=$$(grep '^mcp = ' versions.toml | cut -d'"' -f2); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2+1".0"}'); \
	./scripts/bump-version.sh mcp $$new

bump-gateway-wit: ## Bump MCP Gateway WIT package version (breaking changes only)
	@current=$$(grep '^mcp-gateway = ' versions.toml | cut -d'"' -f2); \
	new=$$(echo $$current | awk -F. '{print $$1"."$$2+1".0"}'); \
	./scripts/bump-version.sh mcp-gateway $$new

# Bump all packages
bump-all-patch: ## Bump all packages patch version
	@echo "Bumping all packages (patch)..."
	@$(MAKE) bump-gateway-patch
	@$(MAKE) bump-rust-patch
	@$(MAKE) bump-ts-patch
	@echo ""
	@echo "✅ All packages bumped!"
	@echo ""
	@echo "Don't forget to:"
	@echo "  1. Review changes: git diff"
	@echo "  2. Commit: git commit -am 'chore: bump all packages patch version'"
	@echo "  3. Create tags:"
	@echo "     git tag wasmcp-spin-v$$(grep 'wasmcp-spin = ' versions.toml | cut -d'"' -f2)"
	@echo "     git tag wasmcp-rust-v$$(grep 'wasmcp-rust = ' versions.toml | cut -d'"' -f2)"
	@echo "     git tag wasmcp-typescript-v$$(grep 'wasmcp-typescript = ' versions.toml | cut -d'"' -f2)"
	@echo "  4. Push: git push origin main --tags"

bump-all-minor: ## Bump all packages minor version
	@echo "Bumping all packages (minor)..."
	@$(MAKE) bump-gateway-minor
	@$(MAKE) bump-rust-minor
	@$(MAKE) bump-ts-minor
	@echo ""
	@echo "✅ All packages bumped!"
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

install-ts-deps: ## Install TypeScript dependencies
	cd src/sdk/wasmcp-typescript && npm ci

install-deps: install-rust-tools install-ts-deps ## Install all dependencies

# Lint targets
lint-rust: ## Run Rust linters (clippy and rustfmt check)
	@echo "Running clippy..."
	cd src/components/wasmcp-spin && cargo clippy -- -D warnings
	cd src/sdk/wasmcp-rust && cargo clippy -- -D warnings
	@echo "Checking rustfmt..."
	cd src/components/wasmcp-spin && cargo fmt -- --check
	cd src/sdk/wasmcp-rust && cargo fmt -- --check

lint-rust-fix: ## Fix Rust lint issues
	@echo "Running clippy with fixes..."
	cd src/components/wasmcp-spin && cargo clippy --fix --allow-dirty --allow-staged
	cd src/sdk/wasmcp-rust && cargo clippy --fix --allow-dirty --allow-staged
	@echo "Running rustfmt..."
	cd src/components/wasmcp-spin && cargo fmt
	cd src/sdk/wasmcp-rust && cargo fmt

lint-ts: ## Run TypeScript linter
	cd src/sdk/wasmcp-typescript && npm run lint

lint-ts-fix: ## Fix TypeScript lint issues
	cd src/sdk/wasmcp-typescript && npm run lint:fix

lint-all: lint-rust lint-ts ## Run all linters

lint-fix-all: ## Fix all lint and formatting issues (Rust and TypeScript)
	@echo "Fixing all lint and formatting issues..."
	@$(MAKE) lint-rust-fix
	@$(MAKE) lint-ts-fix
	@echo "✅ All lint and formatting issues fixed!"

# Build targets
build-gateway: ## Build wasmcp-spin
	cd src/components/wasmcp-spin && cargo clippy -- -D warnings && cargo component build --release

build-rust-sdk: ## Build wasmcp-rust
	cd src/sdk/wasmcp-rust && cargo clippy -- -D warnings && cargo build --release

build-ts-sdk: install-ts-deps ## Build wasmcp-typescript
	cd src/sdk/wasmcp-typescript && npm run lint && npm run build

build-all: build-gateway build-rust-sdk build-ts-sdk ## Build all components

# Test targets
test-gateway: ## Test wasmcp-spin
	cd src/components/wasmcp-spin && cargo test

test-rust-sdk: ## Test wasmcp-rust
	cd src/sdk/wasmcp-rust && cargo test

test-rust: test-gateway test-rust-sdk ## Run all Rust tests

test-ts: install-ts-deps ## Run TypeScript tests
	cd src/sdk/wasmcp-typescript && npm test

test-all: test-rust test-ts ## Run all tests

# CI targets
ci-setup: install-deps ## Setup CI environment

ci-build: ci-setup build-all ## CI build pipeline

ci-test: test-all ## CI test pipeline

ci: ci-build ci-test ## Run full CI pipeline

# Clean targets
clean: ## Clean all build artifacts
	cd src/components/wasmcp-spin && cargo clean
	cd src/sdk/wasmcp-rust && cargo clean
	cd src/sdk/wasmcp-typescript && rm -rf dist node_modules

# Release helper
show-versions: ## Show current versions
	@echo "Current versions:"
	@echo "  wasmcp-spin:  $$(grep 'wasmcp-spin = ' versions.toml | cut -d'"' -f2)"
	@echo "  wasmcp-rust:       $$(grep 'wasmcp-rust = ' versions.toml | cut -d'"' -f2)"
	@echo "  wasmcp-typescript: $$(grep 'wasmcp-typescript = ' versions.toml | cut -d'"' -f2)"
	@echo ""
	@echo "WIT packages:"
	@echo "  mcp:                $$(grep '^mcp = ' versions.toml | cut -d'"' -f2)"
	@echo "  mcp-gateway:        $$(grep '^mcp-gateway = ' versions.toml | cut -d'"' -f2)"

get-gateway-version: ## Get wasmcp-spin version
	@grep 'wasmcp-spin = ' versions.toml | cut -d'"' -f2

get-rust-sdk-version: ## Get wasmcp-rust version
	@grep 'wasmcp-rust = ' versions.toml | cut -d'"' -f2

get-ts-sdk-version: ## Get wasmcp-typescript version
	@grep 'wasmcp-typescript = ' versions.toml | cut -d'"' -f2

# Publishing targets
publish-gateway: ## Publish wasmcp-spin to ghcr.io
	@echo "Publishing wasmcp-spin..."
	@version=$$(grep 'wasmcp-spin = ' versions.toml | cut -d'"' -f2); \
	cd src/components/wasmcp-spin && \
	wkg oci push ghcr.io/fastertools/wasmcp-spin:$$version \
		--annotation "org.opencontainers.image.source=https://github.com/fastertools/wasmcp" \
		--annotation "org.opencontainers.image.description=WebAssembly server component for Spin" \
		--annotation "org.opencontainers.image.licenses=Apache-2.0" \
		target/wasm32-wasip1/release/wasmcp_spin.wasm && \
	wkg oci push ghcr.io/fastertools/wasmcp-spin:latest \
		--annotation "org.opencontainers.image.source=https://github.com/fastertools/wasmcp" \
		--annotation "org.opencontainers.image.description=WebAssembly server component for Spin" \
		--annotation "org.opencontainers.image.licenses=Apache-2.0" \
		target/wasm32-wasip1/release/wasmcp_spin.wasm
	@echo "✅ Published wasmcp-spin v$$(grep 'wasmcp-spin = ' versions.toml | cut -d'"' -f2)"

publish-rust-sdk: ## Publish wasmcp-rust to crates.io
	@echo "Publishing wasmcp-rust to crates.io..."
	cd src/sdk/wasmcp-rust && cargo publish
	@echo "✅ Published wasmcp v$$(make get-rust-sdk-version)"

publish-rust-sdk-dry: ## Dry run publish wasmcp-rust
	cd src/sdk/wasmcp-rust && cargo publish --dry-run

publish-ts-sdk: build-ts-sdk ## Publish wasmcp-typescript to npm
	@echo "Publishing wasmcp to npm..."
	cd src/sdk/wasmcp-typescript && npm publish --access public
	@echo "✅ Published wasmcp v$$(make get-ts-sdk-version)"

publish-ts-sdk-dry: ## Dry run publish wasmcp-typescript
	cd src/sdk/wasmcp-typescript && npm publish --dry-run --access public

publish-all: ## Publish all packages (use with caution!)
	@echo "⚠️  Publishing all packages..."
	@echo "This will publish:"
	@echo "  - wasmcp-spin v$$(make get-gateway-version) to ghcr.io"
	@echo "  - wasmcp v$$(make get-rust-sdk-version) to crates.io"
	@echo "  - wasmcp v$$(make get-ts-sdk-version) to npm"
	@echo ""
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read confirm
	@$(MAKE) publish-gateway
	@$(MAKE) publish-rust-sdk
	@$(MAKE) publish-ts-sdk
	@echo ""
	@echo "🎉 All packages published!"

publish-dry-run: ## Dry run all publishes
	@echo "Dry run for all packages:"
	@echo ""
	@echo "=== wasmcp-spin ==="
	@echo "Would publish v$$(make get-gateway-version) to ghcr.io"
	@echo ""
	@echo "=== wasmcp-rust ==="
	@$(MAKE) publish-rust-sdk-dry
	@echo ""
	@echo "=== wasmcp-typescript ==="
	@$(MAKE) publish-ts-sdk-dry

# Release workflow targets
release-patch: ## Full release workflow for patch version
	@echo "Starting patch release..."
	@$(MAKE) bump-all-patch
	@echo ""
	@echo "Changes made. Please:"
	@echo "1. Review: git diff"
	@echo "2. Commit: git commit -am 'chore: release patch version'"
	@echo "3. Tag and push:"
	@echo "   git tag wasmcp-spin-v$$(make get-gateway-version)"
	@echo "   git tag wasmcp-rust-v$$(make get-rust-sdk-version)"
	@echo "   git tag wasmcp-typescript-v$$(make get-ts-sdk-version)"
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