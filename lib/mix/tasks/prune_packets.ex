defmodule Mix.Tasks.PrunePackets do
  use Mix.Task

  def run(db) do
    IO.inspect "Pruned packets from db"
    Mix.shell.cmd("psql -a #{db} -c 'select prune_packets()'")
  end
end

# function created in psql
# CREATE OR REPLACE FUNCTION prune_packets() RETURNS void AS $$
# BEGIN
#   EXECUTE format($f$delete from packets where inserted_at < NOW() - INTERVAL '30 days'$f$);
#   RAISE NOTICE 'Pruned packets table';
# END;
# $$ LANGUAGE plpgsql;