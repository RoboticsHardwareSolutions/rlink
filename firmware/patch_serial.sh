#!/bin/bash
# Script to generate a new serial number and patch firmware
# Uses xxd and standard Unix utilities

set -e


if [ $# -lt 1 ]; then
  echo "Usage: $0 <input_firmware> [output_firmware] [serial (hex, e.g. 2E12345)]"
  exit 1
fi

INPUT="$1"
OUTPUT="${2:-${INPUT%.bin}_patched.bin}"
SERIAL_HEX=""
if [ -n "$3" ]; then
  SERIAL_HEX="$3"
  # Remove possible 0x prefix
  SERIAL_HEX="${SERIAL_HEX#0x}"
  # Check that it starts with 2E and is 7 hex digits
  if ! [[ "$SERIAL_HEX" =~ ^2E[0-9A-Fa-f]{5}$ ]]; then
    echo "Serial must be in format 2EXXXXX (hex)"
    exit 2
  fi
else
  # Generate random serial 0x2EXXXXX
  RAND_HEX=$(printf "%05X" $((RANDOM * RANDOM % 0x100000)))
  SERIAL_HEX="2E${RAND_HEX}"
fi

SERIAL_LE_BIN=$(printf "%08x" 0x$SERIAL_HEX | sed 's/../& /g' | awk '{print $4$3$2$1}')
SERIAL_BYTES=$(echo $SERIAL_LE_BIN | xxd -r -p | xxd -p)


 # Offset 0xF800 (63488)
BYTE_OFFSET=63488

cp "$INPUT" "$OUTPUT"
echo "$SERIAL_BYTES" | xxd -r -p | dd of="$OUTPUT" bs=1 seek=$BYTE_OFFSET count=4 conv=notrunc 2>/dev/null

SERIAL_OUT=$(echo $SERIAL_HEX | sed 's/\(..\)/\1 /g')
echo "Patched serial: 0x$SERIAL_HEX ($SERIAL_OUT) at offset $BYTE_OFFSET"
echo "Output: $OUTPUT"
