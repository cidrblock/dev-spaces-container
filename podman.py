#! /usr/bin/env python3

import os
import sys

ARGS = sys.argv

ARGS.remove("--interactive")
ARGS.remove("--user=root")

os.execvp(ARGS[0], ARGS)
