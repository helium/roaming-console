import * as rest from "../util/rest";

export const setAlerts = (settings) => {
  rest.post("/api/alerts", { settings }).then((res) => {});
};
