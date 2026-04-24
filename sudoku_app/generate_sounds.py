"""
Generate minimal sound effects for Sudoku game
All sounds are simple, pleasant tones under 1 second
"""
import wave
import struct
import math
import os

def generate_tone(filename, frequency, duration, volume=0.3, fade_out=True):
    """Generate a simple sine wave tone"""
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 2 bytes = 16 bit
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            # Sine wave
            sample = math.sin(2 * math.pi * frequency * t)
            
            # Apply fade out for smoother ending
            if fade_out:
                fade_factor = 1.0 - (i / num_samples) ** 0.5
                sample *= fade_factor
            
            # Apply volume
            sample *= volume
            
            # Convert to 16-bit integer
            packed = struct.pack('h', int(sample * 32767))
            wav_file.writeframes(packed)

def generate_multi_tone(filename, frequencies, duration, volume=0.3):
    """Generate a chord/multi-tone sound"""
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            sample = 0
            
            for freq in frequencies:
                sample += math.sin(2 * math.pi * freq * t)
            
            sample /= len(frequencies)  # Normalize
            
            # Fade out
            fade_factor = 1.0 - (i / num_samples) ** 0.3
            sample *= fade_factor * volume
            
            packed = struct.pack('h', int(sample * 32767))
            wav_file.writeframes(packed)

def generate_ascending_tones(filename, start_freq, end_freq, duration, volume=0.3):
    """Generate ascending pitch sound"""
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            progress = i / num_samples
            
            # Interpolate frequency
            freq = start_freq + (end_freq - start_freq) * progress
            sample = math.sin(2 * math.pi * freq * t)
            
            # Fade out at end
            if progress > 0.7:
                fade = 1.0 - ((progress - 0.7) / 0.3)
                sample *= fade
            
            sample *= volume
            packed = struct.pack('h', int(sample * 32767))
            wav_file.writeframes(packed)

def generate_click(filename, duration=0.05, volume=0.4):
    """Generate a short click sound"""
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            progress = i / num_samples
            
            # Mix of frequencies for click sound
            sample = (
                math.sin(2 * math.pi * 1000 * t) * 0.5 +
                math.sin(2 * math.pi * 2000 * t) * 0.3 +
                math.sin(2 * math.pi * 4000 * t) * 0.2
            )
            
            # Sharp attack, quick decay
            envelope = math.exp(-progress * 8)
            sample *= envelope * volume
            
            packed = struct.pack('h', int(sample * 32767))
            wav_file.writeframes(packed)

def generate_chime(filename, base_freq, duration, volume=0.3):
    """Generate a pleasant chime sound"""
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    
    # Chime harmonics
    harmonics = [1.0, 2.0, 3.0, 4.76]  # Approximate bell harmonics
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            progress = i / num_samples
            
            sample = 0
            for j, h in enumerate(harmonics):
                # Higher harmonics decay faster
                decay = math.exp(-progress * (3 + j * 2))
                sample += math.sin(2 * math.pi * base_freq * h * t) * decay / (j + 1)
            
            sample *= volume
            packed = struct.pack('h', int(sample * 32767))
            wav_file.writeframes(packed)

def main():
    output_dir = "assets/sounds"
    os.makedirs(output_dir, exist_ok=True)
    
    print("Generating sound effects...")
    
    # 1. Game Start - pleasant welcoming tone (0.3s)
    print("  - game_start.wav")
    generate_ascending_tones(
        f"{output_dir}/game_start.wav",
        start_freq=400, end_freq=600,
        duration=0.3, volume=0.25
    )
    
    # 2. Correct Input - very short, subtle click (0.08s)
    print("  - correct_input.wav")
    generate_click(f"{output_dir}/correct_input.wav", duration=0.08, volume=0.3)
    
    # 3. Row Complete - soft chime (0.25s)
    print("  - row_complete.wav")
    generate_chime(f"{output_dir}/row_complete.wav", base_freq=523, duration=0.25, volume=0.25)  # C5
    
    # 4. Column Complete - slightly different chime (0.25s)
    print("  - column_complete.wav")
    generate_chime(f"{output_dir}/column_complete.wav", base_freq=587, duration=0.25, volume=0.25)  # D5
    
    # 5. Box Complete - fuller chime (0.35s)
    print("  - box_complete.wav")
    generate_chime(f"{output_dir}/box_complete.wav", base_freq=659, duration=0.35, volume=0.28)  # E5
    
    # 6. Game Complete - triumphant chord (0.5s)
    print("  - game_complete.wav")
    generate_multi_tone(
        f"{output_dir}/game_complete.wav",
        frequencies=[523, 659, 784],  # C major chord
        duration=0.5, volume=0.3
    )
    
    # 7. Victory - celebratory ascending tones (0.8s)
    print("  - victory.wav")
    generate_ascending_tones(
        f"{output_dir}/victory.wav",
        start_freq=400, end_freq=800,
        duration=0.8, volume=0.3
    )
    
    print("\nAll sounds generated successfully!")
    print(f"Location: {os.path.abspath(output_dir)}")

if __name__ == "__main__":
    main()
