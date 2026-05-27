import {BenchmarkMcpClient} from '../lib/mcpClient.js';
import {getServer} from '../lib/servers.js';
import type {TaskResult, VariantId} from '../lib/types.js';

const EXPECTED_OCU_TOOLS = [
	'click',
	'drag',
	'get_app_state',
	'list_apps',
	'perform_secondary_action',
	'press_key',
	'scroll',
	'set_value',
	'type_text',
];

export async function runColdStartTask(variant: VariantId, trial: number): Promise<TaskResult> {
	const wallStart = performance.now();
	const client = new BenchmarkMcpClient(getServer(variant));
	const calls = [];

	try {
		await client.connect();
		const listStart = performance.now();
		const tools = await client.listTools();
		const listMs = performance.now() - listStart;

		calls.push({
			tool: 'tools/list',
			durationMs: listMs,
			responseBytes: Buffer.byteLength(JSON.stringify(tools)),
			imageBytes: 0,
			isError: false,
		});

		const expected = variant === 'legacy' ? ['computer'] : EXPECTED_OCU_TOOLS;
		const sorted = [...tools].sort();
		const expectedSorted = [...expected].sort();
		const success = JSON.stringify(sorted) === JSON.stringify(expectedSorted);

		const result: TaskResult = {
			taskId: 'cold_start',
			variant,
			trial,
			success,
			wallTimeMs: performance.now() - wallStart,
			steps: 1,
			calls,
		};
		if (!success) {
			result.notes = `tools=${tools.join(',')}`;
		}

		return result;
	} catch (error) {
		return {
			taskId: 'cold_start',
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
