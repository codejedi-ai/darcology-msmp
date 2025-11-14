#!/usr/bin/env python3
"""
RCON Client Module for Minecraft Server Control
Part of the Flask Integration package (future addon)

This module provides functions to execute Minecraft commands via RCON.
It can be used as a standalone script or imported as a module by the Flask server.

Requirements: pip install mcrcon

Setup:
1. Enable RCON in server.properties:
   enable-rcon=true
   rcon.port=25575
   rcon.password=your_secure_password

2. Set environment variables:
   export RCON_HOST=localhost  # or minecraft-server container IP (172.25.0.10)
   export RCON_PORT=25575
   export RCON_PASSWORD=your_secure_password

Usage as script:
    python3 execute-command-rcon.py "say Hello World"

Usage as module:
    from execute_command_rcon import execute_command
    response = execute_command("say Hello World")
"""

import os
import sys

try:
    import mcrcon
except ImportError:
    print("Error: mcrcon not installed. Install with: pip install mcrcon")
    sys.exit(1)


def execute_command(command: str, silent: bool = False):
    """
    Execute a Minecraft command via RCON
    
    Args:
        command: The Minecraft command to execute (e.g., "say Hello World")
        silent: If True, don't print output (useful when used as module)
    
    Returns:
        str: The response from the Minecraft server
    
    Raises:
        ValueError: If RCON_PASSWORD is not set
        Exception: If RCON connection or command execution fails
    """
    rcon_host = os.getenv('RCON_HOST', 'localhost')
    rcon_port = int(os.getenv('RCON_PORT', '25575'))
    rcon_password = os.getenv('RCON_PASSWORD', '')
    
    if not rcon_password:
        error_msg = "Error: RCON_PASSWORD environment variable not set"
        if not silent:
            print(error_msg)
            sys.exit(1)
        raise ValueError(error_msg)
    
    try:
        with mcrcon.MCRcon(rcon_host, rcon_password, port=rcon_port) as mcr:
            response = mcr.command(command)
            if not silent:
                print(f"Command: {command}")
                print(f"Response: {response}")
            return response
    except Exception as e:
        error_msg = f"Error executing command: {e}"
        if not silent:
            print(error_msg)
            sys.exit(1)
        raise Exception(error_msg)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 execute-command-rcon.py \"<minecraft command>\"")
        print("Example: python3 execute-command-rcon.py \"say Hello World\"")
        sys.exit(1)
    
    command = sys.argv[1]
    execute_command(command)

