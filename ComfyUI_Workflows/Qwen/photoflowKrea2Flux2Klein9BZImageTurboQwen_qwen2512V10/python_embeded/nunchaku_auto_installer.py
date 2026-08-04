import sys
import subprocess
import torch
import re
import urllib.request
import json
import os
import time
from urllib.error import URLError, HTTPError

print("=== Nunchaku Auto-Installer for ComfyUI ===")

# Dynamically detect versions
pyver = f'cp{sys.version_info.major}{sys.version_info.minor}-cp{sys.version_info.major}{sys.version_info.minor}'
torchver = torch.__version__
torch_match = re.search(r'(\d+\.\d+)(?:\.\d+)?', torchver)
torch_short = torch_match.group(1) if torch_match else '2.10'

cu = torch.version.cuda
if not cu:
    print('❌ No CUDA detected! Nunchaku requires GPU.')
    input("Press Enter...")
    sys.exit(1)

cu_short = f'cu{cu}'
print(f'Detected: Python {pyver}')
print(f'          Torch {torchver} → {torch_short}')
print(f'          CUDA  {cu} → {cu_short}')

# Get latest version
latest_url = 'https://api.github.com/repos/nunchaku-ai/nunchaku/releases/latest'
print('Fetching latest release...')
try:
    resp = urllib.request.urlopen(latest_url, timeout=10)
    latest_json = json.loads(resp.read().decode('utf-8'))
    latest_tag = latest_json['tag_name'].lstrip('v')
    print(f'Latest Nunchaku: {latest_tag}')
except Exception as e:
    print(f'❌ Failed to fetch release info: {e}')
    print('Manual download required.')
    input("Press Enter...")
    sys.exit(1)

# Dynamic wheel format
wheel_name = f'nunchaku-{latest_tag}+{cu_short}torch{torch_short}-{pyver}-win_amd64.whl'
url = f'https://github.com/nunchaku-ai/nunchaku/releases/download/v{latest_tag}/{wheel_name}'
print(f'\nDownloading: {url}')

# Robust download with retry and connection error handling
max_retries = 3
for attempt in range(max_retries):
    try:
        print(f'Attempt {attempt + 1}/{max_retries}...')
        urllib.request.urlretrieve(url, wheel_name)
        print(f'✅ Wheel downloaded: {wheel_name}')
        break
        
    except (URLError, HTTPError, ConnectionResetError) as e:
        print(f'❌ Download failed (attempt {attempt + 1}): {str(e)[:80]}...')
        if '10054' in str(e) or 'ConnectionResetError' in str(e):
            print('   → GitHub connection reset. Possible rate limiting.')
        elif '404' in str(e):
            print('   → Wheel not found for your config. Check releases page.')
            print(f'     https://github.com/nunchaku-ai/nunchaku/releases/tag/v{latest_tag}')
            input("Press Enter...")
            sys.exit(1)
        
        if attempt < max_retries - 1:
            wait_time = (attempt + 1) * 5  # 5s, 10s, 15s
            print(f'   → Waiting {wait_time}s before retry...')
            time.sleep(wait_time)
        else:
            print('❌ All download attempts failed.')
            print('Solutions:')
            print('1. Check internet connection')
            print('2. Manual download: https://github.com/nunchaku-ai/nunchaku/releases')
            print(f'3. Look for: nunchaku-{latest_tag}+{cu_short}torch{torch_short}-{pyver}-win_amd64.whl')
            input("Press Enter...")
            sys.exit(1)

# Install wheel
try:
    print('Installing wheel...')
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', wheel_name])
    os.remove(wheel_name)
    print('✅ Installation successful!')
except Exception as e:
    print(f'❌ Install failed: {e}')
    if os.path.exists(wheel_name):
        print(f'Wheel left at: {wheel_name}')
    input("Press Enter...")
    sys.exit(1)
