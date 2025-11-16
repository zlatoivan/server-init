SHELL := /bin/bash
DIR ?= .

.PHONY: compose-up
compose-up:
	docker compose up -d --build

.PHONY: static clean-svg dot-svg mmd-svg
static: clean-svg dot-svg mmd-svg

clean-svg:
	find $(DIR) -maxdepth 1 -type f -name '*.svg' -print -delete

dot-svg:
	@fish -c 'test -f ~/.config/fish/config.fish; and source ~/.config/fish/config.fish; \
		functions -q gdot; or begin; echo "ERROR: function gdot not found"; exit 1; end; \
		for f in (find '$(DIR)' -maxdepth 1 -type f -name "*.dot"); \
			set base (string replace -r "\.dot\$$" "" -- "$$f"); \
			gdot "$$base"; \
		end'

mmd-svg:
	@fish -c 'test -f ~/.config/fish/config.fish; and source ~/.config/fish/config.fish; \
		functions -q gmmd; or begin; echo "ERROR: function gmmd not found"; exit 1; end; \
		for f in (find '$(DIR)' -maxdepth 1 -type f \( -name "*.mmd" -o -name "*.mermaid" \)); \
			set base (string replace -r "\.(mmd|mermaid)\$$" "" -- "$$f"); \
			gmmd "$$base"; \
		end'