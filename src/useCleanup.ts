import { useHookState } from "@rbxts/topo-runtime";
import structuredDeepEquals from "./structuredDeepEquals";

interface Storage {
	cb?: Callback;
	dependencies?: ReadonlyArray<unknown>;
}

function cleanup(storage: Storage): void {
	storage.cb?.();
}

export function useCleanup(callback: Callback, dependencies: ReadonlyArray<unknown>, discriminator?: unknown): void {
	const storage = useHookState(discriminator, cleanup) as Storage;

	if (!storage.cb || !structuredDeepEquals(dependencies, storage.dependencies)) {
		cleanup(storage);

		storage.dependencies = dependencies;

		storage.cb = callback();
	}
}