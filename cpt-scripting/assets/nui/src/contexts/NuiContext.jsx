import { createContext, useContext, useMemo, useState } from "react";

const NuiContext = createContext(null);

export function NuiProvider({ children }) {
  const [state, setState] = useState({});
  const value = useMemo(() => ({ state, setState }), [state]);
  return <NuiContext.Provider value={value}>{children}</NuiContext.Provider>;
}

export function useNui() {
  return useContext(NuiContext);
}
