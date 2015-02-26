.PHONY:
	default \
	run-reemission-generator

default:

test-vectors/reemission/001.noparens.txt: | run-reemission-generator
test-vectors/reemission/001.parens.txt: | run-reemission-generator

run-reemission-generator:
	mkdir -p test-vectors/reemission
	util/generate-reemitter-inputs \
		4>test-vectors/reemission/001.noparens.txt \
		5>test-vectors/reemission/001.parens.txt
