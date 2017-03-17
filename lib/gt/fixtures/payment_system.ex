defmodule Gt.Fixtures.PaymentSystem do
  alias Gt.Repo
  alias Gt.PaymentSystem
  alias Gt.PaymentSystemFields
  alias Gt.PaymentSystemFee
  alias Gt.PaymentSystemReport
  alias Gt.PaymentSystemOneGamepay

  @payment_systems [
    {
      "Interkassa",
      nil,
      %PaymentSystemFields{
        map_id: "Interkassa invoice",
        date: "Processed",
        sum: "Payment amount",
        currency: "Currency",
        default_payment_type: "In",
        account_id: "Checkout name",
        player_purse: "Purse",
        state: "State",
      },
      %PaymentSystemOneGamepay{
        payment_system: "Interkassa",
        map_id: "Checkout payment number",
      },
      nil,
      nil
    },
    #%{
      #name: "Moneta",
      #defaultPaymentType: "In",
      #delimiter: ";",
      #mappedAccountId: "Merchant Account ID",
      #mappedComment: "Description",
      #mappedCurrency: "Currency",
      #mappedDate: "Date",
      #mappedFee: "Fee",
      #mappedFeeCurrency: "Currency",
      #mappedId: "#",
      #mappedPaymentType: "Category",
      #mappedPlayerPurse: "User Account ID",
      #mappedProjectGUID: "Description",
      #mappedStatus: "Status",
      #mappedStatusIn: [ "BUSINESS" ],
      #mappedStatusOut: [ "WITHDRAWAL" ],
      #mappedSum: "Amount",
      #oneGamepayPaymentSystem: "moneta",
      #oneGamepayTransactionId: "Client Transaction ID",
      #processingScript: "moneta"
    #},
    #%{
      #defaultAccountId: "Neteller_%%currency%%",
      #defaultPaymentType: "In",
      #mappedCurrency: "Currency",
      #mappedDate: "Date",
      #mappedFee: "Fee",
      #mappedFeeCurrency: "Currency",
      #mappedId: "NETELLER Trans. ID",
      #mappedPaymentType: "Type",
      #mappedPlayerPurse: "Account ID",
      #mappedStatus: "Status",
      #mappedStatusIn: [ "Incoming" ],
      #mappedStatusOk: "Accepted",
      #mappedStatusOut: [ "Outgoing" ],
      #mappedSum: "Amount",
      #name: "Neteller",
      #oneGamepayPaymentSystem: "neteller",
      #oneGamepayTransactionId: "Merchant Ref. ID",
    #},
    #%{
      #defaultAccountId: "Yandex 18884",
      #defaultPaymentType: "In",
      #delimiter: ";",
      #mappedComment: "Description",
      #mappedCurrency: "Payment currency",
      #mappedDate: "Date and time of payment",
      #mappedFee: "Payment amount less fee",
      #mappedFeeCurrency: "Payment currency",
      #mappedId: "Transaction number",
      #mappedPlayerPurse: "E-wallet number",
      #mappedSum: "Gross payment amount",
      #name: "Yandex IN",
      #oneGamepayPaymentSystem: "yandex",
      #processingScript: "yandex_in",
    #},
    #%{
      #defaultPaymentType: "In",
      #delimiter: ",",
      #mappedAccountId: "Account",
      #mappedComment: "Merchant's comment",
      #mappedCurrency: "Transaction currency ID",
      #mappedDate: "Report date",
      #mappedFee: "Settlement fee",
      #mappedFeeCurrency: "Settlement currency ID",
      #mappedId: "Transaction number",
      #mappedPaymentType: "Type",
      #mappedPlayerPurse: "QW ID",
      #mappedProjectGUID: "Merchant's comment",
      #mappedReportCurrency: "Settlement currency ID",
      #mappedReportSum: "Settlement amount",
      #mappedStatus: "Transaction status",
      #mappedStatusIn: [ "Payment" ],
      #mappedStatusOk: "Successful",
      #mappedStatusOut: [ "Payout" ],
      #mappedSum: "Transaction amount",
      #name: "QIWI",
      #oneGamepayPaymentSystem: "qiwi",
      #oneGamepayTransactionId: "Merchant's transaction/invoice number",
      #processingScript: "qiwi",
    #},
    #%{
      #defaultAccountId: "%%account%%__%%currency%%",
      #defaultPaymentType: "In",
      #mappedAccountId: "Merchant Account Short Name",
      #mappedCurrency: "Currency",
      #mappedDate: "Transaction Creation Date and Time",
      #mappedId: "Transaction ID (GuWID)",
      #mappedPaymentType: "Transaction Type",
      #mappedReportCurrency: "Currency",
      #mappedReportSum: "Amount",
      #mappedStatus: "Transaction Status",
      #mappedStatusIn: [ "BookPreAuth", "Transaction", "Capture" ],
      #mappedStatusOk: "OK",
      #mappedStatusOut: [ "Original Credits", "Bookback" ],
      #mappedSum: "Amount",
      #name: "WireCard",
      #processingScript: "wirecard",
    #},
    #%{
      #defaultAccountId: "PSC_EUR",
      #defaultFeeCurrency: "EUR",
      #defaultPaymentType: "In",
      #calculatedTransactionPercent: 10.25,
      #mappedCurrency: "Currency",
      #mappedDate: "Date and time of completion of transaction",
      #mappedId: "Transaction ID",
      #mappedPaymentType: "Transaction type",
      #mappedReportCurrency: "Channel currency",
      #mappedReportSum: "Channel amount",
      #mappedStatus: "Transaction status",
      #mappedStatusIn: [ "purchase" ],
      #mappedStatusOk: "success",
      #mappedSum: "Amount",
      #name: "PaySafeCard_EUR",
      #oneGamepayPaymentSystem: "paysafecard",
      #processingScript: "pay_safe_card"
    #},
    {
      "Accentpay IN",
      nil,
      %PaymentSystemFields{
        map_id: "Transaction ID",
        date: "Date and time of completion of transaction",
        sum: "Channel amount",
        currency: "Channel currency",
        default_payment_type: "In",
        account_id: "Checkout name",
        player_purse: "Purse",
        state: "Transaction status",
        state_ok: "success"
      },
      %PaymentSystemOneGamepay{
        payment_system: "Interkassa",
        map_id: "Order",
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        percent: 6.0,
        divide_100: true,
        fee_report: false,
      },
      %PaymentSystemReport{
        divide_100: false
      }
    },
    #%{
      #calculatedTransactionAmount: 50.0,
      #calculatedTransactionPercent: 2.7,
      #defaultAccountId: "accent_cards",
      #defaultFeeAccountId: "AccentMobile",
      #defaultPaymentType: "Out",
      #mappedCurrency: "Currency",
      #mappedDate: "Date and time of completion of transaction",
      #mappedFeeCurrency: "Channel currency",
      #mappedId: "Order",
      #mappedReportCurrency: "Channel currency",
      #mappedReportSum: "Channel amount",
      #mappedStatus: "Transaction status",
      #mappedStatusOk: "Success",
      #mappedSum: "Amount",
      #name: "Accentpay OUT",
      #oneGamepayPaymentSystem: "visa|mastercard|maestro|american express|diners club|jcb|discover|solo|switch",
      #oneGamepayTransactionId: "Transaction ID",
      #processingScript: "accentpay_out",
    #},
    #%{
      #calculatedTransactionPercent: 2.0,
      #defaultAccountId: "9526_%%currency%%",
      #defaultPaymentType: "Out",
      #mappedAccountId: "Провайдер",
      #mappedCurrency: "Валюта суммы к отправке",
      #mappedDate: "Создан",
      #mappedFeeCurrency: "Валюта суммы к отправке",
      #mappedId: "ID инвойса",
      #mappedStatus: "Статус",
      #mappedStatusOk: "paid",
      #mappedSum: "Сумма к отправке в валюте запроса",
      #name: "DengiOnline OUT",
      #oneGamepayPaymentSystem: "wm",
      #oneGamepayTransactionId: "Номер транзакции",
      #processingScript: "dengionline_out"
    #},
    #%{
      #defaultAccountId: "9294/DOL_%%currency%%",
      #defaultPaymentType: "In",
      #mappedCurrency: "Платежная группа",
      #mappedDate: "Дата создания",
      #mappedId: "ID",
      #mappedStatus: "Статус",
      #mappedStatusOk: "Платёж проведён успешно",
      #mappedSum: "Сумма (руб)",
      #name: "DengiOnline IN",
      #oneGamepayPaymentSystem: "wm",
      #oneGamepayTransactionId: "OrderId",
      #processingScript: "dengionline_in",
    #},
    #%{
      #defaultAccountId: "Scrill_pm_%%currency%%",
      #defaultPaymentType: "In",
      #mappedComment: "More Information",
      #mappedCurrency: "Currency Sent",
      #mappedDate: "Time (CET)",
      #mappedFee: "4",
      #mappedFeeCurrency: "Currency Sent",
      #mappedId: "ID of the coresponding Skrill transaction",
      #mappedPaymentType: "Type",
      #mappedStatus: "Status",
      #mappedStatusIn: [ "Receive Money" ],
      #mappedStatusOk: "processed",
      #mappedStatusOut: [ "Send Money" ],
      #mappedSum: "Amount Sent",
      #name: "Skrill PM",
      #oneGamepayPaymentSystem: "MoneyBookers",
      #oneGamepayTransactionId: "Reference",
      #processingScript: "skrill_pm",
    #},
    #%{
      #defaultAccountId: "Skrill_PM_A_%%currency%%",
      #defaultPaymentType: "In",
      #mappedComment: "More Information",
      #mappedCurrency: "5",
      #mappedDate: "Time (CET)",
      #mappedFee: "4",
      #mappedFeeCurrency: "5",
      #mappedId: "ID of the coresponding Skrill transaction",
      #mappedPaymentType: "Type",
      #mappedStatus: "Status",
      #mappedStatusIn: [ "Receive Money" ],
      #mappedStatusOk: "processed",
      #mappedStatusOut: [ "Send Money" ],
      #mappedSum: "5",
      #name: "Skrill PM A",
      #oneGamepayPaymentSystem: "MoneyBookers",
      #oneGamepayTransactionId: "Reference",
      #processingScript: "skrill_pm_a",
    #},
    #%{
      #defaultAccountId: "Scrill_ggs",
      #defaultPaymentType: "In",
      #mappedComment: "More Information",
      #mappedCurrency: "Currency Sent",
      #mappedDate: "Time (CET)",
      #mappedFee: "4",
      #mappedFeeCurrency: "Currency Sent",
      #mappedId: "ID of the coresponding Skrill transaction",
      #mappedPaymentType: "Type",
      #mappedStatus: "Status",
      #mappedStatusIn: [ "Receive Money" ],
      #mappedStatusOk: "processed",
      #mappedStatusOut: [ "Send Money" ],
      #mappedSum: "Amount Sent",
      #name: "Skrill GGS",
      #oneGamepayPaymentSystem: "MoneyBookers",
      #oneGamepayTransactionId: "Reference",
      #processingScript: "skrill_ggs",
    #},
    #%{
      #defaultPaymentType: "Refund",
      #delimiter: ";",
      #mappedCurrency: "3",
      #mappedDate: "5",
      #mappedId: "1",
      #mappedPlayerPurse: "4",
      #mappedSum: "2",
      #name: "Yandex Refund",
      #processingScript: "yandex_refund",
    #},
    #%{
      #calculatedTransactionPercent: 1.0,
      #defaultAccountId: "Yandex 200462",
      #defaultPaymentType: "Out",
      #delimiter: ";",
      #mappedCurrency: "3",
      #mappedDate: "5",
      #mappedId: "1",
      #mappedPlayerPurse: "4",
      #mappedSum: "2",
      #name: "Yandex OUT",
      #processingScript: "yandex_out",
    #},
    #%{
      #calculatedTransactionPercent: 10.25,
      #defaultAccountId: "PSC_SEK",
      #defaultCurrency: "SEK",
      #defaultFeeCurrency: "SEK",
      #defaultPaymentType: "In",
      #mappedCurrency: "Currency",
      #mappedDate: "Date and time of completion of transaction",
      #mappedId: "Transaction ID",
      #mappedPaymentType: "Transaction type",
      #mappedReportCurrency: "Channel currency",
      #mappedReportSum: "Channel amount",
      #mappedStatus: "Transaction status",
      #mappedStatusIn: [ "purchase" ],
      #mappedStatusOk: "success",
      #mappedSum: "Amount",
      #name: "PaySafeCard_SEK",
      #oneGamepayPaymentSystem: "paysafecard",
      #processingScript: "pay_safe_card"
    #},
    #%{
      #calculatedTransactionPercent: 10.25,
      #defaultAccountId: "PSC_NOK",
      #defaultCurrency: "NOK",
      #defaultFeeCurrency: "NOK",
      #defaultPaymentType: "In",
      #mappedCurrency: "Currency",
      #mappedDate: "Date and time of completion of transaction",
      #mappedId: "Transaction ID",
      #mappedPaymentType: "Transaction type",
      #mappedReportCurrency: "Channel currency",
      #mappedReportSum: "Channel amount",
      #mappedStatus: "Transaction status",
      #mappedStatusIn: [ "purchase" ],
      #mappedStatusOk: "success",
      #mappedSum: "Amount",
      #name: "PaySafeCard_NOK",
      #oneGamepayPaymentSystem: "paysafecard",
      #processingScript: "pay_safe_card"
    #},
    #%{
      #calculatedTransactionPercent: 10.25,
      #defaultAccountId: "PSC_USD",
      #defaultFeeCurrency: "USD",
      #defaultPaymentType: "In",
      #mappedCurrency: "Currency",
      #mappedDate: "Date and time of completion of transaction",
      #mappedId: "Transaction ID",
      #mappedPaymentType: "Transaction type",
      #mappedReportCurrency: "Channel currency",
      #mappedReportSum: "Channel amount",
      #mappedStatus: "Transaction status",
      #mappedStatusIn: [ "purchase" ],
      #mappedStatusOk: "success",
      #mappedSum: "Amount",
      #name: "PaySafeCard_USD",
      #oneGamepayPaymentSystem: "paysafecard",
      #processingScript: "pay_safe_card"
    #},
    #%{
      #calculatedTransactionPercent: 3.0,
      #defaultAccountId: "9909/DOL_%%currency%%",
      #defaultPaymentType: "In",
      #mappedCurrency: "Группа платежных систем",
      #mappedDate: "Дата платежа",
      #mappedFeeCurrency: "Группа платежных систем",
      #mappedId: "ID",
      #mappedStatus: "Статус",
      #mappedStatusOk: "проведен",
      #mappedSum: "Сумма в рублях",
      #name: "DengiOnline WEB IN",
      #oneGamepayPaymentSystem: "wm",
      #oneGamepayTransactionId: "ID заказа",
      #processingScript: "dengionline_web_in",
    #},
    #%{
      #calculatedTransactionPercent: 2.0,
      #defaultAccountId: "9892/DOL_%%currency%%",
      #defaultPaymentType: "Out",
      #mappedCurrency: "Услуги",
      #mappedDate: "Дата создания",
      #mappedFeeCurrency: "Услуги",
      #mappedId: "ID",
      #mappedPaymentType: "Тип",
      #mappedStatus: "Статус",
      #mappedStatusOk: "1. Успех",
      #mappedStatusOut: [ "Выплата" ],
      #mappedSum: "Сумма запрошенная",
      #name: "DengiOnline Web OUT",
      #oneGamepayPaymentSystem: "wm",
      #oneGamepayTransactionId: "Внешний ID партнёра",
      #processingScript: "dengionline_web_out",
    #},
    #%{
      #calculatedTransactionPercent: 0.5,
      #defaultAccountId: "Accent YD OUT",
      #defaultPaymentType: "In",
      #mappedCurrency: "Currency",
      #mappedDate: "Date and time of transaction",
      #mappedFeeCurrency: "Channel currency",
      #mappedId: "Transaction ID",
      #mappedPaymentType: "Transaction type",
      #mappedReportCurrency: "Channel currency",
      #mappedReportSum: "Channel amount",
      #mappedStatus: "Transaction status",
      #mappedStatusIn: [ "purchase" ],
      #mappedStatusOk: "success",
      #mappedStatusOut: [ "payout" ],
      #mappedSum: "Amount",
      #name: "Yandex via AccentPay OUT",
      #oneGamepayTransactionId: "Order",
      #processingScript: "yandex_via_acceptance_out"
    #},
    #%{
      #calculatedTransactionPercent: 7.0,
      #defaultAccountId: "Accent YD IN",
      #defaultFeeAccountId: "AccentMobile",
      #defaultPaymentType: "In",
      #mappedCurrency: "Currency",
      #mappedDate: "Date and time of transaction",
      #mappedFeeCurrency: "Channel currency",
      #mappedId: "Transaction ID",
      #mappedPaymentType: "Transaction type",
      #mappedReportCurrency: "Channel currency",
      #mappedReportSum: "Channel amount",
      #mappedStatus: "Transaction status",
      #mappedStatusIn: [ "purchase" ],
      #mappedStatusOk: "success",
      #mappedStatusOut: [ "payout" ],
      #mappedSum: "Amount",
      #name: "Yandex via AccentPay In",
      #oneGamepayPaymentSystem: "yandex",
      #processingScript: "yandex_via_acceptance_in"
    #},
    #%{
      #calculatedTransactionPercent: 4.5,
      #defaultAccountId: "ACP SBOL IN",
      #defaultFeeCurrency: "RUB",
      #defaultPaymentType: "In",
      #delimiter: ";",
      #mappedCurrency: "Channel currency",
      #mappedDate: "Date and time of completion of transaction",
      #mappedId: "Transaction ID",
      #mappedStatus: "Transaction status",
      #mappedStatusOk: "success",
      #mappedSum: "Channel amount",
      #name: "ACP SBOL IN",
      #oneGamepayPaymentSystem: "sberbank.online",
      #processingScript: "acp"
    #},
    {
      "ECP IN & OUT",
      "ecp",
      %PaymentSystemFields{
        sum: "Amount",
        date: "Date and time of completion of transaction",
        type: "Transaction type",
        state: "Transaction status",
        map_id: "Transaction ID",
        type_in: "rebill,purchase",
        currency: "Currency",
        state_ok: "success",
        type_out: "payout",
        account_id: "Merchant name",
        player_purse: "Payment instrument ID",
        default_account_id: "#\{transation.account_id}#\{transaction.report_currency}",
        default_payment_type: "In"
      },
      %PaymentSystemOneGamepay{
        map_id: "Order",
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        currency: "Channel currency",
        divide_100: true,
        fee_report: true,
      },
      %PaymentSystemReport{
        sum: "Channel amount",
        currency: "Channel currency",
        divide_100: true
      }
    },
    #%{
      #calculatedTransactionPercent: 2.6,
      #defaultAccountId: "ACP USD IN",
      #defaultFeeCurrency: "USD",
      #defaultPaymentType: "In",
      #delimiter: ";",
      #mappedCurrency: "Channel currency",
      #mappedDate: "Date and time of completion of transaction",
      #mappedId: "Transaction ID",
      #mappedStatus: "Transaction status",
      #mappedStatusOk: "success",
      #mappedSum: "Channel amount",
      #name: "ACP WMZ_In",
      #oneGamepayPaymentSystem: "WMZ",
      #processingScript: "acp"
    #},
    #%{
      #calculatedTransactionPercent: 1.5,
      #defaultAccountId: "ACP USD OUT",
      #defaultFeeCurrency: "USD",
      #defaultPaymentType: "Out",
      #delimiter: ";",
      #mappedCurrency: "Channel currency",
      #mappedDate: "Date and time of completion of transaction",
      #mappedId: "Transaction ID",
      #mappedStatus: "Transaction status",
      #mappedStatusOk: "success",
      #mappedSum: "Channel amount",
      #name: "ACP WMZ_Out",
      #oneGamepayPaymentSystem: "WMZ",
      #processingScript: "acp"
    #},
    #%{
      #calculatedTransactionPercent: 2.6,
      #defaultAccountId: "ACP EUR IN",
      #defaultFeeCurrency: "EUR",
      #defaultPaymentType: "In",
      #delimiter: ";",
      #mappedCurrency: "Channel currency",
      #mappedDate: "Date and time of completion of transaction",
      #mappedId: "Transaction ID",
      #mappedStatus: "Transaction status",
      #mappedStatusOk: "success",
      #mappedSum: "Channel amount",
      #name: "ACP WME_In",
      #oneGamepayPaymentSystem: "WME",
      #processingScript: "acp"
    #},
    #%{
      #calculatedTransactionPercent: 1.5,
      #defaultAccountId: "ACP EUR OUT",
      #defaultFeeCurrency: "EUR",
      #defaultPaymentType: "Out",
      #delimiter: ";",
      #mappedCurrency: "Channel currency",
      #mappedDate: "Date and time of completion of transaction",
      #mappedId: "Transaction ID",
      #mappedStatus: "Transaction status",
      #mappedStatusOk: "success",
      #mappedSum: "Channel amount",
      #name: "ACP WME_Out",
      #oneGamepayPaymentSystem: "WME",
      #processingScript: "acp"
    #},
    #%{
      #defaultAccountId: "Zimpler %%currency%%",
      #defaultPaymentType: "In",
      #mappedAccountId: "Market",
      #mappedComment: "Uuid",
      #mappedDate: "Occured At",
      #mappedFee: "Commission",
      #mappedId: "Occured At",
      #mappedPaymentType: "Type",
      #mappedStatusIn: [ "Client Deposit" ],
      #mappedStatusOut: [ "Refund" ],
      #mappedSum: "Amount",
      #name: "Zimpler",
      #oneGamepayTransactionId: "Ref",
      #processingScript: "zimpler",
    #},
    #%{
      #defaultAccountId: "EcoPayz via APCO %%currency%%",
      #defaultPaymentType: "In",
      #mappedDate: "Date",
      #mappedId: "PSPID",
      #mappedPaymentType: "Type",
      #mappedStatus: "Accepted",
      #mappedStatusIn: [ "PURC" ],
      #mappedStatusOk: "YES",
      #mappedSum: "Amount",
      #name: "АПКО",
      #oneGamepayPaymentSystem: "visa|mastercard|eco",
      #oneGamepayTransactionId: "Order Ref",
      #processingScript: "apko",
    #},
    #%{
      #defaultAccountId: "EcoPayz via APCO %%currency%%",
      #defaultPaymentType: "In",
      #mappedCurrency: "Currency",
      #mappedDate: "Create Date",
      #mappedId: "PSPID",
      #mappedPaymentType: "Type",
      #mappedStatus: "Status",
      #mappedStatusIn: [ "PURC" ],
      #mappedStatusOk: "APPROVED",
      #mappedSum: "Amount",
      #name: "АПКО 2 (тест)",
      #oneGamepayTransactionId: "Order Ref",
      #processingScript: "apko",
    #}
  ]

  def run do
    Enum.map(@payment_systems, fn {name, script, fields, one_gamepay, fee, report} ->
        %PaymentSystem{}
        |> PaymentSystem.changeset(%{name: name, script: script})
        |> Ecto.Changeset.put_embed(:fields, fields)
        |> Ecto.Changeset.put_embed(:one_gamepay, one_gamepay)
        |> Ecto.Changeset.put_embed(:fee, fee)
        |> Ecto.Changeset.put_embed(:report, report)
        |> Repo.insert!
    end)
  end
end
