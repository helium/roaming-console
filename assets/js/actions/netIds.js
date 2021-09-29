import * as rest from "../util/rest";
import sanitizeHtml from "sanitize-html";

export const setNetIds = (netIds) => {
  return rest.post("/api/net_ids", { net_ids: netIds })
}
