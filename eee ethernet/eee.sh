#!/bin/bash

# Disable Energy-Efficient Ethernet (EEE) on enp13s0f0
sudo ethtool --set-eee enp13s0f0 eee off