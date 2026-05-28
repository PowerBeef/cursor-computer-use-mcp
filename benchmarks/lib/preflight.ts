import {execSync} from 'node:child_process';
import {existsSync} from 'node:fs';
import {resolveOcuCommandPath} from './servers.js';
import {repoRoot} from './paths.js';

export function runPreflight(): {ok: boolean; messages: string[]} {
	const messages: string[] = [];
	let ok = true;

	if (process.platform !== 'darwin') {
		messages.push('ERROR: benchmarks require macOS');
		ok = false;
	}

	const ocuCommand = process.env.BENCHMARK_OCU_COMMAND || 'cairn';
	try {
		execSync(`command -v ${ocuCommand}`, {stdio: 'ignore'});
		messages.push(`OK: ${ocuCommand} on PATH`);
	} catch {
		const bundled = resolveOcuCommandPath();
		if (bundled && existsSync(bundled)) {
			messages.push(`WARN: ${ocuCommand} not on PATH; set BENCHMARK_OCU_COMMAND=${bundled}`);
		} else {
			messages.push(`ERROR: ${ocuCommand} not found (run npm run npm:build or npm i -g cairn)`);
			ok = false;
		}
	}

	if (process.env.BENCHMARK_LEGACY === '1') {
		messages.push('INFO: legacy variant enabled (npx computer-use-mcp)');
	}

	messages.push(`repo: ${repoRoot()}`);
	return {ok, messages};
}

export function getEnvironmentMetadata(): Record<string, string> {
	return {
		platform: process.platform,
		arch: process.arch,
		node: process.version,
		ocuCommand: process.env.BENCHMARK_OCU_COMMAND || 'cairn',
		legacyEnabled: process.env.BENCHMARK_LEGACY === '1' ? 'yes' : 'no',
	};
}
