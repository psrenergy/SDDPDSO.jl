#!/bin/bash

unset XPRESSDIR
unset XPAUTH_PATH
export XPRESS_JL_NO_DEPS_ERROR=1
export XPRESS_JL_NO_AUTO_INIT=1
export XPRESS_JL_SKIP_LIB_CHECK=1

julia --project=revise --load=revise\revise_load_script.jl