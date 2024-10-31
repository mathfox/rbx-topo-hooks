import { getKey, useHookState } from "@rbxts/topo-runtime";
import structuredDeepEquals from "./structuredDeepEquals";

interface Storage {
	dependencies?: ReadonlyArray<unknown>;
}

export function useChange(
    dependencies: ReadonlyArray<unknown>,
    discriminator?: unknown,
    key: unknown = getKey(),
): boolean {
	const storage = useHookState(key, discriminator) as Storage;

	const previous = storage.dependencies;
	storage.dependencies = dependencies;

	return !structuredDeepEquals(dependencies, previous);
}
