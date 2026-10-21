#!/usr/bin/env python3
"""Integration tests using real PNG dimensions and EPUB archives."""
import json
from pathlib import Path
import struct
import subprocess
import tempfile
import sys
import unittest
import xml.etree.ElementTree as ET
from zipfile import ZIP_STORED, ZipFile
import zlib

COMMAND = Path(__file__).resolve().parents[1] / 'data/tools/epub_image_width.py'


def png(w, h):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) +
            chunk(b'IDAT', zlib.compress((b'\0' + b'\xff' * w * 3) * h)) + chunk(b'IEND', b''))


class Tests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.epub = Path(self.temp.name) / 'test book.epub'
        self.images = {'wide.png': png(200, 100), 'square.png': png(100, 100),
                       'tall.png': png(50, 100), 'long.png': png(10, 100),
                       'chapter-1.png': png(100, 100), 'profile-cg.png': png(100, 100),
                       'part-1.png': png(100, 100), 'art.png': png(100, 100)}
        self.body = '<html xmlns="http://www.w3.org/1999/xhtml"><body>' + ''.join(
            '<figure class="image"><img src="img/' + n + '" alt="diagram" /></figure>'
            for n in self.images) + '<p><img src="img/square.png" alt="inline" /></p></body></html>'
        self.write()

    def write(self):
        with ZipFile(self.epub, 'w') as z:
            z.writestr('mimetype', 'application/epub+zip', compress_type=ZIP_STORED)
            z.writestr('META-INF/container.xml', '<container><rootfiles><rootfile full-path="EPUB/book.opf"/></rootfiles></container>')
            z.writestr('EPUB/book.opf', '<package><manifest><item id="body" href="body.xhtml" media-type="application/xhtml+xml"/><item id="art" href="img/art.png" properties="cover-image"/></manifest><spine><itemref idref="body"/></spine></package>')
            z.writestr('EPUB/body.xhtml', self.body)
            for n, data in self.images.items():
                z.writestr('EPUB/img/' + n, data)

    def run_command(self, *args, success=True, write=True):
        if write and not any(x in args for x in ('--dry-run', '--in-place', '--output')):
            args = (*args, '--in-place')
        r = subprocess.run([sys.executable, str(COMMAND), str(self.epub), *args], capture_output=True, text=True)
        self.assertEqual(r.returncode == 0, success, r.stdout + r.stderr)
        return r

    def tags(self):
        with ZipFile(self.epub) as z:
            return list(ET.fromstring(z.read('EPUB/body.xhtml')).iter('{http://www.w3.org/1999/xhtml}img'))

    def test_dimensions_and_exclusions(self):
        self.run_command()
        tags = self.tags()
        self.assertEqual([t.get('style') for t in tags[:4]],
                         ['width: 100%; height: auto', 'width: 80%; height: auto',
                          'width: 40%; height: auto', 'width: 40%; height: auto'])
        self.assertTrue(all('style' not in t.attrib for t in tags[4:]))
        with ZipFile(self.epub) as z:
            self.assertEqual(z.infolist()[0].filename, 'mimetype')
            self.assertEqual(z.infolist()[0].compress_type, ZIP_STORED)
            for n, data in self.images.items():
                self.assertEqual(z.read('EPUB/img/' + n), data)

    def test_dry_run_does_not_write(self):
        before = self.epub.read_bytes()
        r = self.run_command('--dry-run')
        self.assertIn('dry run', r.stdout)
        self.assertEqual(before, self.epub.read_bytes())

    def test_idempotent_and_recalculation(self):
        self.run_command()
        before = self.epub.read_bytes()
        self.run_command()
        self.assertEqual(before, self.epub.read_bytes())
        self.run_command('--height-width-ratio', '0.5', '--min-width', '20', '--max-width', '90')
        self.assertEqual(self.tags()[1].get('style'), 'width: 50%; height: auto')

    def test_extra_exclusion(self):
        self.run_command('--exclude', 'square*')
        self.assertNotIn('style', self.tags()[1].attrib)

    def test_preserve_other_style_and_replace_dimensions(self):
        self.body = self.body.replace('alt="diagram"', 'alt="diagram" width="300" height="400" style="border: 0; width: 80% !important; height: 4em"', 1)
        self.write()
        self.run_command()
        tag = self.tags()[0]
        self.assertEqual(tag.get('style'), 'border: 0; width: 100%; height: auto')
        self.assertNotIn('width', tag.attrib)
        self.assertNotIn('height', tag.attrib)
        self.assertEqual(tag.get('alt'), 'diagram')

    def test_missing_image_preserves_input(self):
        del self.images['tall.png']
        self.write()
        before = self.epub.read_bytes()
        self.run_command(success=False)
        self.assertEqual(before, self.epub.read_bytes())

    def test_invalid_options_preserve_input(self):
        before = self.epub.read_bytes()
        for args in [('--min-width', '101'), ('--height-width-ratio', 'nan'), ('--max-width', '0')]:
            self.run_command(*args, success=False)
            self.assertEqual(before, self.epub.read_bytes())

    def test_bad_image_preserves_input(self):
        self.images['tall.png'] = b'invalid'
        self.write()
        before = self.epub.read_bytes()
        self.run_command(success=False)
        self.assertEqual(before, self.epub.read_bytes())


    def test_preview_json_by_default(self):
        before = self.epub.read_bytes()
        r = self.run_command('--json', write=False)
        result = json.loads(r.stdout)
        self.assertTrue(result['dry_run'])
        self.assertIsNone(result['output'])
        self.assertEqual(len(result['figures']), 4)
        self.assertEqual(before, self.epub.read_bytes())

    def test_output_new_file_and_reject_overwrite(self):
        before = self.epub.read_bytes()
        output = self.epub.parent / 'new book.epub'
        self.run_command('--output', str(output))
        self.assertEqual(before, self.epub.read_bytes())
        self.assertTrue(output.is_file())
        saved = output.read_bytes()
        self.run_command('--output', str(output), success=False)
        self.assertEqual(saved, output.read_bytes())
        self.assertEqual(before, self.epub.read_bytes())

    def test_conflicting_modes(self):
        before = self.epub.read_bytes()
        self.run_command('--dry-run', '--in-place', success=False)
        self.assertEqual(before, self.epub.read_bytes())

    def test_symlink_input_and_output(self):
        before = self.epub.read_bytes()
        link = self.epub.parent / 'link.epub'
        link.symlink_to(self.epub)
        self.run_command('--output', str(link), success=False)
        original = self.epub
        self.epub = link
        self.run_command(success=False)
        self.assertEqual(before, original.read_bytes())


if __name__ == '__main__':
    unittest.main()
