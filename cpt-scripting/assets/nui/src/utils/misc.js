export const isEnvBrowser = () => !window.invokeNative;

export const debugData = (events, timeout = 500) => {
  if (!import.meta.env.DEV || !isEnvBrowser()) return;
  events.forEach((data) => {
    setTimeout(() => window.dispatchEvent(new MessageEvent("message", { data })), timeout);
  });
};
