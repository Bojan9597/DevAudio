"""
Audio utility functions for extracting duration and metadata.
"""

try:
    from mutagen.wave import WAVE
    from mutagen.mp3 import MP3
    from mutagen.flac import FLAC
    from mutagen.oggvorbis import OggVorbis
    from mutagen.oggflac import OggFLAC
    from mutagen.oggopus import OggOpus
    from mutagen.oggtheoravorbis import OggTheoraVorbis
    import mutagen
    MUTAGEN_AVAILABLE = True
except ImportError:
    MUTAGEN_AVAILABLE = False
    print("Warning: mutagen not installed. Audio duration extraction will not work.")

def get_audio_duration_seconds(file_path):
    """
    Extract audio duration in seconds from a file.
    
    Args:
        file_path (str): Path to the audio file
        
    Returns:
        int: Duration in seconds, or 0 if unable to determine
    """
    if not MUTAGEN_AVAILABLE:
        print(f"Warning: mutagen not available. Cannot extract duration for {file_path}")
        return 0
    
    try:
        # Try to detect format automatically
        audio = mutagen.File(file_path)
        
        if audio is None:
            print(f"Warning: Could not determine audio format for {file_path}")
            return 0
            
        if hasattr(audio.info, 'length'):
            duration_seconds = int(audio.info.length)
            print(f"Extracted duration: {file_path} -> {duration_seconds}s")
            return duration_seconds
        else:
            print(f"Warning: Audio file has no length info: {file_path}")
            return 0
            
    except Exception as e:
        print(f"Error extracting duration from {file_path}: {e}")
        return 0


def get_total_playlist_duration(playlist_durations):
    """
    Calculate total duration from a list of track durations.
    
    Args:
        playlist_durations (list): List of duration_seconds (int)
        
    Returns:
        int: Total duration in seconds
    """
    return sum(d for d in playlist_durations if d > 0)
