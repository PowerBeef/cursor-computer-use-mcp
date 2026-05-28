import {resolve} from 'node:path';
import type {ServerConfig, VariantId} from './types.js';
import {repoRoot} from './paths.js';

const root = repoRoot();

/** Native cairn MCP (9 Codex-style tools). */
export const OCU_SERVER: ServerConfig = {
	id: 'ocu',
	command: process.env.BENCHMARK_OCU_COMMAND || 'cairn',
	args: ['mcp'],
	cwd: root,
};

/** Optional legacy coordinate MCP (single `computer` tool). */
export const LEGACY_SERVER: ServerConfig = {
	id: 'legacy',
	command: 'npx',
	args: ['-y', 'computer-use-mcp'],
	cwd: root,
};

export function getServer(variant: VariantId): ServerConfig {
	return variant === 'legacy' ? LEGACY_SERVER : OCU_SERVER;
}

export function resolveOcuCommandPath(): string | undefined {
	if (process.env.BENCHMARK_OCU_COMMAND) {
		return process.env.BENCHMARK_OCU_COMMAND;
	}

	const bundled = resolve(root, 'artifacts/npm/cairn/bin/cairn');
	return bundled;
}
