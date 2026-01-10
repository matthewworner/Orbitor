#!/bin/bash

# Texture Processing Script
# Converts raw downloaded textures to optimized formats for SceneKit/Metal

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW_DIR="$BASE_DIR/Assets/Raw/Textures"
OUTPUT_DIR="$BASE_DIR/Resources/Textures"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Texture Processing Pipeline${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check for required tools
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    local missing=0
    
    if ! command -v sips &> /dev/null; then
        echo -e "${RED}✗ sips not found (macOS built-in tool)${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ sips found${NC}"
    fi
    
    if ! command -v convert &> /dev/null; then
        echo -e "${YELLOW}⚠ ImageMagick not found (optional but recommended)${NC}"
        echo -e "  Install with: brew install imagemagick"
    else
        echo -e "${GREEN}✓ ImageMagick found${NC}"
    fi
    
    echo ""
    
    if [ $missing -eq 1 ]; then
        echo -e "${RED}Missing required dependencies. Please install and try again.${NC}"
        exit 1
    fi
}

# Process a single texture
process_texture() {
    local input="$1"
    local output="$2"
    local width="$3"
    local height="$4"
    local description="$5"
    
    echo -e "${YELLOW}Processing:${NC} $description"
    echo -e "${BLUE}Input:${NC} $input"
    echo -e "${BLUE}Output:${NC} $output (${width}x${height})"
    
    if [ ! -f "$input" ]; then
        echo -e "${RED}✗ Input file not found, skipping${NC}\n"
        return 1
    fi
    
    if [ -f "$output" ]; then
        echo -e "${GREEN}✓ Output already exists, skipping${NC}\n"
        return 0
    fi
    
    # Create output directory if needed
    mkdir -p "$(dirname "$output")"
    
    # Use ImageMagick if available (better quality), otherwise use sips
    if command -v convert &> /dev/null; then
        convert "$input" -resize "${width}x${height}!" -quality 95 "$output"
    else
        sips -z "$height" "$width" -s format jpeg -s formatOptions high "$input" --out "$output" > /dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        local size=$(du -h "$output" | cut -f1)
        echo -e "${GREEN}✓ Processed successfully (${size})${NC}\n"
        return 0
    else
        echo -e "${RED}✗ Processing failed${NC}\n"
        return 1
    fi
}

# Main processing
check_dependencies

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}PROCESSING 8K TEXTURES${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Earth Day
process_texture \
    "$RAW_DIR/8K/earth_day_raw.jpg" \
    "$OUTPUT_DIR/8K/earth_8k_day.jpg" \
    8192 4096 \
    "Earth - Blue Marble Day"

# Earth Night
process_texture \
    "$RAW_DIR/8K/earth_night_raw.jpg" \
    "$OUTPUT_DIR/8K/earth_8k_night.jpg" \
    8192 4096 \
    "Earth - Black Marble Night"

# Earth Clouds (PNG for transparency)
if [ -f "$RAW_DIR/8K/earth_clouds_raw.png" ]; then
    echo -e "${YELLOW}Processing:${NC} Earth Clouds (with alpha)"
    if command -v convert &> /dev/null; then
        convert "$RAW_DIR/8K/earth_clouds_raw.png" -resize "8192x4096!" "$OUTPUT_DIR/8K/earth_8k_clouds.png"
        echo -e "${GREEN}✓ Processed successfully${NC}\n"
    else
        cp "$RAW_DIR/8K/earth_clouds_raw.png" "$OUTPUT_DIR/8K/earth_8k_clouds.png"
        echo -e "${YELLOW}⚠ Copied without resizing (install ImageMagick for proper processing)${NC}\n"
    fi
fi

# Sun
process_texture \
    "$RAW_DIR/8K/sun_raw.jpg" \
    "$OUTPUT_DIR/8K/sun_8k.jpg" \
    8192 4096 \
    "Sun"

# Jupiter
process_texture \
    "$RAW_DIR/8K/jupiter_raw.jpg" \
    "$OUTPUT_DIR/8K/jupiter_8k.jpg" \
    8192 4096 \
    "Jupiter"

# Saturn
process_texture \
    "$RAW_DIR/8K/saturn_raw.jpg" \
    "$OUTPUT_DIR/8K/saturn_8k.jpg" \
    8192 4096 \
    "Saturn"

# Saturn Rings (16K, PNG for transparency)
if [ -f "$RAW_DIR/8K/saturn_rings_raw.png" ]; then
    echo -e "${YELLOW}Processing:${NC} Saturn Rings (16K with alpha)"
    if command -v convert &> /dev/null; then
        convert "$RAW_DIR/8K/saturn_rings_raw.png" -resize "16384x8192!" "$OUTPUT_DIR/8K/saturn_rings_16k.png"
        echo -e "${GREEN}✓ Processed successfully${NC}\n"
    else
        cp "$RAW_DIR/8K/saturn_rings_raw.png" "$OUTPUT_DIR/8K/saturn_rings_16k.png"
        echo -e "${YELLOW}⚠ Copied without resizing${NC}\n"
    fi
fi

# Starfield
process_texture \
    "$RAW_DIR/8K/starfield_raw.jpg" \
    "$OUTPUT_DIR/8K/starfield_8k.jpg" \
    8192 4096 \
    "Starfield Background"

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}SUMMARY${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Count processed files
processed_count=$(find "$OUTPUT_DIR/8K" -type f 2>/dev/null | wc -l | tr -d ' ')
total_size=$(du -sh "$OUTPUT_DIR/8K" 2>/dev/null | cut -f1 || echo "0B")

echo -e "${GREEN}✓ Processing complete${NC}"
echo -e "  Files processed: $processed_count"
echo -e "  Total size: $total_size"
echo -e "  Output directory: $OUTPUT_DIR/8K"
echo -e ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Verify textures in Preview or image viewer"
echo -e "  2. Import into Xcode project"
echo -e "  3. Use Xcode's texture compiler to convert to ASTC format"
echo -e "  4. Test in SceneKit with sphere geometry"
echo -e ""
echo -e "${YELLOW}Note:${NC} For optimal Metal performance, convert to ASTC format in Xcode:"
echo -e "  - Select texture in Xcode"
echo -e "  - File Inspector → Texture → Compression: ASTC"
echo -e "  - This will reduce file size by 70-80% with minimal quality loss\n"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Texture Processing Complete${NC}"
echo -e "${BLUE}========================================${NC}\n"
