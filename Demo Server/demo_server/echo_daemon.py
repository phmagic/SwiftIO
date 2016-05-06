#!/usr/bin/env python3.5

# This isn't used.

import daemon

from echo_server import main

with daemon.DaemonContext():
    main()