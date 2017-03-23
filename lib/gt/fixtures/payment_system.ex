defmodule Gt.Fixtures.PaymentSystem do
  alias Gt.Repo
  alias Gt.PaymentSystem
  alias Gt.PaymentSystemFields
  alias Gt.PaymentSystemCsv
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
        default_account_id: "some_account_id",
        player_purse: "Purse",
        state: "State",
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        payment_system: "Interkassa",
        map_id: "Checkout payment number",
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        fee_report: false,
      },
      %PaymentSystemReport{
        divide_100: false
      }
    },
    {
      "Moneta",
      nil,
      %PaymentSystemFields{
        map_id: "#",
        date: "Date",
        sum: "Amount",
        currency: "Currency",
        default_payment_type: "In",
        account_id: "Merchant Account Id",
        player_purse: "User Account Id",
        state: "Status",
        comment: "Description",
        state_ok: "Выполнена",
        type_in: "BUSINESS",
        type_out: "WITHDRAWAL",
        is_out_negative: true
      },
      %PaymentSystemCsv{
        separator: "semicolon",
        encoding: "windows-1251",
      },
      %PaymentSystemOneGamepay{
        payment_system: "Moneta",
        map_id: "Client Transaction ID",
        pguid: "Description"
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        fee_report: false,
        map_id: "Fee",
        currency: "Currency"
      },
      %PaymentSystemReport{
        divide_100: false
      }
    },
    {
      "Neteller",
      nil,
      %PaymentSystemFields{
        map_id: "NETELLER Trans. ID",
        date: "Date",
        sum: "Amount",
        currency: "Currency",
        default_payment_type: "In",
        default_account_id: "Neteller_#\{transaction.currency}",
        type: "Type",
        player_purse: "Account ID",
        state: "Status",
        state_ok: "Accepted",
        type_in: "Incoming",
        type_out: "Outgoing",
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        payment_system: "neteller",
        map_id: "Merchant Ref. ID",
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        fee_report: false,
        map_id: "Fee",
        currency: "Currency"
      },
      %PaymentSystemReport{
        divide_100: false
      }
    },
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
    {
      "PaySafeCard_EUR",
      nil,
      %PaymentSystemFields{
        map_id: "Transaction ID",
        date: "Date and time of completion of transaction",
        sum: "Amount",
        currency: "Currency",
        type: "Transaction type",
        default_payment_type: "In",
        default_account_id: "PSC_EUR",
        account_id: "Checkout name",
        player_purse: "Purse",
        type_in: "purchase",
        state: "Transaction status",
        state_ok: "success"
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        map_id: "Order",
        payment_system: "paysafecard"
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        percent: 10.25,
        divide_100: true,
        fee_report: false,
      },
      %PaymentSystemReport{
        divide_100: false,
        sum: "Channel amount",
        currency: "Channel currency"
      }
    },
    {
      "Accentpay IN",
      nil,
      %PaymentSystemFields{
        map_id: "Transaction ID",
        date: "Date and time of completion of transaction",
        sum: "Channel amount",
        currency: "Channel currency",
        default_payment_type: "In",
        default_account_id: "AccentMobile",
        account_id: "Checkout name",
        player_purse: "Purse",
        state: "Transaction status",
        state_ok: "success"
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
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
    {
      "Accentpay OUT",
      nil,
      %PaymentSystemFields{
        map_id: "Order",
        date: "Date and time of transaction",
        sum: "Amount",
        currency: "Currency",
        default_payment_type: "Out",
        default_account_id: "accent_cards",
        player_purse: "Purse",
        state: "Transaction status",
        state_ok: "success"
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        map_id: "Order",
        payment_system: "visa,mastercard,maestro,american express,diners club,jcb,discover,solo,switch"
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        currency: "Channel currency",
        default_account_id: "AccentMobile",
        sum: 50.0,
        percent: 2.7,
        divide_100: true,
        fee_report: true,
      },
      %PaymentSystemReport{
        currency: "Channel currency",
        sum: "Channel amount",
        divide_100: true
      }
    },
    #{
      #"DengiOnline Web OUT",
      #"dol_web_out",
      #%PaymentSystemFields{
        #map_id: "ID",
        #date: "Дата создания",
        #sum: "Сумма запрошенная",
        #currency: "Услуги",
        #type: "Тип",
        #default_payment_type: "Out",
        #default_account_id: "9526_#\{currency}",
        #player_purse: "Purse",
        #state: "Статус",
        #type_out: "Выплата",
        #state_ok: "1. Успех"
      #},
      #%PaymentSystemCsv{},
      #%PaymentSystemOneGamepay{
        #map_id: "Внешний ID партнёра",
        #payment_system: "wm"
      #},
      #%PaymentSystemFee{
        #types: ["In", "Out"],
        #fee_report: false,
      #},
      #%PaymentSystemReport{
        #divide_100: false
      #}
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
    {
      "PaySafeCard_SEK",
      nil,
      %PaymentSystemFields{
        map_id: "Transaction ID",
        date: "Date and time of completion of transaction",
        sum: "Amount",
        currency: "Currency",
        type: "Transaction type",
        default_payment_type: "In",
        default_account_id: "PSC_SEK",
        type_in: "purchase",
        state: "Transaction status",
        state_ok: "success"
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        payment_system: "paysafecard"
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        percent: 10.25,
        divide_100: true,
        fee_report: true,
      },
      %PaymentSystemReport{
        divide_100: true,
        sum: "Channel amount",
        currency: "Channel currency"
      }
    },
    {
      "PaySafeCard_NOK",
      nil,
      %PaymentSystemFields{
        map_id: "Transaction ID",
        date: "Date and time of completion of transaction",
        sum: "Amount",
        currency: "Currency",
        type: "Transaction type",
        default_payment_type: "In",
        default_account_id: "PSC_NOK",
        type_in: "purchase",
        state: "Transaction status",
        state_ok: "success"
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        payment_system: "paysafecard"
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        percent: 10.25,
        divide_100: true,
        fee_report: true,
      },
      %PaymentSystemReport{
        divide_100: true,
        sum: "Channel amount",
        currency: "Channel currency"
      }
    },
    {
      "PaySafeCard_USD",
      nil,
      %PaymentSystemFields{
        map_id: "Transaction ID",
        date: "Date and time of completion of transaction",
        sum: "Amount",
        currency: "Currency",
        type: "Transaction type",
        default_payment_type: "In",
        default_account_id: "PSC_USD",
        type_in: "purchase",
        state: "Transaction status",
        state_ok: "success"
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        payment_system: "paysafecard"
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        percent: 10.25,
        divide_100: true,
        fee_report: true,
      },
      %PaymentSystemReport{
        divide_100: true,
        sum: "Channel amount",
        currency: "Channel currency"
      }
    },
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
    {
      "ACP SBOL IN",
      nil,
      %PaymentSystemFields{
        map_id: "Transaction ID",
        date: "Date and time of completion of transaction",
        sum: "Channel amount",
        currency: "Channel currency",
        type: "Transaction type",
        default_payment_type: "In",
        default_account_id: "ACP SBOL IN",
        type_in: "purchase",
        state: "Transaction status",
        state_ok: "success"
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        payment_system: "sberbank.online,alfa-click,promsvyazbank"
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        percent: 4.5,
        divide_100: true,
        fee_report: false,
      },
      %PaymentSystemReport{
        divide_100: false,
        sum: "Channel amount",
        currency: "Channel currency"
      }
    },
    {
      "ECP IN & OUT",
      "ecp",
      %PaymentSystemFields{
        sum: "Amount,TR_AMOUNT",
        date: "Date and time of completion of transaction,TR_DATE_TIME",
        type: "TR_TYPE,Transaction type",
        state: "Transaction status",
        map_id: "Transaction ID,TRX. ID ADMIN,TRX. ID",
        type_in: "rebill,purchase,05",
        currency: "Currency,TR_CCY",
        state_ok: "success,finished|confirmed",
        type_out: "payout,06,25",
        account_id: "Merchant name,MERCHANT_NAME",
        fee_sum_rub: 50.0,
        player_purse: "Payment instrument ID",
        ggs_merchants: "GGS,FBS",
        fee_in_percent: 2.9,
        fee_out_percent: 2.7,
        is_out_negative: false,
        darmako_merchants: "CASINO-X.COM,POKERDOM,RuPoker.com,Pomadorro",
        default_account_id: "#\{transaction.account_id}#\{transaction.report_currency}",
        default_payment_type: "In"
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        payment_system: "visa,mastercard,maestro,american express,diners club,jcb,discover,solo,switch"
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        currency: "Channel currency,TR_CCY",
        divide_100: true,
        fee_report: true,
      },
      %PaymentSystemReport{
        sum: "Channel amount,TR_AMOUNT",
        currency: "Channel currency,TR_CCY",
        divide_100: true
      }
    },
    {
      "ACP WME_In",
      nil,
      %PaymentSystemFields{
        map_id: "Transaction ID",
        date: "Date and time of completion of transaction",
        sum: "Channel amount",
        currency: "Channel currency",
        default_payment_type: "In",
        default_account_id: "ACP EUR IN",
        type_in: "purchase",
        state: "Transaction status",
        state_ok: "success"
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        payment_system: "WME"
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        percent: 2.6,
        divide_100: true,
        fee_report: false,
      },
      %PaymentSystemReport{
        divide_100: false,
      }
    },
    {
      "ACP WME_Out",
      nil,
      %PaymentSystemFields{
        map_id: "Transaction ID",
        date: "Date and time of completion of transaction",
        sum: "Channel amount",
        currency: "Channel currency",
        default_payment_type: "In",
        default_account_id: "ACP EUR OUT",
        type_in: "purchase",
        state: "Transaction status",
        state_ok: "success"
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        payment_system: "WME"
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        percent: 1.5,
        divide_100: true,
        fee_report: false,
      },
      %PaymentSystemReport{
        divide_100: false,
      }
    },
    {
      "ACP WMZ_In",
      nil,
      %PaymentSystemFields{
        map_id: "Transaction ID",
        date: "Date and time of completion of transaction",
        sum: "Channel amount",
        currency: "Channel currency",
        default_payment_type: "In",
        default_account_id: "ACP USD IN",
        type_in: "purchase",
        state: "Transaction status",
        state_ok: "success"
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        payment_system: "WMZ"
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        percent: 2.6,
        divide_100: true,
        fee_report: false,
      },
      %PaymentSystemReport{
        divide_100: false,
      }
    },
    {
      "ACP WMZ_Out",
      nil,
      %PaymentSystemFields{
        map_id: "Transaction ID",
        date: "Date and time of completion of transaction",
        sum: "Channel amount",
        currency: "Channel currency",
        default_payment_type: "In",
        default_account_id: "ACP USD OUT",
        type_in: "purchase",
        state: "Transaction status",
        state_ok: "success"
      },
      %PaymentSystemCsv{},
      %PaymentSystemOneGamepay{
        payment_system: "WMZ"
      },
      %PaymentSystemFee{
        types: ["In", "Out"],
        percent: 1.5,
        divide_100: true,
        fee_report: false,
      },
      %PaymentSystemReport{
        divide_100: false,
      }
    },
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
