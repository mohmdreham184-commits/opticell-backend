import urllib.request
import time

try:
    u = urllib.request.urlopen('http://localhost:3000/api/reports/stream')
    start = time.time()
    events = 0
    while time.time() - start < 10 and events < 3:
        line = u.readline()
        if line:
            if line.startswith(b'data:'):
                print('EVENT received:', line[:80])
                events += 1
            elif line.strip() == b'':
                print('BLANK LINE')
        if events >= 3:
            break
    print(f'\nTotal data events received: {events}')
finally:
    u.close()
