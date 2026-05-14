import sys
import os

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), "backend"))

from main import app

print("=== Registered Routes ===")
for route in app.routes:
    if hasattr(route, "path"):
        print(f"{route.path} [{', '.join(route.methods)}]")
