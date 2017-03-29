defmodule Gt.Api.Wl.Stats do
  @derive [Poison.Encoder]

  defstruct [:date,
             :rounds,
             :bets,
             :wins,
             :deposits_sum,
             :deposits_count,
             :payouts_sum,
             :payouts_count,
             :refunds_sum,
             # RFD - real first deposit/depositor - сколько человек совершили свой первый депозит
             # за месяц или в конкретный день (в случае посуточной статистики)
             :rfd,
             :hits,
             :hosts,
             :registrations,
             :players_real,
             :players
           ]
end
