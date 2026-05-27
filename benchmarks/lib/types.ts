export type VariantId = 'ocu' | 'legacy';

export type ServerConfig = {
	id: VariantId;
	command: string;
	args: string[];
	cwd?: string;
	env?: Record<string, string>;
};

export type ToolCallRecord = {
	tool: string;
	args?: Record<string, unknown>;
	durationMs: number;
	responseBytes: number;
	imageBytes: number;
	isError: boolean;
	errorMessage?: string;
};

export type TaskResult = {
	taskId: string;
	variant: VariantId;
	trial: number;
	success: boolean;
	wallTimeMs: number;
	steps: number;
	calls: ToolCallRecord[];
	notes?: string;
};

export type TrialRun = {
	variant: VariantId;
	trials: number;
	tasks: TaskResult[];
	metadata: Record<string, string>;
};
