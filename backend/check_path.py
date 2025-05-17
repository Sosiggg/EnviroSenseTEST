import sys
import os

print("Python Path:")
for path in sys.path:
    print(f"  - {path}")

print("\nCurrent Directory:")
print(f"  - {os.getcwd()}")

print("\nDirectory Contents:")
for item in os.listdir():
    print(f"  - {item}")

print("\nChecking if 'app' is a directory:")
print(f"  - {'app' in os.listdir() and os.path.isdir('app')}")

if 'app' in os.listdir() and os.path.isdir('app'):
    print("\nContents of 'app' directory:")
    for item in os.listdir('app'):
        print(f"  - {item}")
