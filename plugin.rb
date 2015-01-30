# name: stackexchange_oauth2
# about: Authenticate with discourse with stackexchange.com
# version: 0.0.1
# author: Arthur Zaharov

gem 'omniauth-stackexchange', '0.2.0'

class StackexchangeAuthenticator < ::Auth::Authenticator

  CLIENT_ID = ''
  CLIENT_SECRET = ''
  PUBLIC_KEY = ''

  def name
    'stackexchange'
  end

  def after_authenticate(auth_token)
    result = Auth::Result.new

    # grap the info we need from omni auth
    data = auth_token[:info]
    raw_info = auth_token["extra"]["raw_info"]
    name = data["name"]
    email = data["email"]
    stex_uid = auth_token["uid"]

    # plugin specific data storage
    current_info = ::PluginStore.get("stex", "stex_uid_#{stex_uid}")

    result.user =
      if current_info
        User.where(id: current_info[:user_id]).first
      end

    result.name = name
    result.email = email
    result.extra_data = { stackexchange_uid: stackexchange_uid }

    result
  end

  def after_create_account(user, auth)
    data = auth[:extra_data]
    ::PluginStore.set("stex", "stex_uid_#{data[:stex_uid]}", {user_id: user.id })
  end

  def register_middleware(omniauth)
    omniauth.provider :stackexchange, CLIENT_ID, CLIENT_SECRET, public_key: PUBLIC_KEY, site: 'stackoverflow'
    # omniauth.provider :stackexchange,
    #         setup: lambda { |env|
    #           strategy = env['omniauth.strategy']
    #           strategy.options[:client_id] = CLIENT_ID
    #           strategy.options[:client_secret] = CLIENT_SECRET
    #           strategy.options[:public_key] = PUBLIC_KEY
    #         },
    #         scope: 'email'
  end
end


auth_provider :title => 'with StackExchange',
              :message => 'Log in via StackExchange (Make sure pop up blockers are not enabled).',
              :frame_width => 920,
              :frame_height => 800,
              :authenticator => StackexchangeAuthenticator.new

register_css <<CSS

.btn-social.stackexchange {
  background: #46698f;
}

CSS
