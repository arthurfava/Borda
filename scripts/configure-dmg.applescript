on run argv
    set volumeName to item 1 of argv
    tell application "Finder"
        tell disk volumeName
            open
            delay 1
            set current view of container window to icon view
            delay 1
            set toolbar visible of container window to false
            set statusbar visible of container window to false
            set pathbar visible of container window to false
            set sidebar width of container window to 0
            set bounds of container window to {120, 120, 780, 520}
            set arrangement of icon view options of container window to not arranged
            set icon size of icon view options of container window to 104
            set text size of icon view options of container window to 13
            set background picture of icon view options of container window to file ".background:background.png"
            set position of item "Borda.app" to {165, 225}
            set position of item "Applications" to {495, 225}
            update without registering applications
            delay 2
            close
        end tell
    end tell
end run
