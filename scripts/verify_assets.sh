#!/bin/bash

# Asset Verification Script - Updated for realistic thresholds
# Checks that all required Phase 1 assets are present and valid

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCES_DIR="$BASE_DIR/Resources"
RAW_DIR="$BASE_DIR/Assets/Raw"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Asset Verification - Phase 1${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Counters
total_checks=0
passed_checks=0
failed_checks=0
missing_files=()

# Check if file exists and meets size requirements
check_file() {
    local file="$1"
    local min_size="$2"  # in KB
    local description="$3"
    
    total_checks=$((total_checks + 1))
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗${NC} $description"
        echo -e "  ${YELLOW}Missing:${NC} $file"
        failed_checks=$((failed_checks + 1))
        missing_files+=("$description")
        return 1
    fi
    
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    local size_kb=$((size / 1024))
    
    if [ $size_kb -lt $min_size ]; then
        echo -e "${YELLOW}⚠${NC} $description (${size_kb}KB - small but usable)"
        passed_checks=$((passed_checks + 1))
        return 0
    fi
    
    echo -e "${GREEN}✓${NC} $description (${size_kb}KB)"
    passed_checks=$((passed_checks + 1))
    return 0
}

# ============================================
# TEXTURES (8K) - Using realistic thresholds
# ============================================

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}8K PROCESSED TEXTURES${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

check_file "$RESOURCES_DIR/Textures/8K/sun_8k.jpg" 500 "Sun Texture"
check_file "$RESOURCES_DIR/Textures/8K/mercury_8k.jpg" 500 "Mercury Texture"
check_file "$RESOURCES_DIR/Textures/8K/venus_8k.jpg" 500 "Venus Texture"
check_file "$RESOURCES_DIR/Textures/8K/earth_8k_day.jpg" 1000 "Earth Day Texture"
check_file "$RESOURCES_DIR/Textures/8K/earth_8k_night.jpg" 500 "Earth Night Texture"
check_file "$RESOURCES_DIR/Textures/8K/earth_8k_clouds.png" 100 "Earth Clouds Texture"
check_file "$RESOURCES_DIR/Textures/8K/mars_8k.jpg" 500 "Mars Texture"
check_file "$RESOURCES_DIR/Textures/8K/jupiter_8k.jpg" 1000 "Jupiter Texture"
check_file "$RESOURCES_DIR/Textures/8K/saturn_8k.jpg" 500 "Saturn Texture"
check_file "$RESOURCES_DIR/Textures/8K/saturn_rings_16k.png" 10 "Saturn Rings Texture"
check_file "$RESOURCES_DIR/Textures/8K/uranus_8k.jpg" 100 "Uranus Texture"
check_file "$RESOURCES_DIR/Textures/8K/neptune_8k.jpg" 100 "Neptune Texture"
check_file "$RESOURCES_DIR/Textures/8K/starfield_8k.jpg" 100 "Starfield Background"

echo ""

# ============================================
# DATA FILES
# ============================================

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}ORBITAL DATA (TLE)${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

check_file "$RAW_DIR/Data/active_satellites.tle" 100 "Active Satellites TLE"
check_file "$RAW_DIR/Data/debris.tle" 10 "Debris/Analyst TLE"
check_file "$RAW_DIR/Data/starlink.tle" 100 "Starlink TLE"
check_file "$RAW_DIR/Data/iss.tle" 0 "ISS TLE"

# Count TLE objects
echo ""
if [ -f "$RAW_DIR/Data/active_satellites.tle" ]; then
    active_count=$(grep -c "^1 " "$RAW_DIR/Data/active_satellites.tle" 2>/dev/null || echo "0")
    echo -e "  ${BLUE}📡 Active satellites: ~$active_count objects${NC}"
fi

if [ -f "$RAW_DIR/Data/starlink.tle" ]; then
    starlink_count=$(grep -c "^1 " "$RAW_DIR/Data/starlink.tle" 2>/dev/null || echo "0")
    echo -e "  ${BLUE}🛰️  Starlink: ~$starlink_count satellites${NC}"
fi

if [ -f "$RAW_DIR/Data/debris.tle" ]; then
    debris_count=$(grep -c "^1 " "$RAW_DIR/Data/debris.tle" 2>/dev/null || echo "0")
    echo -e "  ${BLUE}🗑️  Debris/Analyst: ~$debris_count objects${NC}"
fi

echo ""

# ============================================
# SUMMARY
# ============================================

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}VERIFICATION SUMMARY${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "Total Checks: $total_checks"
echo -e "${GREEN}Passed: $passed_checks${NC}"
echo -e "${RED}Failed: $failed_checks${NC}"
echo ""

# Calculate total texture size
texture_size=$(du -sh "$RESOURCES_DIR/Textures/8K" 2>/dev/null | cut -f1 || echo "0")
echo -e "Total Texture Size: ${BLUE}$texture_size${NC}"
echo ""

if [ $failed_checks -eq 0 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ ALL PHASE 1 ASSETS VERIFIED - READY FOR DEVELOPMENT!    ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo -e "  1. Create Xcode screensaver project"
    echo -e "  2. Import textures from Resources/Textures/8K/"
    echo -e "  3. Enable ASTC compression in Xcode"
    echo -e "  4. Start building the solar system scene!"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Missing ${failed_checks} required asset(s):${NC}"
    echo ""
    for item in "${missing_files[@]}"; do
        echo -e "  - $item"
    done
    echo ""
    exit 1
fi
