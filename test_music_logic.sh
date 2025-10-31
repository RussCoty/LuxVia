#!/bin/bash

echo "🎵 Testing Music List Logic"
echo "================================"

# Count and show lyric entries with audio files
echo "📊 Counting lyric entries with audio files:"
count=$(grep -c "lyric,.*\\.mp3\\|lyric,.*\\.wav" /workspaces/LuxVia/LuxVia/lyrics.csv)
echo "Total entries: $count"

echo ""
echo "🎼 Sample entries that would be shown:"
echo "-------------------------------------"

# Show first 10 entries
grep "lyric,.*\\.mp3\|lyric,.*\\.wav" /workspaces/LuxVia/LuxVia/lyrics.csv | head -10 | while IFS=',' read -r uid title content type audiofile category; do
    # Clean up the title (remove quotes)
    title_clean=$(echo "$title" | sed 's/^"//;s/"$//')
    echo "• $title_clean -> $audiofile"
done

echo ""
echo "✅ Expected result: Music library should show $count entries"
echo "   (All entries will show 'Audio Missing' since no MP3 files exist)"