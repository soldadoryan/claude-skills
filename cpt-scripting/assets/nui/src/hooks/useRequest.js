import { useCallback } from "react";
import { isEnvBrowser } from "../utils/misc";

const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : "script";

function useRequest() {
  const request = useCallback(async (method, body = {}, mock = null) => {
    if (isEnvBrowser()) return mock;
    try {
      const response = await fetch(`https://${resourceName}/${method}`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(body),
      });
      return await response.json();
    } catch {
      return null;
    }
  }, []);

  return { request };
}

export default useRequest;
