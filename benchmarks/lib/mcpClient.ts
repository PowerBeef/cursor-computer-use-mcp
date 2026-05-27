import {type ChildProcess, spawn} from 'node:child_process';
import type {ServerConfig, ToolCallRecord} from './types.js';

type JsonRpc = {
	jsonrpc: '2.0';
	id?: number;
	method?: string;
	params?: unknown;
	result?: unknown;
	error?: {message: string};
};

export type McpToolResult = {
	content?: Array<{type: string; text?: string; data?: string; mimeType?: string}>;
	isError?: boolean;
	structuredContent?: unknown;
};

export class BenchmarkMcpClient {
	private proc: ChildProcess | undefined;
	private buffer = '';
	private nextId = 1;
	private pending = new Map<number, {resolve: (v: unknown) => void; reject: (e: Error) => void}>();
	private ready: Promise<void> | undefined;
	private readonly config: ServerConfig;
	private startTime = 0;

	constructor(config: ServerConfig) {
		this.config = config;
	}

	get spawnMs(): number {
		return this.startTime;
	}

	async connect(): Promise<void> {
		if (!this.ready) {
			this.ready = this.start();
		}

		await this.ready;
	}

	async listTools(): Promise<string[]> {
		const result = await this.request<{tools: Array<{name: string}>}>('tools/list', {});
		return result.tools.map((t) => t.name);
	}

	async callTool(name: string, args: Record<string, unknown> = {}): Promise<{
		result: McpToolResult;
		metrics: ToolCallRecord;
	}> {
		const started = performance.now();
		let result: McpToolResult;
		let errorMessage: string | undefined;

		try {
			result = await this.request<McpToolResult>('tools/call', {
				name,
				arguments: args,
			});
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : String(error);
			result = {
				isError: true,
				content: [{type: 'text', text: errorMessage}],
			};
		}

		const durationMs = performance.now() - started;
		const serialized = JSON.stringify(result);
		const responseBytes = Buffer.byteLength(serialized, 'utf8');
		let imageBytes = 0;
		for (const block of result.content ?? []) {
			if (block.type === 'image' && block.data) {
				imageBytes += Buffer.byteLength(block.data, 'utf8');
			}
		}

		const metrics: ToolCallRecord = {
			tool: name,
			args,
			durationMs,
			responseBytes,
			imageBytes,
			isError: Boolean(result.isError) || Boolean(errorMessage),
		};
		if (errorMessage) {
			metrics.errorMessage = errorMessage;
		}

		return {result, metrics};
	}

	/** Baseline single `computer` tool wrapper */
	async callComputer(action: string, extra: Record<string, unknown> = {}): Promise<{
		result: McpToolResult;
		metrics: ToolCallRecord;
	}> {
		return this.callTool('computer', {action, ...extra});
	}

	async close(): Promise<void> {
		for (const {reject} of this.pending.values()) {
			reject(new Error('client closed'));
		}

		this.pending.clear();
		this.ready = undefined;

		if (this.proc && !this.proc.killed) {
			this.proc.kill();
		}

		this.proc = undefined;
	}

	private async start(): Promise<void> {
		const spawnStart = performance.now();
		this.proc = spawn(this.config.command, this.config.args, {
			cwd: this.config.cwd,
			env: {...process.env, ...this.config.env},
			stdio: ['pipe', 'pipe', 'pipe'],
		});

		this.proc.stdout?.on('data', (chunk: Buffer) => {
			this.onData(chunk.toString('utf8'));
		});

		this.proc.stderr?.on('data', () => {
			/* ignore noisy MCP logs */
		});

		await this.request('initialize', {
			protocolVersion: '2024-11-05',
			capabilities: {},
			clientInfo: {name: 'cursor-computer-use-benchmark', version: '1.0.0'},
		});
		this.send({jsonrpc: '2.0', method: 'notifications/initialized'});
		this.startTime = performance.now() - spawnStart;
	}

	private onData(chunk: string): void {
		this.buffer += chunk;
		const lines = this.buffer.split('\n');
		this.buffer = lines.pop() ?? '';

		for (const line of lines) {
			const trimmed = line.trim();
			if (!trimmed) {
				continue;
			}

			let message: JsonRpc;
			try {
				message = JSON.parse(trimmed) as JsonRpc;
			} catch {
				continue;
			}

			if (message.id === undefined) {
				continue;
			}

			const waiter = this.pending.get(message.id);
			if (!waiter) {
				continue;
			}

			this.pending.delete(message.id);
			if (message.error) {
				waiter.reject(new Error(message.error.message));
			} else {
				waiter.resolve(message.result);
			}
		}
	}

	private send(message: JsonRpc): void {
		if (!this.proc?.stdin?.writable) {
			throw new Error('MCP process not writable');
		}

		this.proc.stdin.write(`${JSON.stringify(message)}\n`);
	}

	private request<T>(method: string, params?: unknown): Promise<T> {
		const id = this.nextId++;
		return new Promise<T>((resolve, reject) => {
			this.pending.set(id, {
				resolve: resolve as (v: unknown) => void,
				reject,
			});
			this.send({jsonrpc: '2.0', id, method, params});
		});
	}
}
