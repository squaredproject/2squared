#!/usr/bin/env python
import json
import os
import sys

if len(sys.argv) == 1:
    print 'Usage:', sys.argv[0], '<input>... <output>'
    sys.exit(1)

if os.path.exists(sys.argv[-1]):
    print sys.argv[-1], 'exists, not overwriting and exiting.'
    sys.exit(2)

output = []
for filename in sys.argv[1:-2]:
    print 'Reading:', filename
    playback_run = json.loads(open(filename).read())
    for o in playback_run:
        if 'event' in o.keys() and o['event'] != u'FINISH':
            output.append(o)
        elif 'event' not in o.keys():
            output.append(o)

filename = sys.argv[-2]
print 'Reading:', filename
o = json.loads(open(filename).read())
output.extend(o)

print 'Outputting:', sys.argv[-1]
open(sys.argv[-1], 'w').write(json.dumps(output))
