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
    ARGS.insert(2,"tcp://127.0.0.1:2475")
    ARGS.insert(2,"--connection")

ARGS[0] = "podman.orig"
  
os.execvp(ARGS[0], ARGS)
