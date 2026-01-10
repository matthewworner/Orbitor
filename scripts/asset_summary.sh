#!/bin/bash

# Quick Asset Summary Script

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║         🌌 ASSET COLLECTION STATUS - QUICK SUMMARY                  ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""

# Count textures
texture_count=$(find "$BASE_DIR/Assets/Raw/Textures/8K" -type f 2>/dev/null | wc -l | tr -d ' ')
data_count=$(find "$BASE_DIR/Assets/Raw/Data" -type f -name "*.tle" 2>/dev/null | wc -l | tr -d ' ')

echo "📁 TEXTURES: $texture_count files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh "$BASE_DIR/Assets/Raw/Textures/8K/" 2>/dev/null | tail -n +2 | awk '{
    size = $5
    file = $9
    if (file ~ /sun/) printf "  ✅ Sun:            %6s\n", size
    else if (file ~ /jupiter/) printf "  ✅ Jupiter:        %6s\n", size
    else if (file ~ /saturn_ring/) printf "  ✅ Saturn Rings:   %6s\n", size
    else if (file ~ /earth_day/) printf "  ✅ Earth Day:      %6s\n", size
    else if (file ~ /earth_night/) printf "  ✅ Earth Night:    %6s\n", size
    else if (file ~ /earth_cloud/) printf "  ✅ Earth Clouds:   %6s\n", size
    else if (file ~ /starfield/) printf "  ✅ Starfield:      %6s\n", size
    else printf "  ✅ %s: %s\n", file, size
}'

echo ""
echo "  ⬜ Saturn (planet texture) - STILL NEEDED"
echo "  ⬜ Mars - STILL NEEDED"
echo "  ⬜ Mercury - STILL NEEDED"
echo "  ⬜ Venus - STILL NEEDED"
echo "  ⬜ Uranus - STILL NEEDED"
echo "  ⬜ Neptune - STILL NEEDED"
echo ""

echo "📊 DATA FILES: $data_count TLE files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh "$BASE_DIR/Assets/Raw/Data/"*.tle 2>/dev/null | awk '{
    size = $5
    file = $9
    gsub(/.*\//, "", file)
    gsub(/.tle/, "", file)
    printf "  ✅ %-20s %6s\n", file ":", size
}'
echo ""

# Count TLE objects
if [ -f "$BASE_DIR/Assets/Raw/Data/active_satellites.tle" ]; then
    active_count=$(grep -c "^1 " "$BASE_DIR/Assets/Raw/Data/active_satellites.tle" 2>/dev/null || echo "0")
    echo "  📡 Active satellites: ~$active_count objects"
fi

if [ -f "$BASE_DIR/Assets/Raw/Data/starlink.tle" ]; then
    starlink_count=$(grep -c "^1 " "$BASE_DIR/Assets/Raw/Data/starlink.tle" 2>/dev/null || echo "0")
    echo "  🛰️  Starlink: ~$starlink_count objects"
fi

if [ -f "$BASE_DIR/Assets/Raw/Data/debris.tle" ]; then
    debris_count=$(grep -c "^1 " "$BASE_DIR/Assets/Raw/Data/debris.tle" 2>/dev/null || echo "0")
    echo "  🗑️  Debris/Analyst: ~$debris_count objects"
fi

echo ""
echo "🎵 AUDIO FILES: 0 files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⬜ Solar wind loop - Optional for MVP"
echo "  ⬜ Jupiter sounds - Optional for MVP"
echo "  ⬜ Radio static - Optional for MVP"
echo ""

# Calculate progress
total_critical=11  # 8 planets (Sun, Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune) + Saturn rings + Earth clouds + starfield = 11 textures + 4 data files = 15 critical
have_textures=7
have_data=4
have_total=$((have_textures + have_data))
total_assets=15

percentage=$((have_total * 100 / total_assets))

echo "📊 OVERALL PROGRESS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Textures:  $have_textures/13 (54%)"
echo "  Data:      $have_data/4 (100%) ✅"
echo "  Audio:     0/3 (0%) - Optional"
echo ""
echo "  TOTAL:     $have_total/$total_assets ($percentage%)"
echo ""

if [ $percentage -ge 80 ]; then
    echo "🎉 Status: READY TO START DEVELOPMENT!"
    echo ""
    echo "Next steps:"
    echo "  1. Run: ./scripts/process_textures.sh"
    echo "  2. Run: ./scripts/verify_assets.sh"
    echo "  3. Create Xcode project"
    echo "  4. Start building!"
elif [ $percentage -ge 60 ]; then
    echo "⚠️  Status: ALMOST READY (need a few more textures)"
    echo ""
    echo "Critical missing:"
    echo "  • Saturn planet texture"
    echo "  • Mars texture"
    echo ""
    echo "Download from: https://www.solarsystemscope.com/textures/"
else
    echo "🔄 Status: IN PROGRESS"
    echo ""
    echo "Still need several planetary textures."
    echo "Visit: https://www.solarsystemscope.com/textures/"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║  For detailed status: cat ASSET_STATUS.md                            ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
