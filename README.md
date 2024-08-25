# Cache Controller Project

## Overview

This project implements a basic cache controller for a hypothetical computer system. The cache controller interacts with a CPU, local SRAM memory, and main memory (SDRAM) to manage data access and storage.

## Key Features

- 256 byte cache organized into 8 blocks of 32 bytes each
- Handles CPU read and write requests 
- Implements cache hit and miss logic
- Manages data transfers between cache and main memory
- Tracks dirty and valid bits for cache blocks

## Components

- Cache Controller (main logic)
- CPU (transaction generator)  
- SRAM (local cache memory)
- SDRAM Controller (main memory interface)

## Implementation Details

- Developed using VHDL in Xilinx ISE
- Targeted for Xilinx Spartan-3E FPGA
- Uses BlockRAM for cache memory

## Key Files

- `CacheController.vhd` - Main cache controller logic
- `CPU_gen.vhd` - CPU transaction generator 
- `SDRAMController.vhd` - SDRAM controller interface

## Performance Metrics

The project measures:

- Hit/miss determination time
- Data access time 
- Block replacement time
- Cache hit time
- Cache miss penalties
