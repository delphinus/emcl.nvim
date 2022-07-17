TEST_DIR=lua/emcl/tests/
MINIMAL_LUA=${TEST_DIR}minimal.lua
.PHONY: test
test:
	nvim --headless --noplugin -i NONE -u ${MINIMAL_LUA} -c "PlenaryBustedDirectory ${TEST_DIR} {minimal_init = '${MINIMAL_LUA}'}"
