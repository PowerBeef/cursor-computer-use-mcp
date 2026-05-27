#!/usr/bin/env node
import {execFileSync} from 'node:child_process';
import {writeFileSync} from 'node:fs';
import {fixturePath} from './lib/paths.js';

const outPath = fixturePath('textedit-click.json');

execFileSync('osascript', [
	'-e', 'tell application "TextEdit" to activate',
	'-e', 'tell application "TextEdit"',
	'-e', 'if (count of documents) = 0 then make new document',
	'-e', 'end tell',
	'-e', 'delay 0.5',
], {stdio: 'ignore'});

const bounds = execFileSync('osascript', [
	'-e', 'tell application "TextEdit"',
	'-e', 'set b to bounds of front window',
	'-e', 'return (item 1 of b as text) & "," & (item 2 of b as text) & "," & (item 3 of b as text) & "," & (item 4 of b as text)',
	'-e', 'end tell',
], {encoding: 'utf8'}).trim();

let sw = 1920;
let sh = 1080;
try {
	const screen = execFileSync('osascript', [
		'-e', 'tell application "Finder"',
		'-e', 'set d to bounds of window of desktop',
		'-e', 'return (item 3 of d as text) & "," & (item 4 of d as text)',
		'-e', 'end tell',
	], {encoding: 'utf8'}).trim();
	const parts = screen.split(',').map(Number);
	sw = parts[0] ?? sw;
	sh = parts[1] ?? sh;
} catch {
	/* defaults */
}

const parts = bounds.split(',').map(Number);
const x1 = parts[0] ?? 0;
const y1 = parts[1] ?? 0;
const x2 = parts[2] ?? 0;
const y2 = parts[3] ?? 0;
const centerX = (x1 + x2) / 2;
const centerY = y1 + (y2 - y1) * 0.55;

const cal = {
	clickXFraction: Math.min(0.95, Math.max(0.05, centerX / sw)),
	clickYFraction: Math.min(0.95, Math.max(0.05, centerY / sh)),
	note: `Calibrated from TextEdit window bounds ${bounds} on screen ~${sw}x${sh}`,
};

writeFileSync(outPath, `${JSON.stringify(cal, null, 2)}\n`);
console.log('Wrote', outPath);
console.log(JSON.stringify(cal, null, 2));
