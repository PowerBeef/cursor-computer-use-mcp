import {writeFileSync, mkdirSync} from 'node:fs';
import {join} from 'node:path';
import {median, successRate, summarizeNumbers} from './lib/metrics.js';
import type {TaskResult, TrialRun, VariantId} from './lib/types.js';

function filterTasks(runs: TrialRun[], variant: VariantId, taskId: string): TaskResult[] {
	return runs
		.filter((r) => r.variant === variant)
		.flatMap((r) => r.tasks.filter((t) => t.taskId === taskId));
}

function latencyStats(tasks: TaskResult[], toolFilter?: string | RegExp): string {
	const latencies: number[] = [];
	for (const task of tasks) {
		for (const call of task.calls) {
			if (toolFilter) {
				if (typeof toolFilter === 'string' && call.tool !== toolFilter) {
					continue;
				}

				if (toolFilter instanceof RegExp && !toolFilter.test(call.tool)) {
					continue;
				}
			}

			latencies.push(call.durationMs);
		}
	}

	const s = summarizeNumbers(latencies);
	return latencies.length === 0 ? 'n/a' : `median ${s.median.toFixed(0)}ms, p95 ${s.p95.toFixed(0)}ms (n=${s.n})`;
}

export function writeReport(outDir: string, runs: TrialRun[]): void {
	mkdirSync(outDir, {recursive: true});

	for (const run of runs) {
		writeFileSync(join(outDir, `${run.variant}.json`), JSON.stringify(run, null, 2));
	}

	const md = buildMarkdown(runs, runs[0]?.metadata ?? {});
	writeFileSync(join(outDir, 'report.md'), md);
	console.log(`\nWrote ${join(outDir, 'report.md')}`);
}

function buildMarkdown(runs: TrialRun[], metadata: Record<string, string>): string {
	const lines: string[] = [
		'# Computer Use benchmark report',
		'',
		'## Environment',
		'',
	];

	for (const [k, v] of Object.entries(metadata)) {
		lines.push(`- **${k}**: ${v}`);
	}

	lines.push('', '## Task success rates', '', '| Task | OCU | Legacy |', '|------|-----|--------|');

	const taskIds = ['cold_start', 'screenshot_latency', 'textedit_type', 'policy'];
	for (const taskId of taskIds) {
		const ocu = filterTasks(runs, 'ocu', taskId);
		const legacy = filterTasks(runs, 'legacy', taskId);
		const ocuRate = `${(successRate(ocu.map((t) => t.success)) * 100).toFixed(0)}%`;
		const legacyRate = legacy.length
			? `${(successRate(legacy.map((t) => t.success)) * 100).toFixed(0)}%`
			: 'n/a';
		lines.push(`| ${taskId} | ${ocuRate} | ${legacyRate} |`);
	}

	lines.push('', '## Cold start (tools/list)', '');
	lines.push(`- OCU: ${latencyStats(filterTasks(runs, 'ocu', 'cold_start'), 'tools/list')}`);
	if (runs.some((r) => r.variant === 'legacy')) {
		lines.push(`- Legacy: ${latencyStats(filterTasks(runs, 'legacy', 'cold_start'), 'tools/list')}`);
	}

	lines.push('', '## Screenshot / state capture', '');
	lines.push(
		`- OCU get_app_state: ${latencyStats(filterTasks(runs, 'ocu', 'screenshot_latency'), 'get_app_state')}`,
	);
	if (runs.some((r) => r.variant === 'legacy')) {
		lines.push(
			`- Legacy get_screenshot: ${latencyStats(filterTasks(runs, 'legacy', 'screenshot_latency'), 'computer')}`,
		);
	}

	const ocuCap = filterTasks(runs, 'ocu', 'screenshot_latency');
	const legacyCap = filterTasks(runs, 'legacy', 'screenshot_latency');
	if (ocuCap.length && legacyCap.length) {
		const ocuBytes = ocuCap.flatMap((t) => t.calls.map((c) => c.responseBytes));
		const legacyBytes = legacyCap.flatMap((t) => t.calls.map((c) => c.responseBytes));
		lines.push(
			'',
			'## Payload size (screenshot task)',
			'',
			`- OCU response bytes median: ${median(ocuBytes).toFixed(0)}`,
			`- Legacy response bytes median: ${median(legacyBytes).toFixed(0)}`,
		);
	}

	const ocuText = filterTasks(runs, 'ocu', 'textedit_type');
	const legacyText = filterTasks(runs, 'legacy', 'textedit_type');
	lines.push('', '## TextEdit type+verify', '');
	lines.push(`- OCU wall time median: ${median(ocuText.map((t) => t.wallTimeMs)).toFixed(0)}ms`);
	if (legacyText.length) {
		lines.push(`- Legacy wall time median: ${median(legacyText.map((t) => t.wallTimeMs)).toFixed(0)}ms`);
	}

	return lines.join('\n');
}
