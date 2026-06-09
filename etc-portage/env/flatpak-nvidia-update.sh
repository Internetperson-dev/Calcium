#!/bin/bash
# Run Flatpak update for NVIDIA runtime after nvidia-drivers upgrade
flatpak update --assumeyes org.freedesktop.Platform.GL.nvidia
