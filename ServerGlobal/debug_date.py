import datetime

try:
    # Target date: 29/12/176891
    # Let's find the timestamp for this.
    target = datetime.datetime(176891, 12, 29)
    ts = target.timestamp()
    print(f"Timestamp for 176891-12-29: {ts}")
    print(f"As int: {int(ts)}")
    print(f"In ms: {int(ts * 1000)}")
    
    current = datetime.datetime.now().timestamp()
    print(f"Current ts: {current}")
    
    ratio = ts / current
    print(f"Ratio ts/current: {ratio}")
    
    # Check if current * 1000 * 1000 matches roughly
    print(f"Current * 1M: {current * 1000000}")
    
except Exception as e:
    print(e)
