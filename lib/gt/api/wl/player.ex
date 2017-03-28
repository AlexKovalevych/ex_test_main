defmodule Gt.Api.Wl.Player do
  @derive [Poison.Encoder]

  defstruct [id: nil,
             ip: nil,
             partner_code: nil,
             login: nil,
             email: nil,
             email_verified: false,
             password: nil,
             phone: nil,
             nickname: nil,
             lastname: nil,
             firstname: nil,
             middlename: nil,
             level: nil,
             status: nil,
             is_online: nil,
             is_test: false,
             is_active: false,
             verified: false,
             bonuses_on: false,
             balance: nil,
             currency: nil,
             birthday: nil,
             registered_at: nil,
             last_visit_at: nil,
             financial: [],
             country: nil,
             address: nil,
             social_identity: nil,
             multiaccount: []
           ]
end
