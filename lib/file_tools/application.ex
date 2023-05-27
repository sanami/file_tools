defmodule FileTools.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    if Mix.env() == :test do
      {:ok, self()}
    else
      children = [
        {FileTools.FileSupervisor, 1},
        {FileTools.FileDispatcher, 2}
      ]

      opts = [strategy: :rest_for_one, name: FileTools.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
end
