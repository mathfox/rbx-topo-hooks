import { useHookState } from "@rbxts/topo-runtime";
import structuredDeepEquals from "./structuredDeepEquals";

interface Storage {
	dependencies?: ReadonlyArray<unknown>;
}

export function useChange(dependencies: ReadonlyArray<unknown>, discriminator?: unknown): boolean {
	const storage = useHookState("useChange", discriminator) as Storage;

	const previous = storage.dependencies;
	storage.dependencies = dependencies;

	return !structuredDeepEquals(dependencies, previous);
}
