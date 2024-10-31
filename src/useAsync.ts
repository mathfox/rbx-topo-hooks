import { useHookState } from "@rbxts/topo-runtime";
import structuredDeepEquals from "./structuredDeepEquals";

interface Storage<TValue> {
	dependencies: ReadonlyArray<unknown>;
	promise?: Promise<TValue>;
	status: Promise.Status;
	settleValue?: TValue | unknown;
}

function cleanup(storage: Storage<unknown>) {
	storage.promise?.cancel();
}

export function useAsync<TValue>(
	callback: () => Promise<TValue>,
	dependencies: ReadonlyArray<unknown>,
	discriminator?: unknown,
): LuaTuple<
	| [status: PromiseConstructor["Status"]["Started"], undefined]
	| [status: PromiseConstructor["Status"]["Resolved"], value: TValue]
	| [status: PromiseConstructor["Status"]["Rejected"], errorValue: unknown]
	| [status: PromiseConstructor["Status"]["Cancelled"], undefined]
>;

/**
 * The type of `value` will be `undefined` in case if the promise has not been resolved.
 */
export function useAsync(
	callback: () => Promise<unknown>,
	dependencies: ReadonlyArray<unknown>,
	discriminator?: unknown,
) {
	const storage = useHookState("useAsync", discriminator, cleanup) as Storage<unknown>;

	if (!structuredDeepEquals(dependencies, storage.dependencies)) {
		cleanup(storage);

		storage.dependencies = dependencies;

		const promise = callback();

		storage.promise = promise;
		storage.status = "Started";

		promise.then(
			(value) => {
				storage.settleValue = value;
			},
			(errorValue) => {
				storage.settleValue = errorValue;
			},
		);

		promise.finally(() => {
			storage.status = promise.getStatus();
		});
	}

	return $tuple(storage.status, storage.settleValue);
}
