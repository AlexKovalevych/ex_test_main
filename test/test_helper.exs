{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.start

#Mix.Task.run "ecto.create", ~w(-r Gt.Repo --quiet)
#Mix.Task.run "ecto.migrate", ~w(-r Gt.Repo --quiet)

