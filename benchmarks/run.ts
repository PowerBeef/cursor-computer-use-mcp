#!/usr/bin/env node
import {mkdirSync} from 'node:fs';
import {join} from 'node:path';
import {getEnvironmentMetadata, runPreflight} from './lib/preflight.js';
import {OCU_SERVER, LEGACY_SERVER} from './lib/servers.js';
import type {TaskResult, TrialRun, VariantId} from './lib/types.js';
import {writeReport} from './report.js';
import {runColdStartTask} from './tasks/cold-start.js';
import {runPolicyTask} from './tasks/policy.js';
import {runScreenshotLatencyTask} from './tasks/screenshot-latency.js';
import {runTextEditTypeTask} from './tasks/textedit-type.js';

const TRIALS = Number(process.env.BENCHMARK_TRIALS || '3');

function variantsToRun(): VariantId[] {
	const variants: VariantId[] = ['ocu'];
	if (process.env.BENCHMARK_LEGACY === '1') {
		variants.push('legacy');
	}

	return variants;
}

async function runVariant(variant: VariantId, trials: number): Promise<TrialRun> {
	const tasks: TaskResult[] = [];
	const taskRunners = [
		runColdStartTask,
		runScreenshotLatencyTask,
		runTextEditTypeTask,
		runPolicyTask,
	];

	for (let trial = 1; trial <= trials; trial++) {
		console.log(`\n[${variant}] trial ${trial}/${trials}`);
		for (const runner of taskRunners) {
			const taskId = runner.name;
			console.log(`  → ${taskId}...`);
			const result = await runner(variant, trial);
			tasks.push(result);
			console.log(`    ${result.success ? 'OK' : 'FAIL'} ${result.taskId} (${result.steps} steps, ${result.wallTimeMs.toFixed(0)}ms)`);
		}
	}

	return {
		variant,
		trials,
		tasks,
		metadata: getEnvironmentMetadata(),
	};
}

async function main(): Promise<void> {
	const preflight = runPreflight();
	console.log('Preflight:');
	for (const m of preflight.messages) {
		console.log(`  ${m}`);
	}

	if (!preflight.ok) {
		process.exit(1);
	}

	const variants = variantsToRun();
	console.log(`\nBenchmark: ${TRIALS} trials per variant (${variants.join(', ')})`);
	console.log(`  OCU: ${OCU_SERVER.command} ${OCU_SERVER.args.join(' ')}`);
	if (variants.includes('legacy')) {
		console.log(`  Legacy: ${LEGACY_SERVER.command} ${LEGACY_SERVER.args.join(' ')}`);
	}

	const stamp = new Date().toISOString().replace(/[:.]/g, '-');
	const outDir = join(process.cwd(), 'benchmarks', 'results', stamp);
	mkdirSync(outDir, {recursive: true});

	const runs: TrialRun[] = [];
	for (const variant of variants) {
		runs.push(await runVariant(variant, TRIALS));
	}

	writeReport(outDir, runs);

	const latestDir = join(process.cwd(), 'benchmarks', 'results', 'latest');
	try {
		const {rmSync, symlinkSync} = await import('node:fs');
		rmSync(latestDir, {force: true, recursive: true});
		symlinkSync(outDir, latestDir, 'dir');
	} catch {
		/* ignore symlink errors */
	}

	console.log(`\nDone. Results: ${outDir}`);
}

main().catch((error) => {
	console.error(error);
	process.exit(1);
});
