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
    (key: unknown, instance: TInstance, event: TEvent)
    : IterableFunction<LuaTuple<[index: number, ...rest: InferSignalParameters<InstanceEvents<TInstance>[TEvent]>]>>;

declare function useEvent
    <TParams extends ReadonlyArray<any>, TEvent extends SignalLike<TParams>>
    (key: unknown, discriminator: unknown, event: TEvent)
    : IterableFunction<LuaTuple<[index: number, ...rest: InferSignalParameters<TEvent>]>>;

export = useEvent;