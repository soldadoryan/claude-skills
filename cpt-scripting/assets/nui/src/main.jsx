import React from "react";
import ReactDOM from "react-dom/client";
import "@fontsource/montserrat/400.css";
import "@fontsource/montserrat/600.css";
import "@fontsource/montserrat/700.css";
import "./styles/variables.css";
import "./styles/global.css";
import { NuiProvider } from "./contexts/NuiContext";
import App from "./App";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <NuiProvider>
      <App />
    </NuiProvider>
  </React.StrictMode>,
);
