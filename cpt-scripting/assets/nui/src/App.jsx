import { useEffect } from "react";
import { useNui } from "./contexts/NuiContext";
import useNuiEvent from "./hooks/useNuiEvent";
import useRequest from "./hooks/useRequest";
import { debugData } from "./utils/misc";

debugData([{ action: "open", data: { products: { water: { price: 50 } } } }]);

function App() {
  const { state, setState } = useNui();
  const { request } = useRequest();

  useNuiEvent("open", (payload) => setState({ action: "open", ...payload.data }));
  useNuiEvent("close", () => setState({}));

  useEffect(() => {
    const onKeyDown = (event) => {
      if (event.key === "Escape") {
        setState({});
        request("close");
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [request, setState]);

  if (state.action !== "open") return null;

  return <main />;
}

export default App;
