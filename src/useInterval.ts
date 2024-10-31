import { useHookState } from "@rbxts/topo-runtime";

interface Storage {
	time?: number;
	expiry?: number;
}

export function useInterval(seconds: number, discriminator?: unknown): boolean {
	const storage = useHookState("useInterval", discriminator) as Storage;

	const now = os.clock();

	if (storage.time === undefined) {
		storage.time = now;
		storage.expiry = now + seconds;

		return false;
	}

	if (now >= storage.expiry!) {
		storage.time = now;
		storage.expiry = now + seconds;

		return true;
	}

	return false;
}
