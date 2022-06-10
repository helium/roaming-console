import * as rest from "../util/rest";
import { displayError } from "../util/messages";

export const updateNetIdConfig = (id, config) => {
  return rest.put(`/api/net_ids/${id}`, {
    protocol: config.protocol,
    ...(config.config_id && { config_id: config.config_id }),
    ...(config.address && { address: config.address }),
    ...(config.port && { port: config.port }),
    ...(config.disable_pull_data && {
      disable_pull_data: config.disable_pull_data,
    }),
    ...(config.http_endpoint && { http_endpoint: config.http_endpoint }),
    ...(config.http_flow_type && { http_flow_type: config.http_flow_type }),
    ...(config.http_dedupe_timeout && {
      http_dedupe_timeout: config.http_dedupe_timeout,
    }),
    join_credentials: config.join_credentials,
    multi_buy: config.multi_buy,
    ...(config.http_auth_header && {
      http_headers: { auth: config.http_auth_header },
    }),
    devaddrs: config.devaddrs,
  });
};

export const updateNetIdConfigActive = (id, config_id, active) => {
  return rest.put(`/api/net_ids/${id}`, {
    config_id,
    active,
  });
};
