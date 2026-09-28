import { createContext, useContext, useMemo, useState, type ReactNode } from 'react';

type CreateSheetContextValue = {
  open: boolean;
  show: () => void;
  hide: () => void;
};

const CreateSheetContext = createContext<CreateSheetContextValue>({
  open: false,
  show: () => undefined,
  hide: () => undefined,
});

export function CreateSheetProvider({ children }: { children: ReactNode }) {
  const [open, setOpen] = useState(false);
  const value = useMemo(
    () => ({
      open,
      show: () => setOpen(true),
      hide: () => setOpen(false),
    }),
    [open],
  );
  return <CreateSheetContext.Provider value={value}>{children}</CreateSheetContext.Provider>;
}

export function useCreateSheet() {
  return useContext(CreateSheetContext);
}
