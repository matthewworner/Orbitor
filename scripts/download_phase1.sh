#!/bin/bash

# Asset Download Script - Phase 1 (MVP Critical Assets)
# Nature's Calm vs. Humanity's Noise Screensaver
# Downloads essential textures and data for initial development

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$BASE_DIR/Resources"
RAW_DIR="$BASE_DIR/Assets/Raw"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Phase 1 Asset Download - MVP Critical${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Create directories if they don't exist
mkdir -p "$RAW_DIR/Textures/8K"
mkdir -p "$RAW_DIR/Textures/4K"
mkdir -p "$RAW_DIR/Audio"
mkdir -p "$RAW_DIR/Data"

# Function to download with progress
download_file() {
    local url="$1"
    local output="$2"
    local description="$3"
    
    echo -e "${YELLOW}Downloading:${NC} $description"
    echo -e "${BLUE}URL:${NC} $url"
    echo -e "${BLUE}Output:${NC} $output"
    
    if [ -f "$output" ]; then
        echo -e "${GREEN}✓ File already exists, skipping${NC}\n"
        return 0
    fi
    
    if curl -L --progress-bar -o "$output" "$url"; then
        echo -e "${GREEN}✓ Download complete${NC}\n"
        return 0
    else
        echo -e "${RED}✗ Download failed${NC}\n"
        return 1
    fi
}

# ============================================
# PLANETARY TEXTURES (8K)
# ============================================

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}PLANETARY TEXTURES (8K)${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Earth - Blue Marble (Day)
# Note: NASA's highest resolution is 21600x10800, we'll download and resize
download_file \
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73909/world.topo.bathy.200412.3x5400x2700.jpg" \
    "$RAW_DIR/Textures/8K/earth_day_raw.jpg" \
    "Earth - Blue Marble Day (5400x2700 - will upscale to 8K)"

# Earth - Black Marble (Night)
download_file \
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/144000/144898/BlackMarble_2016_3km.jpg" \
    "$RAW_DIR/Textures/8K/earth_night_raw.jpg" \
    "Earth - Black Marble Night Lights"

# Sun
# Using Solar System Scope textures (free for non-commercial)
echo -e "${YELLOW}Note:${NC} Sun texture requires manual download from Solar System Scope"
echo -e "${BLUE}URL:${NC} https://www.solarsystemscope.com/textures/"
echo -e "${BLUE}File:${NC} Download '2k_sun.jpg' and place in $RAW_DIR/Textures/8K/sun_raw.jpg\n"

# Jupiter
echo -e "${YELLOW}Note:${NC} Jupiter texture requires processing from Björn Jónsson's maps"
echo -e "${BLUE}URL:${NC} http://bjj.mmedia.is/data/jupiter/"
echo -e "${BLUE}Instructions:${NC} Download highest resolution available\n"

# Saturn
echo -e "${YELLOW}Note:${NC} Saturn texture requires manual download"
echo -e "${BLUE}URL:${NC} http://bjj.mmedia.is/data/s_polar/"
echo -e "${BLUE}Instructions:${NC} Download highest resolution available\n"

# Saturn Rings
echo -e "${YELLOW}Note:${NC} Saturn rings require manual download"
echo -e "${BLUE}URL:${NC} https://www.solarsystemscope.com/textures/"
echo -e "${BLUE}File:${NC} Download '2k_saturn_ring_alpha.png' and upscale to 16K\n"

# ============================================
# TLE DATA (Satellite Orbital Elements)
# ============================================

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}ORBITAL DATA (TLE)${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Active Satellites
download_file \
    "https://celestrak.org/NORAD/elements/gp.php?GROUP=active&FORMAT=tle" \
    "$RAW_DIR/Data/active_satellites.tle" \
    "Active Satellites TLE Data (~11,000 objects)"

# Debris
download_file \
    "https://celestrak.org/NORAD/elements/gp.php?GROUP=debris&FORMAT=tle" \
    "$RAW_DIR/Data/debris.tle" \
    "Space Debris TLE Data (~29,000 objects)"

# Starlink (for recent launch visualization)
download_file \
    "https://celestrak.org/NORAD/elements/gp.php?GROUP=starlink&FORMAT=tle" \
    "$RAW_DIR/Data/starlink.tle" \
    "Starlink Constellation TLE Data"

# ISS (for highlighting)
download_file \
    "https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=tle" \
    "$RAW_DIR/Data/iss.tle" \
    "International Space Station TLE Data"

# ============================================
# AUDIO ASSETS (NASA Public Domain)
# ============================================

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}AUDIO ASSETS${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Note:${NC} NASA audio files require manual download and processing"
echo -e "${BLUE}Primary Source:${NC} https://voyager.jpl.nasa.gov/audio/"
echo -e "${BLUE}Secondary:${NC} https://www.nasa.gov/connect/sounds/\n"

echo -e "Required Phase 1 Audio Files:"
echo -e "  1. Solar wind plasma waves (Voyager) → solar_wind_loop_10min.mp3"
echo -e "  2. Jupiter auroral emissions (Juno) → jupiter_auroral_60sec.mp3"
echo -e "  3. Radio static (create from mission comms) → radio_static_layer1.mp3\n"

# ============================================
# STARFIELD BACKGROUND
# ============================================

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}STARFIELD BACKGROUND${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Note:${NC} Starfield requires manual creation or download"
echo -e "${BLUE}Option 1:${NC} ESA Gaia Star Map - https://www.cosmos.esa.int/web/gaia/data-release-3"
echo -e "${BLUE}Option 2:${NC} Generate procedurally in code"
echo -e "${BLUE}Option 3:${NC} Use Hubble Deep Field - https://hubblesite.org/contents/media/images/\n"

# ============================================
# SUMMARY
# ============================================

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}DOWNLOAD SUMMARY${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${GREEN}✓ Automated Downloads Complete${NC}"
echo -e "  - Earth textures (day/night)"
echo -e "  - TLE orbital data (active satellites, debris, Starlink, ISS)"
echo -e ""
echo -e "${YELLOW}⚠ Manual Downloads Required${NC}"
echo -e "  - Sun texture (Solar System Scope)"
echo -e "  - Jupiter texture (Björn Jónsson)"
echo -e "  - Saturn texture + rings (Björn Jónsson / Solar System Scope)"
echo -e "  - Audio files (NASA Voyager, Juno)"
echo -e "  - Starfield background"
echo -e ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Complete manual downloads (see URLs above)"
echo -e "  2. Run texture processing script: ./scripts/process_textures.sh"
echo -e "  3. Run audio processing script: ./scripts/process_audio.sh"
echo -e "  4. Verify all assets: ./scripts/verify_assets.sh"
echo -e ""
echo -e "${BLUE}Raw assets location:${NC} $RAW_DIR"
echo -e "${BLUE}Processed assets will go to:${NC} $RESOURCES_DIR\n"

# Create a checklist file
cat > "$BASE_DIR/DOWNLOAD_STATUS.md" << 'EOF'
# Download Status - Phase 1 Assets

## Automated Downloads ✅
- [x] Earth - Blue Marble Day texture
- [x] Earth - Black Marble Night texture
- [x] Active Satellites TLE data
- [x] Space Debris TLE data
- [x] Starlink TLE data
- [x] ISS TLE data

## Manual Downloads Required ⬜

### Textures
- [ ] Sun texture (8K)
  - Source: https://www.solarsystemscope.com/textures/
  - File: Download '2k_sun.jpg' or higher
  - Save as: `Assets/Raw/Textures/8K/sun_raw.jpg`

- [ ] Jupiter texture (8K)
  - Source: http://bjj.mmedia.is/data/jupiter/
  - File: Download highest resolution cylindrical map
  - Save as: `Assets/Raw/Textures/8K/jupiter_raw.jpg`

- [ ] Saturn texture (8K)
  - Source: http://bjj.mmedia.is/data/s_polar/
  - File: Download highest resolution map
  - Save as: `Assets/Raw/Textures/8K/saturn_raw.jpg`

- [ ] Saturn Rings (16K)
  - Source: https://www.solarsystemscope.com/textures/
  - File: Download '2k_saturn_ring_alpha.png' or higher
  - Save as: `Assets/Raw/Textures/8K/saturn_rings_raw.png`

- [ ] Earth Clouds (8K with alpha)
  - Source: https://www.solarsystemscope.com/textures/
  - File: Download '2k_earth_clouds.png' or higher
  - Save as: `Assets/Raw/Textures/8K/earth_clouds_raw.png`

### Audio
- [ ] Solar wind ambient loop
  - Source: https://voyager.jpl.nasa.gov/audio/
  - File: Download plasma wave recordings
  - Process: Create 10-minute seamless loop
  - Save as: `Assets/Raw/Audio/solar_wind_raw.wav`

- [ ] Jupiter auroral emissions
  - Source: https://www.nasa.gov/juno/multimedia/sounds/
  - File: Download Jupiter sounds
  - Process: Create 60-second loop
  - Save as: `Assets/Raw/Audio/jupiter_auroral_raw.wav`

- [ ] Radio static (human noise)
  - Source: Create from NASA mission communications
  - Process: Mix various radio frequencies
  - Save as: `Assets/Raw/Audio/radio_static_raw.wav`

### Starfield
- [ ] Starfield background (8K)
  - Option 1: ESA Gaia star map
  - Option 2: Generate procedurally
  - Option 3: Hubble Deep Field composite
  - Save as: `Assets/Raw/Textures/8K/starfield_raw.jpg`

## Processing Status
- [ ] Textures processed and compressed (ASTC)
- [ ] Audio normalized and looped
- [ ] TLE data parsed to JSON
- [ ] All assets verified and tested

**Last Updated:** Run `./scripts/download_phase1.sh` to update
EOF

echo -e "${GREEN}✓ Created DOWNLOAD_STATUS.md checklist${NC}\n"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Phase 1 Download Script Complete${NC}"
echo -e "${BLUE}========================================${NC}\n"
