#! /usr/bin/env python3

import os
import sys

ARGS = sys.argv

try:
    ARGS.remove("--interactive")
    ARGS.remove("--user=root")
except ValueError:
    pass

ARGS[0] = "podman.orig"
    
os.execvp(ARGS[0], ARGS)
