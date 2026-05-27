import {execFileSync} from 'node:child_process';
import {readFileSync} from 'node:fs';
import {fixturePath} from './paths.js';

const textEditFixture = fixturePath('textedit-click.json');

export type TextEditCalibration = {
	clickXFraction: number;
	clickYFraction: number;
	note?: string;
};

export function loadCalibration(): TextEditCalibration {
	const raw = readFileSync(textEditFixture, 'utf8');
	return JSON.parse(raw) as TextEditCalibration;
}

export function resetTextEdit(): void {
	execFileSync('osascript', [
		'-e', 'tell application "TextEdit" to activate',
		'-e', 'tell application "TextEdit" to close every document saving no',
		'-e', 'tell application "TextEdit" to make new document',
	], {stdio: 'ignore', timeout: 15_000});
	execFileSync('sleep', ['0.5']);
}

export function readTextEditDocument(): string {
	return execFileSync('osascript', [
		'-e', 'tell application "TextEdit"',
		'-e', 'if (count of documents) = 0 then return ""',
		'-e', 'return text of document 1',
		'-e', 'end tell',
	], {encoding: 'utf8', timeout: 10_000}).trim();
}

export function quitTextEdit(): void {
	try {
		execFileSync('osascript', [
			'-e', 'tell application "TextEdit" to close every document saving no',
		], {stdio: 'ignore', timeout: 10_000});
	} catch {
		/* ignore */
	}
}

export function extractTextFromMcpResult(content: Array<{type: string; text?: string}> | undefined): string {
	return (content ?? [])
		.filter((b) => b.type === 'text' && b.text)
		.map((b) => b.text!)
		.join('\n');
}

/** Find first likely editable element index in OCU accessibility text */
export function findEditableElementIndex(treeText: string): string | undefined {
	const patterns = [
		/^\s*(\d+)\s*[:.)]\s*.*\b(AXTextArea|AXTextField|AXTextEditor|AXTextView)\b/im,
		/\belement_index[=:\s]+["']?(\d+)["']?/i,
		/\b(\d+)\s+AXTextArea\b/i,
	];

	for (const pattern of patterns) {
		const match = treeText.match(pattern);
		if (match?.[1]) {
			return match[1];
		}
	}

	const lineMatch = treeText.match(/^\s*(\d+)\s*:/m);
	return lineMatch?.[1];
}

export function coordsFromCalibration(
	imageWidth: number,
	imageHeight: number,
	cal: TextEditCalibration,
): [number, number] {
	return [
		Math.round(imageWidth * cal.clickXFraction),
		Math.round(imageHeight * cal.clickYFraction),
	];
}
