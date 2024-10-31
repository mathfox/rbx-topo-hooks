import { useHookState } from "@rbxts/topo-runtime";
import structuredDeepEquals from "./structuredDeepEquals";

interface Storage {
	instance?: Instance;
	dependencies?: ReadonlyArray<unknown>;
}

function cleanup(storage: Storage): void {
	storage.instance?.Destroy();
}

/**
 * Destroys the instance returned by `creator` function whether hook is no longer getting called
 * or whenever the `dependencies` change.
 */
export function useInstance<TInstance extends Instance>(
	creator: () => TInstance,
	dependencies: ReadonlyArray<unknown>,
	discriminator?: unknown,
): TInstance {
	const storage = useHookState("useInstance", discriminator, cleanup) as Storage;

	if (!storage.instance || !structuredDeepEquals(dependencies, storage.dependencies)) {
		cleanup(storage);

		storage.dependencies = dependencies;

		storage.instance = creator();
	}

	return storage.instance as TInstance;
}
