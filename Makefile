STYLUA ?= stylua
LUALS ?= lua-language-server

CHECK_GLOB = --glob '**/*.lua' --glob '!Libs/**'

.PHONY: check check-format check-luals fmt

check: check-format check-luals

check-format:
	$(STYLUA) --check $(CHECK_GLOB) .

check-luals:
	$(LUALS) --check=. --checklevel=Warning --check_format=pretty --configpath=.luarc.json --metapath=.lls/meta --logpath=.lls/log

fmt:
	$(STYLUA) $(CHECK_GLOB) .
