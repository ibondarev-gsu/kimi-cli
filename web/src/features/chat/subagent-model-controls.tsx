import { useCallback, useState, type ReactElement } from "react";
import { toast } from "sonner";
import { Bot, XIcon } from "lucide-react";
import type { GlobalConfig } from "@/lib/api/models";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { cn } from "@/lib/utils";

const INHERIT_VALUE = "__inherit__";

export type SubagentModelControlsProps = {
  config: GlobalConfig | null;
  isUpdating: boolean;
  onUpdate: (subagentModels: Record<string, string>) => Promise<void>;
  className?: string;
};

export function SubagentModelControls({
  config,
  isUpdating,
  onUpdate,
  className,
}: SubagentModelControlsProps): ReactElement | null {
  const [open, setOpen] = useState(false);
  const [pending, setPending] = useState<Record<string, string>>({});

  const builtinTypes = config?.builtinSubagentTypes ?? [];
  const current = config?.subagentModels ?? {};

  const handleChange = useCallback((type: string, modelKey: string) => {
    setPending((prev) => ({ ...prev, [type]: modelKey }));
  }, []);

  const handleSave = useCallback(async () => {
    if (!config) return;
    const merged: Record<string, string> = {};
    for (const t of builtinTypes) {
      const val = pending[t] ?? current[t] ?? "";
      if (val && val !== INHERIT_VALUE) {
        merged[t] = val;
      }
    }
    try {
      await onUpdate(merged);
      toast.success("Subagent models updated");
      setPending({});
      setOpen(false);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Failed to update";
      toast.error("Failed to update subagent models", { description: message });
    }
  }, [builtinTypes, config, current, onUpdate, pending]);

  const handleClear = useCallback((type: string) => {
    setPending((prev) => ({ ...prev, [type]: INHERIT_VALUE }));
  }, []);

  if (builtinTypes.length === 0) {
    return null;
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button
          variant="ghost"
          size="sm"
          className={cn("h-9 justify-start gap-2 border-0", className)}
          aria-label="Configure subagent models"
          type="button"
          disabled={isUpdating || !config}
        >
          <Bot className="size-4 shrink-0" />
          <span className="truncate">Subagents</span>
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Subagent Models</DialogTitle>
        </DialogHeader>
        <div className="space-y-3 py-2">
          {builtinTypes.map((type) => {
            const selected = pending[type] ?? current[type] ?? INHERIT_VALUE;
            return (
              <div key={type} className="flex items-center gap-3">
                <span className="w-20 shrink-0 text-sm font-medium capitalize">
                  {type}
                </span>
                <Select
                  value={selected}
                  onValueChange={(value) => handleChange(type, value)}
                  disabled={isUpdating}
                >
                  <SelectTrigger className="flex-1">
                    <SelectValue placeholder="Inherit parent model" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value={INHERIT_VALUE}>Inherit parent model</SelectItem>
                    {(config?.models ?? []).map((m) => (
                      <SelectItem key={m.name} value={m.name}>
                        {m.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {selected && selected !== INHERIT_VALUE && (
                  <Button
                    variant="ghost"
                    size="icon"
                    className="size-8 shrink-0"
                    onClick={() => handleClear(type)}
                    disabled={isUpdating}
                  >
                    <XIcon className="size-3" />
                  </Button>
                )}
              </div>
            );
          })}
        </div>
        <div className="flex justify-end gap-2">
          <Button
            variant="outline"
            onClick={() => {
              setPending({});
              setOpen(false);
            }}
          >
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={isUpdating}>
            Save
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
