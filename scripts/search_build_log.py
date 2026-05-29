import pathlib
import re
import sys
path = pathlib.Path(r'C:\Users\reham\AppData\Roaming\Code\User\workspaceStorage\40040966c4b3fc6e7ca328cf50ff3709\GitHub.copilot-chat\chat-session-resources\97dd5650-bf2a-4ff0-ac92-18ee9c58c1ce\call_3XERDZlZpAV3NdQl0VLJtJgE__vscode-1777483436225\content.txt')
text = path.read_text(errors='replace')
for line in text.splitlines():
    if re.search(r'app-release\.apk|Built .*apk|APK|apk|failed to produce|BUILD SUCCESSFUL|BUILD FAILED', line, re.IGNORECASE):
        print(line)
