
import os
import wave
import struct

def create_silent_wav(filename, duration=1.0):
    sample_rate = 44100
    num_frames = int(duration * sample_rate)
    num_channels = 1
    sample_width = 2  # 16-bit

    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(num_channels)
        wav_file.setsampwidth(sample_width)
        wav_file.setframerate(sample_rate)
        
        # Write silence
        data = struct.pack('<h', 0) * num_frames
        wav_file.writeframes(data)
    print(f"Created {filename}")

def main():
    base_dir = "/Users/pro/Projects/Screensaver/Resources/Audio"
    
    # Files identified from AudioController.swift
    files = [
        "ambient_solar_wind",
        "human_radio_noise",
        "planet_mercury",
        "planet_venus",
        "planet_earth",
        "planet_mars",
        "planet_jupiter",
        "planet_saturn",
        "planet_uranus",
        "planet_neptune",
        "mission_apollo_11_moon_landing",
        "mission_voyager_golden_record",
        "mission_hubble_launch",
        "mission_iss_construction",
        "mission_perseverance_mars_landing"
    ]

    # Ensure directories exist
    os.makedirs(base_dir, exist_ok=True)
    
    # Determine subdirectories based on existing structure or flattening
    # The AudioController looks in "Audio" directory or root bundle.
    # We will generate them flat in Resources/Audio for simplicity, 
    # as the bundle logic usually flattens or preserves depending on copy build phase.
    # To be safe, we put them in Resources/Audio/Generic
    
    for fname in files:
        # Determine category for better organization (optional, but good for user)
        if "planet" in fname:
            subdir = os.path.join(base_dir, "Planetary")
        elif "mission" in fname:
            subdir = os.path.join(base_dir, "Events")
        elif "human" in fname:
            subdir = os.path.join(base_dir, "Human")
        else:
            subdir = os.path.join(base_dir, "Ambient")
            
        os.makedirs(subdir, exist_ok=True)
        path = os.path.join(subdir, f"{fname}.wav")
        if not os.path.exists(path):
            create_silent_wav(path)
        else:
            print(f"Skipping {path} (exists)")

if __name__ == "__main__":
    main()
