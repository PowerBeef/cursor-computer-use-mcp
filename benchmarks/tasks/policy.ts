import {BenchmarkMcpClient} from '../lib/mcpClient.js';
import {getServer} from '../lib/servers.js';
import type {TaskResult, ToolCallRecord, VariantId} from '../lib/types.js';
import {extractTextFromMcpResult} from '../lib/textedit.js';

export async function runPolicyTask(variant: VariantId, trial: number): Promise<TaskResult> {
	if (variant === 'legacy') {
		return {
			taskId: 'policy',
			variant,
			trial,
			success: true,
			wallTimeMs: 0,
			steps: 0,
			calls: [],
			notes: 'legacy computer-use-mcp has no password-manager denylist (informational skip)',
		};
	}

	const wallStart = performance.now();
	const client = new BenchmarkMcpClient(getServer(variant));
	const calls: ToolCallRecord[] = [];

	try {
		await client.connect();
		// Use a denylisted third-party bundle ID — never com.apple.Passwords (would launch the system app).
		const {result, metrics} = await client.callTool('get_app_state', {app: 'com.1password.1password'});
		calls.push(metrics);

		const text = extractTextFromMcpResult(result.content);
		const blocked = metrics.isError || /blocked|denied|not allowed|safety/i.test(text);

		return {
			taskId: 'policy',
			variant,
			trial,
			success: blocked,
			wallTimeMs: performance.now() - wallStart,
			steps: 1,
			calls,
			notes: blocked ? 'policy blocked as expected' : `unexpected allow: ${text.slice(0, 120)}`,
		};
	} catch (error) {
		return {
			taskId: 'policy',
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
