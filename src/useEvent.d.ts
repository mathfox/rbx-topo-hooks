type ConnectionLike =
	| { Disconnect(): void }
	| { disconnect(): void }
	| { Destroy(): void }
	| { destroy(): void }
	| (() => void);

type SignalLike<TArgs extends ReadonlyArray<any>> =
	| { Connect(callback: (...args: TArgs) => void): ConnectionLike }
	| { connect(callback: (...args: TArgs) => void): ConnectionLike }
	| { on(callback: (...args: TArgs) => void): ConnectionLike };

type InferSignalParameters<TValue> = TValue extends SignalLike<infer TParams> ? TParams : never;

declare function useEvent
    <TInstance extends Instance, TEvent extends InstanceEventNames<TInstance>>
    (instance: TInstance, event: TEvent, key?: unknown)
    : IterableFunction<LuaTuple<[index: number, ...rest: InferSignalParameters<InstanceEvents<TInstance>[TEvent]>]>>;

declare function useEvent
    <TParams extends ReadonlyArray<any>, TEvent extends SignalLike<TParams>>
    (discriminator: unknown, event: TEvent, key?: unknown)
    : IterableFunction<LuaTuple<[index: number, ...rest: InferSignalParameters<TEvent>]>>;

export = useEvent;