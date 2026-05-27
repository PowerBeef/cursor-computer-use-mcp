export function percentile(values: number[], p: number): number {
	if (values.length === 0) {
		return 0;
	}

	const sorted = [...values].sort((a, b) => a - b);
	const index = Math.ceil((p / 100) * sorted.length) - 1;
	return sorted[Math.max(0, index)] ?? 0;
}

export function median(values: number[]): number {
	return percentile(values, 50);
}

export function summarizeNumbers(values: number[]): {median: number; p95: number; min: number; max: number; n: number} {
	if (values.length === 0) {
		return {median: 0, p95: 0, min: 0, max: 0, n: 0};
	}

	return {
		median: median(values),
		p95: percentile(values, 95),
		min: Math.min(...values),
		max: Math.max(...values),
		n: values.length,
	};
}

export function successRate(successes: boolean[]): number {
	if (successes.length === 0) {
		return 0;
	}

	return successes.filter(Boolean).length / successes.length;
}
