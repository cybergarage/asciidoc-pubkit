#!/usr/bin/env python3
"""Set Asciidoctor EPUB body figure widths from embedded image aspect ratios."""
import argparse
import json
import fnmatch
import html
import math
import os
from pathlib import Path
import posixpath
import re
import subprocess
import shutil
import sys
import tempfile
from urllib.parse import unquote, urlsplit
import xml.etree.ElementTree as ET
from zipfile import BadZipFile, ZipFile

EXCLUDES = ('cover*', 'chapter-*', 'part-*', 'profile*')
TAG = re.compile(r"<img\b(?:[^>\"']|\"[^\"]*\"|'[^']*')*>", re.I)
ATTR = re.compile(r"\s+(width|height|style)\s*=\s*([\"'])(.*?)\2", re.I | re.S)


def local(tag):
    return tag.rsplit('}', 1)[-1]


def archive_path(base, href):
    url = urlsplit(href)
    if url.scheme or url.netloc:
        raise ValueError('external image is unsupported: ' + href)
    path = posixpath.normpath(posixpath.join(posixpath.dirname(base), unquote(url.path)))
    if path.startswith('../') or path.startswith('/'):
        raise ValueError('invalid archive path: ' + href)
    return path


def dimensions(data):
    identify = ['magick', 'identify'] if shutil.which('magick') else ['identify']
    result = subprocess.run(identify + ['-format', '%w %h\n', '-'],
                            input=data, capture_output=True, check=True, timeout=30)
    lines = result.stdout.decode().splitlines()
    if len(lines) != 1:
        raise ValueError('multi-frame images are unsupported')
    w, h = map(int, lines[0].split())
    if w <= 0 or h <= 0:
        raise ValueError('image dimensions must be positive')
    return w, h


def sized_tag(tag, width):
    styles = []
    for match in ATTR.finditer(tag):
        if match[1].lower() == 'style':
            for rule in html.unescape(match[3]).split(';'):
                if rule.strip() and rule.partition(':')[0].strip().lower() not in ('width', 'height'):
                    styles.append(rule.strip())
    styles.extend([f'width: {width:g}%', 'height: auto'])
    tag = ATTR.sub('', tag)
    end = '/>' if tag.endswith('/>') else '>'
    return tag[:-len(end)].rstrip() + ' style="' + html.escape('; '.join(styles), quote=True) + '" ' + end


def update(data, name, images, args, cache, report):
    source = data.decode('utf-8')
    root = ET.fromstring(source)
    figures = set()
    def walk(element, in_figure=False):
        in_figure = in_figure or (local(element.tag) == 'figure' and
                                 'image' in element.get('class', '').split())
        if local(element.tag) == 'img' and in_figure:
            figures.add(id(element))
        for child in element:
            walk(child, in_figure)
    walk(root)
    elements = [e for e in root.iter() if local(e.tag) == 'img']
    tags = list(TAG.finditer(source))
    if len(tags) != len(elements):
        raise ValueError('cannot safely match image tags: ' + name)
    replacements = {}
    for tag, element in zip(tags, elements):
        if id(element) not in figures:
            continue
        src = element.get('src', '')
        path = archive_path(name, src)
        if path in images['covers'] or any(fnmatch.fnmatchcase(posixpath.basename(path), p)
                                          for p in EXCLUDES + tuple(args.exclude)):
            continue
        if path not in cache:
            cache[path] = dimensions(images['zip'].read(path))
        w, h = cache[path]
        raw = args.height_width_ratio * 100 * w / h
        width = min(args.max_width, max(args.min_width,
                    round(max(args.min_width, min(args.max_width, raw)), 1)))
        replacements[tag.start()] = sized_tag(tag[0], width)
        report.append((path, w, h, width, raw < args.min_width))
    return TAG.sub(lambda m: replacements.get(m.start(), m[0]), source).encode('utf-8')


def apply(args):
    cache, report = {}, []
    with ZipFile(args.epub) as archive:
        container = ET.fromstring(archive.read('META-INF/container.xml'))
        opf_path = next(e.get('full-path') for e in container.iter() if local(e.tag) == 'rootfile')
        opf = ET.fromstring(archive.read(opf_path))
        manifest = {e.get('id'): e for e in opf.iter() if local(e.tag) == 'item'}
        cover_ids = {e.get('content') for e in opf.iter()
                     if local(e.tag) == 'meta' and e.get('name', '').lower() == 'cover'}
        covers = {archive_path(opf_path, e.get('href')) for i, e in manifest.items()
                  if i in cover_ids or 'cover-image' in e.get('properties', '').split()}
        documents = {archive_path(opf_path, manifest[e.get('idref')].get('href'))
                     for e in opf.iter() if local(e.tag) == 'itemref' and
                     manifest[e.get('idref')].get('media-type') == 'application/xhtml+xml'}
        changed = {}
        for name in sorted(documents):
            original = archive.read(name)
            new = update(original, name, {'zip': archive, 'covers': covers}, args, cache, report)
            if new != original:
                changed[name] = new
        destination = args.output or args.epub
        writing = args.in_place or args.output is not None
        if writing and (changed or args.output is not None):
            # Validate everything before replacement. A failure preserves the input EPUB.
            fd, temp = tempfile.mkstemp(prefix='.epub-image-width-', suffix='.epub', dir=destination.parent)
            try:
                with os.fdopen(fd, 'wb') as output, ZipFile(output, 'w') as dest:
                    dest.comment = archive.comment
                    for entry in archive.infolist():
                        dest.writestr(entry, changed.get(entry.filename, archive.read(entry.filename)))
                os.chmod(temp, args.epub.stat().st_mode & 0o777)
                if args.output is not None:
                    # Install without overwriting any existing file, even in a race.
                    os.link(temp, destination)
                else:
                    os.replace(temp, destination)
            finally:
                if os.path.exists(temp):
                    os.unlink(temp)
    result = {
        'input': str(args.epub), 'output': str(destination) if writing else None,
        'dry_run': not writing, 'changed_documents': len(changed),
        'settings': {'height_width_ratio': args.height_width_ratio,
                     'min_width': args.min_width, 'max_width': args.max_width,
                     'exclude': list(EXCLUDES) + args.exclude},
        'figures': [{'image': p, 'pixel_width': w, 'pixel_height': h,
                     'width_percent': width, 'minimum_limited': floor}
                    for p, w, h, width, floor in report]
    }
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        for path, w, h, width, floor in report:
            print(f'{path}: {w}x{h} -> {width:g}%' + (' (minimum width; review tall figure)' if floor else ''))
        print(f'epub image-width: {len(report)} figures; {len(changed)} XHTML files' +
              ('; dry run' if not writing else '; output: ' + str(destination)))


def main():
    parser = argparse.ArgumentParser(prog="asciidoc-pubkit epub image-width", description=__doc__)
    parser.add_argument('epub', type=Path)
    parser.add_argument('--height-width-ratio', type=float, default=0.8,
                        help='target image height / text area width (default: 0.8)')
    parser.add_argument('--min-width', type=float, default=40, help='minimum width percentage (default: 40)')
    parser.add_argument('--max-width', type=float, default=100, help='maximum width percentage (default: 100)')
    parser.add_argument('--exclude', action='append', default=[], help='additional image basename glob')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--dry-run', action='store_true', help='preview only (the default)')
    mode.add_argument('--in-place', action='store_true', help='explicitly replace the input EPUB')
    mode.add_argument('-o', '--output', type=Path, help='write a new EPUB; never overwrite')
    parser.add_argument('--json', action='store_true', help='structured settings and per-figure report')
    args = parser.parse_args()
    if not all(math.isfinite(v) for v in (args.height_width_ratio, args.min_width, args.max_width)) or not (
            args.height_width_ratio > 0 and 0 < args.min_width <= args.max_width <= 100):
        parser.error('require finite ratio > 0 and 0 < min-width <= max-width <= 100')
    try:
        if not args.epub.is_file() or args.epub.is_symlink():
            raise ValueError('input must be a regular file, not a symlink')
        if args.output is not None and (args.output.exists() or args.output.is_symlink()):
            raise ValueError('output already exists: ' + str(args.output))
        apply(args)
    except (OSError, ValueError, KeyError, StopIteration, ET.ParseError, BadZipFile,
            subprocess.SubprocessError) as error:
        print(f'Error: {error}', file=sys.stderr)
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main())
