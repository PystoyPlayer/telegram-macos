from pathlib import Path
import argparse
import subprocess
import tempfile

def block(text, marker, opener='{'):
    start = text.index(marker)
    start = text.index(opener, start)
    closer = '}' if opener == '{' else ')'
    depth = 0
    for i in range(start, len(text)):
        if text[i] == opener:
            depth += 1
        elif text[i] == closer:
            depth -= 1
            if depth == 0:
                return text[start:i+1]
    raise ValueError(marker)

def parts(source):
    state = 'private struct State: Equatable ' + block(source, 'private struct State')
    marker = 'chatInteraction.revealMedia = '
    callback = marker + block(source, marker) if marker in source else ''
    rows = []
    for line in source.splitlines():
        if 'MessageEntryAdditionalData(' in line and 'eventLog: entry.event' in line:
            rows.append('MessageEntryAdditionalData' + block(line, 'MessageEntryAdditionalData(', '('))
    assert len(rows) == 4
    return state, callback, rows

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, required=True)
    args = parser.parse_args()
    state, callback, rows = parts(args.source.read_text())
    template = Path(__file__).with_name('Tests.swift').read_text()
    swift = template.replace('STATE_SOURCE', state).replace('CALLBACK_SOURCE', callback).replace('ROW_SOURCE', ',\n'.join(rows))
    with tempfile.TemporaryDirectory(prefix='admin-log-spoiler-') as temp:
        path = Path(temp)
        (path/'main.swift').write_text(swift)
        subprocess.run(['swiftc', str(path/'main.swift'), '-o', str(path/'checks')], check=True)
        raise SystemExit(subprocess.run([str(path/'checks')]).returncode)

if __name__ == '__main__':
    main()
