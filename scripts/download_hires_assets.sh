#!/bin/bash

# Target Directories
TEXTURE_DIR="NatureVsNoise/NatureVsNoise/Resources/Textures/8K"
AUDIO_DIR="NatureVsNoise/NatureVsNoise/Resources/Audio"
mkdir -p "$TEXTURE_DIR"
mkdir -p "$AUDIO_DIR/Ambient"
mkdir -p "$AUDIO_DIR/Planetary"

echo "🪐 Starting COMPREHENSIVE Asset Download..."
echo "📍 Texture Target: $TEXTURE_DIR"
echo "📍 Audio Target: $AUDIO_DIR"

# Helper function with size check
download_texture() {
    name=$1
    url=$2
    output="$TEXTURE_DIR/$name"
    echo "⬇️  Downloading Texture: $name..."
    
    # Try 8k download
    curl -L -f -s -o "$output" "$url"
    
    # Check if file exists and is > 1MB (min size for decent texture)
    if [ -f "$output" ]; then
        filesize=$(stat -f%z "$output")
        if [ $filesize -gt 1000000 ]; then
             echo "✅ Saved $name ($(du -h "$output" | cut -f1))"
        else
             echo "⚠️  Warning: $name is too small ($filesize bytes). Likely a 404/redirect."
             rm "$output" 
        fi
    else
        echo "❌ Failed to download $name"
    fi
}

download_audio() {
    name=$1
    url=$2
    folder=$3
    output="$AUDIO_DIR/$folder/$name"
    echo "🎵 Downloading Audio: $name..."
    curl -L -f -s -o "$output" "$url"
    if [ $? -eq 0 ]; then
        echo "✅ Saved $name"
    else
        echo "❌ Failed to download audio $name"
    fi
}

echo "--- 1. PLANETARY TEXTURES (Solar System Scope) ---"

# Earth
download_texture "earth_8k_day.jpg" "https://www.solarsystemscope.com/textures/download/8k_earth_daymap.jpg"
download_texture "earth_8k_night.jpg" "https://www.solarsystemscope.com/textures/download/8k_earth_nightmap.jpg"
download_texture "earth_8k_clouds.jpg" "https://www.solarsystemscope.com/textures/download/8k_earth_clouds.jpg"

# Moon
download_texture "moon_8k.jpg" "https://www.solarsystemscope.com/textures/download/8k_moon.jpg"

# Mars
download_texture "mars_8k.jpg" "https://www.solarsystemscope.com/textures/download/8k_mars.jpg"

# Mercury
download_texture "mercury_8k.jpg" "https://www.solarsystemscope.com/textures/download/8k_mercury.jpg"

# Venus
download_texture "venus_8k_surface.jpg" "https://www.solarsystemscope.com/textures/download/8k_venus_surface.jpg"
download_texture "venus_8k_atmosphere.jpg" "https://www.solarsystemscope.com/textures/download/8k_venus_atmosphere.jpg"

# Jupiter
download_texture "jupiter_8k.jpg" "https://www.solarsystemscope.com/textures/download/8k_jupiter.jpg"

# Saturn
download_texture "saturn_8k.jpg" "https://www.solarsystemscope.com/textures/download/8k_saturn.jpg"
# Note: SSS Ring is usually '8k_saturn_ring_alpha.png'
download_texture "saturn_rings_8k.png" "https://www.solarsystemscope.com/textures/download/8k_saturn_ring_alpha.png"

# Uranus
download_texture "uranus_2k.jpg" "https://www.solarsystemscope.com/textures/download/2k_uranus.jpg" 

# Neptune
download_texture "neptune_2k.jpg" "https://www.solarsystemscope.com/textures/download/2k_neptune.jpg"

# Sun
download_texture "sun_8k.jpg" "https://www.solarsystemscope.com/textures/download/8k_sun.jpg"

# Deep Space
download_texture "starfield_8k.jpg" "https://www.solarsystemscope.com/textures/download/8k_stars_milky_way.jpg"

echo "--- 2. MOON TEXTURES (2K Fallback common) ---"
# SSS only provides 2k for some moons often
download_texture "haumea_2k.jpg" "https://www.solarsystemscope.com/textures/download/2k_haumea_fictional.jpg" 
# (Others generic)

echo "--- 3. AUDIO ASSETS (Direct Links) ---"
# Solar Wind
download_audio "solar_wind_preview.mp3" "https://audio-previews.elements.envatousercontent.com/files/156619325/preview.mp3" "Ambient"

# Saturn Radio
download_audio "saturn_radio.wav" "https://saturn.jpl.nasa.gov/audio/cassini-saturn-eerie-sound.wav" "Planetary"

echo "✨ Comprehensive Download Complete."
