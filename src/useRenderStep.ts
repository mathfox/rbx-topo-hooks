import { HttpService, RunService } from "@rbxts/services";
import { useDestructor } from "./useDestructor";
import { useMemo } from "./useMemo";

interface RenderStepOptions {
	discriminator?: unknown;
	name?: string;
	priority?: number;
}

export function useRenderStep(
	callback: (deltaTime: number) => void,
	options?: RenderStepOptions,
): void {
	const actualName = useMemo(
		() => {
			return options?.name || HttpService.GenerateGUID(false);
		},
		[],
		options?.discriminator,
	);

	const actualPriority = useMemo(
		() => {
			return options?.priority || Enum.RenderPriority.Last.Value;
		},
		[],
		options?.discriminator,
	);

	useDestructor(
		() => {
			RunService.BindToRenderStep(actualName, actualPriority, callback);

			return () => {
				RunService.UnbindFromRenderStep(actualName);
			};
		},
		[],
		options?.discriminator,
	);
}
