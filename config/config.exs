import Config

config :logger,
  level: :debug,
  backends: [:console]

env_file = "#{config_env()}.exs"
if File.exists?("config/#{env_file}"), do: import_config(env_file)
