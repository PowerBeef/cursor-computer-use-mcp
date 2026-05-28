import {BenchmarkMcpClient} from '../lib/mcpClient.js';
import {getServer} from '../lib/servers.js';
import type {TaskResult, ToolCallRecord, VariantId} from '../lib/types.js';
import {resetTextEdit} from '../lib/textedit.js';

export async function runScreenshotLatencyTask(variant: VariantId, trial: number): Promise<TaskResult> {
	const wallStart = performance.now();
	const client = new BenchmarkMcpClient(getServer(variant));
	const calls: ToolCallRecord[] = [];

	try {
		resetTextEdit();
		await client.connect();

		if (variant === 'legacy') {
			const {metrics} = await client.callComputer('get_screenshot');
			calls.push(metrics);
		} else {
			const {metrics, result} = await client.callTool('get_app_state', {app: 'TextEdit'});
			calls.push(metrics);
			if (metrics.imageBytes === 0) {
				const text = result.content?.find((block) => block.type === 'text')?.text ?? '';
				if (text.includes('computer-use://screenshot/latest')) {
					const resource = await client.readResource('computer-use://screenshot/latest');
					const blob = resource.contents?.[0]?.blob;
					if (blob) {
						metrics.imageBytes = Buffer.byteLength(blob, 'utf8');
					}
				}
			}
		}

		const success = !calls.some((c) => c.isError) && calls[0]!.imageBytes > 0;

		const result: TaskResult = {
			taskId: 'screenshot_latency',
			variant,
			trial,
			success,
			wallTimeMs: performance.now() - wallStart,
			steps: calls.length,
			calls,
		};
		if (!success) {
			result.notes = 'capture returned no image or errored';
		}

		return result;
	} catch (error) {
		return {
			taskId: 'screenshot_latency',
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
