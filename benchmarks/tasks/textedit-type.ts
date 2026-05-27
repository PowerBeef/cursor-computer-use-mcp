import {randomUUID} from 'node:crypto';
import {BenchmarkMcpClient} from '../lib/mcpClient.js';
import {getServer} from '../lib/servers.js';
import type {TaskResult, ToolCallRecord, VariantId} from '../lib/types.js';
import {
	coordsFromCalibration,
	extractTextFromMcpResult,
	findEditableElementIndex,
	loadCalibration,
	readTextEditDocument,
	resetTextEdit,
} from '../lib/textedit.js';

export async function runTextEditTypeTask(variant: VariantId, trial: number): Promise<TaskResult> {
	const marker = `cursor-bench-${randomUUID().slice(0, 8)}`;
	const wallStart = performance.now();
	const client = new BenchmarkMcpClient(getServer(variant));
	const calls: ToolCallRecord[] = [];

	try {
		resetTextEdit();
		await client.connect();

		if (variant === 'ocu') {
			await runOcuPath(client, marker, calls);
		} else {
			await runLegacyPath(client, marker, calls);
		}

		const docText = readTextEditDocument();
		const success = docText.includes(marker);
		const axVerify = calls.some((c) => {
			if (c.tool !== 'get_app_state') {
				return false;
			}

			return false;
		});

		return {
			taskId: 'textedit_type',
			variant,
			trial,
			success,
			wallTimeMs: performance.now() - wallStart,
			steps: calls.length,
			calls,
			notes: success ? `verified via AppleScript` : `doc missing marker; len=${docText.length}; ax=${axVerify}`,
		};
	} catch (error) {
		return {
			taskId: 'textedit_type',
			variant,
			trial,
			success: false,
			wallTimeMs: performance.now() - wallStart,
			steps: calls.length,
			calls,
			notes: error instanceof Error ? error.message : String(error),
		};
	} finally {
		await client.close();
	}
}

async function runOcuPath(
	client: BenchmarkMcpClient,
	marker: string,
	calls: ToolCallRecord[],
): Promise<void> {
	const state1 = await client.callTool('get_app_state', {app: 'TextEdit'});
	calls.push(state1.metrics);

	const tree = extractTextFromMcpResult(state1.result.content);
	const elementIndex = findEditableElementIndex(tree);

	if (elementIndex) {
		const setVal = await client.callTool('set_value', {
			app: 'TextEdit',
			element_index: elementIndex,
			value: marker,
		});
		calls.push(setVal.metrics);
		if (setVal.metrics.isError) {
			const typeText = await client.callTool('type_text', {app: 'TextEdit', text: marker});
			calls.push(typeText.metrics);
		}
	} else {
		const click = await client.callTool('click', {
			app: 'TextEdit',
			x: 200,
			y: 200,
		});
		calls.push(click.metrics);
		const typeText = await client.callTool('type_text', {app: 'TextEdit', text: marker});
		calls.push(typeText.metrics);
	}

	const state2 = await client.callTool('get_app_state', {app: 'TextEdit'});
	calls.push(state2.metrics);
}

async function runLegacyPath(
	client: BenchmarkMcpClient,
	marker: string,
	calls: ToolCallRecord[],
): Promise<void> {
	const cal = loadCalibration();
	const shot = await client.callComputer('get_screenshot');
	calls.push(shot.metrics);

	const metaText = extractTextFromMcpResult(shot.result.content);
	let imageWidth = 1280;
	let imageHeight = 720;
	try {
		const meta = JSON.parse(metaText.split('\n').find((l) => l.startsWith('{')) ?? '{}') as {
			image_width?: number;
			image_height?: number;
		};
		if (meta.image_width) {
			imageWidth = meta.image_width;
		}

		if (meta.image_height) {
			imageHeight = meta.image_height;
		}
	} catch {
		/* use defaults */
	}

	const [x, y] = coordsFromCalibration(imageWidth, imageHeight, cal);

	const move = await client.callComputer('mouse_move', {coordinate: [x, y]});
	calls.push(move.metrics);
	const click = await client.callComputer('left_click', {coordinate: [x, y]});
	calls.push(click.metrics);
	const type = await client.callComputer('type', {text: marker});
	calls.push(type.metrics);
}
