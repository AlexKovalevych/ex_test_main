defmodule Gt.Fixtures.Payment do
  use Timex
  alias Gt.Repo
  alias Gt.Project
  alias Gt.ProjectUser
  alias Gt.Payment
  import Ecto.Query

  @systems %{
    "c" => "Creditcard",
    "q" => "QIWI",
    "w" => "Webmoney",
    "e" => "Eport",
    "y" => "Yandex",
    "s" => "SmsPay",
    "qd" => "QiwiDirect",
    "a" => "Alphaclick",
    "l" => "LiqPay",
    "yd" => "Яндекс.Деньги",
    "i" => "interkassa",
    "p" => "Privat24",
    "m" => "Moneta",
    "mr" => "Mail.ru",
    "mb" => "Moneybookers",
    "p7" => "Pay777Pins",
    "sw" => "SMSWiz",
    "sp" => "SpryPay"
  }

  @now Timex.now

  def run do
    {:ok, data} = File.read Path.join(__DIR__, "payments.json")
    users = Poison.decode!(data)
    projects = Project
               |> where([p], p.title in ["Loto 1", "Loto 2", "Loto 3", "Loto 4", "Loto 5", "Loto 6", "Loto 7", "Loto 8", "Loto 9"])
               |> Gt.Repo.all

    Enum.each(projects, fn project ->
      users
      |> ParallelStream.map(&insert_payments(project, &1))
      |> Enum.into([])
    end)
  end

  def insert_payments(project, [user_item_id, data]) do
    user_item_id = case project.title do
      "Loto 1" -> user_item_id
      "Loto 2" -> user_item_id <> "2"
      "Loto 3" -> user_item_id <> "3"
      "Loto 4" -> user_item_id <> "4"
      "Loto 5" -> user_item_id <> "5"
      "Loto 6" -> user_item_id <> "32"
      "Loto 7" -> user_item_id <> "7"
      "Loto 8" -> user_item_id <> "8"
      "Loto 9" -> user_item_id <> "9"
    end

    user = ProjectUser
           |> where([pu], pu.project_id == ^project.id)
           |> where([pu], pu.item_id == ^user_item_id)
           |> Repo.one
    ParallelStream.each(data, fn payment ->
      [
        date_past_days,
        hours,
        minutes,
        seconds,
        _traffic_source,
        cash_real,
        item_id,
        state,
        system,
        type
      ] = payment
      date = @now
             |> Timex.shift(days: -date_past_days)
             |> Timex.set([hour: hours, minute: minutes, second: seconds])
             |> Timex.to_naive_datetime()
      cash_real = case project.title do
        "Loto 1" -> cash_real
        "Loto 2" -> round(cash_real * 1.05)
        "Loto 3" -> round(cash_real * 0.85)
        "Loto 4" -> round(cash_real * 1.2)
        "Loto 5" -> round(cash_real * 0.8)
        "Loto 6" -> round(cash_real * 1.1)
        "Loto 7" -> round(cash_real * 0.95)
        "Loto 8" -> round(cash_real * 1.07)
        "Loto 9" -> round(cash_real * 1.11)
      end
      Payment.changeset(%Payment{}, %{
                          item_id: item_id,
                          date: date,
                          type: type,
                          state: state,
                          sum: abs(cash_real),
                          system: @systems[system],
                          project_id: project.id,
                          project_user_id: user.id,
                        })
      |> Repo.insert!
    end)
    |> Enum.into([])
  end

end
