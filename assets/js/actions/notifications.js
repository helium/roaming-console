import * as rest from "../util/rest";

export const setNotifications = (settings) => {
  rest.post("/api/notifications", { settings })
  .then(res => {})
}
