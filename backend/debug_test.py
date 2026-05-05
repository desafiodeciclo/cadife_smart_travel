import subprocess
import sys

if __name__ == '__main__':
    result = subprocess.run([sys.executable, '-m', 'pytest', 'tests/test_infrastructure/test_repositories.py'], capture_output=True, text=True)
    with open('pytest_log.txt', 'w', encoding='utf-8') as f:
        f.write(result.stdout)
        f.write("\nSTDERR:\n")
        f.write(result.stderr)

