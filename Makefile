all: docs

docs: contrib/ocloak.1

%.1: %.1.scd
	scdoc < $^ > $@
