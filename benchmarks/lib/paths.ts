import {resolve} from 'node:path';

/** Repo root (npm scripts run with cwd = project root). */
export function repoRoot(): string {
	return process.cwd();
}

export function fixturePath(name: string): string {
	return resolve(repoRoot(), 'benchmarks/fixtures', name);
}
