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

def filter_out_finish_events(entries):
    for entry in entries:
        if ('event' in entry.keys() and entry['event'] != u'FINISH') or \
                ('event' not in entry.keys()):
            yield entry

max_millis = -1
def add_millis_forwards(entry):
    global max_millis
    max_millis = max(entry['millis'], max_millis)
    if entry['millis'] < max_millis:
        entry['millis'] += max_millis
    return entry

output = []
max_millis = -1
for filename in sys.argv[1:-2]:
    print 'Reading:', filename
    playback_run = json.loads(open(filename).read())

    for event in filter_out_finish_events(playback_run):
        entry_to_output = add_millis_forwards(event)
        output.append(entry_to_output)

filename = sys.argv[-2]
print 'Reading:', filename
events = json.loads(open(filename).read())
for event in events:
    entry_to_output = add_millis_forwards(event)
    output.append(entry_to_output)

print 'Outputting:', sys.argv[-1]
open(sys.argv[-1], 'w').write(json.dumps(output))
