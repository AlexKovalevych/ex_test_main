defmodule Gt.DataSource.GsAdmService do
  #alias Gt.Api.EventLogResponse
  #alias Gt.Api.EventLogEvent
  #alias Gt.DataSourceRegistry
  #alias Gt.ProjectUser
  #alias Gt.Payment
  #alias Gt.Repo
  #alias Gt.Api.EventLog, as: Api
  #alias Gt.Api.WlRest, as: WlApi
  import SweetXml
  require Logger

  def process_file(data_source, {filename, index}, total_files) do
    Gt.Uploaders.DataSource.local_path(data_source.id, filename)
    |> File.read!()
    |> process_data(data_source, index, total_files)
  end

  defp process_data(content, data_source, index, total_files) do
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
        pguid: ~x"@PGUID"s
      )
    end
    #count = Enum.count(events)
    #Logger.info("Parsing #{count} items")
    #DataSourceRegistry.delete(data_source.id, :new_user_stats)
    #DataSourceRegistry.save(data_source.id, :total, total_files * count)
    #DataSourceRegistry.save(data_source.id, :processed, index * count)

    #events
    #|> ParallelStream.each(fn event ->
      #case event.name do
        #"user_register" -> new_user_event(data_source, event)
        #"user_changed" -> change_event(data_source, event)
        #"user_emailconfirm" -> email_confirm(data_source, event)
        #"user_depositcomplete" -> payment_event(data_source, event)
        #"user_cashoutcomplete" -> payment_event(data_source, event)
        #"user_depositerror" -> payment_event(data_source, event)
        #"user_cashoutcancel" -> payment_event(data_source, event)
        #_ -> nil
      #end
      #DataSourceRegistry.increment(data_source.id, :processed)
    #end)
    #|> Enum.reduce(0, fn _, acc -> acc + 1 end)
    #user_ids = DataSourceRegistry.find(data_source.id, :new_user_stats) || []
    #Logger.info("Processing new user stats for #{Enum.count(user_ids)} users")
    #user_ids
    #|> Enum.each(fn {_, {user, from, to, count}} ->
      #ProjectUser.calculate_stats(user, from, to)
      #ProjectUser.deps_wdrs_cache(user)
      #ProjectUser.calculate_vip_levels(user)
    #end)
  end

end
#
        #if (!isset($xmlArray['@attributes']['status']) || $xmlArray['@attributes']['status'] != 'ok') {
            #return null;
        #}

        #if (!isset($xmlArray['data']) || !is_array($xmlArray['data'])) {
            #return array();
        #}

        #if (isset($xmlArray['data']['@attributes'])) {
            #$xmlArray['data'] = [['@attributes' => $xmlArray['data']['@attributes']]];
        #}

        #$transactions = array();
        #foreach ($xmlArray['data'] as $item) {

            #if (!isset($item['@attributes']) || !is_array($item['@attributes'])) {
                #continue;
            #}

            #$item = $item['@attributes'];
            #$transaction = new Transaction();

            #$transaction->setId(isset($item['ID']) ? trim($item['ID']) : 0);
            #$transaction->setCreateDate(isset($item['DateCreate']) ? new \DateTime($item['DateCreate']) : null);
            #$transaction->setCommitDateTime(
                #isset($item['Date']) && isset($item['Time']) ? new \DateTime($item['Date'] . ' ' . $item['Time']) : null
            #);

            #$projectId = isset($item['project_id']) ? intval($item['project_id']) : null;
            #if ($this->is170()) {
                #$projectId = $this->get170Id();
            #}

            #$transaction->setCash(isset($item['fCash']) ? intval($item['fCash']) : null);
            #$transaction->setCashUser(isset($item['fCashUser']) ? intval($item['fCashUser']) : null);
            #$transaction->setLosses(isset($item['fLosses']) ? intval($item['fLosses']) : null);
            #$transaction->setUserId(isset($item['UserID']) ? trim($item['UserID']) : null);
            #$transaction->setOrderId(isset($item['OrderID']) ? trim($item['OrderID']) : null);
            #$transaction->setProjectId($projectId);
            #$transaction->setIsActive(isset($item['fActive']) ? (bool)$item['fActive'] : null);
            #$transaction->setComment(isset($item['fComment']) ? $item['fComment'] : null);
            #$transaction->setSystemId(isset($item['SystemID']) ? trim($item['SystemID']) : null);
            #$transaction->setSystem(isset($item['System']) ? $item['System'] : null);
            #$transaction->setStatusId(isset($item['StatusID']) ? trim($item['StatusID']) : null);
            #$transaction->setStatus(isset($item['Status']) ? $item['Status'] : null);
            #$transaction->setInfo(isset($item['Info']) ? $item['Info'] : null);
            #$transaction->setUserLogin(isset($item['UserLogin']) ? $item['UserLogin'] : null);
            #$transaction->setPGUID(isset($item['PGUID']) ? $item['PGUID'] : null);

            #$transactions[] = $transaction;
        #}

        #return $transactions;

