defmodule Lab2.Application do
  use Application

  @registry :workers_registry

  def start(_type, _args) do
    children = [
      {
        Registry,
        [keys: :unique, name: @registry]
      },
      {
        DynSupervisor,
        []
      },
      %{
        id: Fetch,
        start: {
          Fetch, :start_link, [
            "http://localhost:4000/legacy_sensors",
            "http://localhost:4000/iot",
            "http://localhost:4000/sensors"
          ]
        }
      },
      %{
        id: MessageBroker,
        start: {MessageBroker, :start_link, []}
      },
      %{
        id: Router,
        start: {Router, :start_link, []}
      },
      %{
        id: Aggregator,
        start: {Aggregator, :start_link, []}
      },
      %{
        id: FlowRouter,
        start: {FlowRouter, :start_link, []}
      },
      %{
        id: FlowAggr,
        start: {FlowAggr, :start_link, []}
      },
      %{
        id: JoinSensors,
        start: {JoinSensors, :start_link, []}
      },
      %{
        id: Forecast,
        start: {Forecast, :start_link, []}
      }

    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
    receive do
    end
  end
end
