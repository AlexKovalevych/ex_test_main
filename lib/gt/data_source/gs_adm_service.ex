defmodule Gt.DataSource.GsAdmService do
  alias Gt.Repo
  alias Gt.Project
  alias Gt.DataSourceRegistry
  alias Gt.GameServerTransaction
  alias Gt.Api.AdmService
  import SweetXml
  require Logger

  def process_file(data_source, {filename, index}, total_files) do
    res = Gt.Uploaders.DataSource.local_path(data_source.id, filename)
    |> File.read!()
    |> HtmlEntities.decode
    |> String.replace("&", "&amp;")
    |> process_data(data_source, index, total_files)
  end

  defp process_data(content, data_source, index, total_files) do
    count = content |> xpath(~x"//data"l) |> Enum.count
    DataSourceRegistry.save(data_source.id, :total, total_files * count)
    DataSourceRegistry.save(data_source.id, :processed, index * count)

    if content |> xpath(~x"//result/@status") != 'ok' do
      message = "Failed to parse AdmService response"
      Logger.info(message)
      raise message
    else
      content
      |> xpath(~x"//data"l,
        id: ~x"@ID"s,
        create_date: ~x"@DateCreate"s,
        date: ~x"@Date"s,
        time: ~x"@Time"s,
        project_id: ~x"@project_id"s,
        sum: ~x"@fCash"i,
        user_sum: ~x"@fCashUser"i,
        system: ~x"@System"s,
        system_id: ~x"@SystemID"I,
        status: ~x"@Status"s,
        status_id: ~x"@StatusID"I,
        pguid: ~x"@PGUID"s,
        project_id: ~x"@project_Id"s
      )
      |> Enum.each(&(upsert_transaction(&1, data_source)))
    end
  end

  defp upsert_transaction(data, data_source) do
    project = Project.by_item_id(Project, data.project_id) |> Repo.one
    [year, month, date] = String.split(data.date, "-") |> Enum.map(&String.to_integer/1)
    [hours, minutes, seconds] = String.split(data.time, ":") |> Enum.map(&String.to_integer/1)
    {:ok, date} = NaiveDateTime.new(year, month, date, hours, minutes, seconds)
    fields = %{
      date: date,
      sum: data.sum,
      user_sum: data.user_sum,
      system: data.system,
      system_id: data.system_id,
      status: data.status,
      status_id: data.status_id,
      pguid: data.pguid,
    }

    transaction = %GameServerTransaction{}
    |> GameServerTransaction.changeset(Map.merge(
      fields,
      %{
        item_id: data.id,
        project_id: project.id
      }
    ))

    on_conflict = [set: Map.to_list(fields)]
    Repo.insert!(transaction, on_conflict: on_conflict, conflict_target: [:item_id, :project_id])
    DataSourceRegistry.increment(data_source.id, :processed)
  end

end
