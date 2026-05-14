import os
import re

versions_dir = r"c:\Users\F.R.A.N.Ks\Documents\ALPHA\DESAFIOCICLO\Semana 2\cadife_smart_travel\backend\migrations\versions"
files = [f for f in os.listdir(versions_dir) if f.endswith(".py")]

revisions = set()
down_revisions = set()

for f in files:
    try:
        with open(os.path.join(versions_dir, f), "r", encoding="utf-8") as file:
            content = file.read()
            rev_match = re.search(r'revision\s*(?::\s*str)?\s*=\s*[\'"]([^\'"]+)[\'"]', content)
            
            if rev_match:
                revisions.add(rev_match.group(1))
            
            down_match = re.search(r'down_revision\s*(?::\s*Union\[[^\]]+\])?\s*=\s*([^\n]+)', content)
            
            if down_match:
                val = down_match.group(1).strip()
                if val.startswith("(") or val.startswith("["):
                    items = re.findall(r'[\'"]([^\'"]+)[\'"]', val)
                    down_revisions.update(items)
                elif val != "None":
                    item = re.search(r'[\'"]([^\'"]+)[\'"]', val)
                    if item:
                        down_revisions.add(item.group(1))
    except Exception as e:
        print(f"Error reading {f}: {e}")

print("Revisions found:", len(revisions))
print("Heads (revisions not in any down_revision):")
heads = revisions - down_revisions
for h in heads:
    print(f"  - {h}")

print("\nMissing Down Revisions (down_revisions not in versions folder):")
missing = down_revisions - revisions
for m in missing:
    if m != 'None':
        print(f"  - {m}")
