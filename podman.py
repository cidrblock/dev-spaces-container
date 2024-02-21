#! /usr/bin/env python3

import os
import sys

ARGS = sys.argv
SUPPORTED = ("run", "ps", "exec", "cp", "logs", "inspect", "kill", "rm", "wait", "stop", "start")

try:
    ARGS.remove("--interactive")
    ARGS.remove("--user=root")
except ValueError:
    pass

if ARGS[1] in SUPPORTED:
    os.environ["CONTIANER_HOST"] = "tcp://127.0.0.1:2475"
else:
    os.environ.pop("CONTIANER_HOST", None)

ARGS[0] = "podman.orig"

os.execvp(ARGS[0], ARGS)
