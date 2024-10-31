import { getKey, useHookState } from "@rbxts/topo-runtime";

interface Storage<TValue> {
	value?: {
		value: TValue;
	};
}

/**
 * The `key` argument serves as discriminator for `useHookState`.
 */
export function useMap<TValue>(defaultValue: TValue, discriminator?: unknown, key: unknown = getKey()): { value: TValue } {
	const storage = useHookState(key, discriminator) as Storage<TValue>;

	storage.value ??= {
		value: defaultValue,
	};

	return storage.value;
}
