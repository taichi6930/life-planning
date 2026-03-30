import re

with open('coverage/lcov.info') as f:
    content = f.read()

files = content.split('end_of_record')
total_hit = 0
total_found = 0
results = []
for block in files:
    sf_match = re.search(r'SF:(.*)', block)
    if not sf_match:
        continue
    filepath = sf_match.group(1)
    if not filepath.startswith('lib/'):
        continue
    hit = sum(1 for m in re.finditer(r'DA:\d+,(\d+)', block) if int(m.group(1)) > 0)
    found = len(re.findall(r'DA:', block))
    if found > 0:
        total_hit += hit
        total_found += found
        pct = hit / found * 100
        name = filepath
        uncovered = found - hit
        results.append((name, hit, found, pct, uncovered))

results.sort(key=lambda x: x[3])
print(f'Total: {total_hit}/{total_found} = {total_hit/total_found*100:.1f}%')
print()
for name, hit, found, pct, uncov in results:
    marker = ' !!' if pct < 99 else ' OK'
    print(f'{pct:5.1f}% ({uncov:3d} uncov) {name}{marker}')
