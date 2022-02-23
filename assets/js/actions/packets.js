import * as rest from "../util/rest";

export const getPackets = async () => {
  const packets = await rest.get("/api/packets/");
  return packets.data;
};
