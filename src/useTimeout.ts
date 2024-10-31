import { useHookState } from "@rbxts/topo-runtime";

interface Storage {
	time?: number;
	expiry?: number;
}

export function useTimeout(key: unknown, seconds: number, discriminator?: unknown): boolean {
	const storage = useHookState(key, discriminator) as Storage;

	const now = os.clock();

	if (storage.time === undefined) {
		storage.time = now;
		storage.expiry = now + seconds;

		return false;
	}

	return now >= storage.expiry!;
}
