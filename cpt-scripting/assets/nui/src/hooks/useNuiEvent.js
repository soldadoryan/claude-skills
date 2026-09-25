import { useEffect, useRef } from "react";

function useNuiEvent(action, handler) {
  const handlerRef = useRef(handler);

  useEffect(() => {
    handlerRef.current = handler;
  }, [handler]);

  useEffect(() => {
    const listener = (event) => {
      if (event.data?.action === action) handlerRef.current(event.data);
    };
    window.addEventListener("message", listener);
    return () => window.removeEventListener("message", listener);
  }, [action]);
}

export default useNuiEvent;
