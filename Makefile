STYLUA ?= stylua
LUALS ?= lua-language-server

CHECK_GLOB = --glob '**/*.lua' --glob '!Libs/**'

.PHONY: init check check-format check-luals fmt release-check

init:
	./Tools/dev_setup.sh

check: check-format check-luals

check-format:
	$(STYLUA) --check $(CHECK_GLOB) .

check-luals:
	$(LUALS) --check=. --checklevel=Warning --check_format=pretty --configpath=.luarc.json --metapath=.lls/meta --logpath=.lls/log

fmt:
	$(STYLUA) $(CHECK_GLOB) .

release-check:
	./Tools/release_check.sh
