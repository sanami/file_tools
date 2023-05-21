import Config

config :logger, :console,
  level: :debug,
  format: "[$level] $metadata $message\n",
  metadata: [:pid]

env_file = Path.expand "#{config_env()}.exs", __DIR__
if File.exists?(env_file), do: import_config(env_file)
