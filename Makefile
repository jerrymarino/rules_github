# This Makefile is used for testing, only

test: tools/bazelwrapper
	tools/bazelwrapper build \
		@ripgrep//:* \
		@build_bazel_rules_swift//:* \
		@xchammer//:*

tools/bazelwrapper:
	mkdir -p tools
	curl \
		https://github.com/pinterest/xchammer/blob/master/tools/bazelwrapper
		-o tools/bazelwrapper
	chmod +x tools/bazelwrapper

# Dev utilities
get_example: OWNER=BurntSushi
get_example: NAME=ripgrep
get_example:
	curl \
	   	https://api.github.com/repos/$(OWNER)/$(NAME)/releases \
		-o releases.json

