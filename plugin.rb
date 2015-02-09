# name: stackexchange_oauth2
# about: Authenticate with discourse with stackexchange.com
# version: 0.0.1
# author: Arthur Zaharov

gem 'omniauth-stackexchange', '0.2.0'

class StackexchangeAuthenticator < ::Auth::Authenticator
  def name
    'stackexchange'
  end

  def after_authenticate(auth_token)
    result = Auth::Result.new

    name = auth_token['info']['nickname']
    stackexchange_uid = auth_token['uid']

    current_info = ::PluginStore.get('stackexchange', "stackexchange_uid_#{stackexchange_uid}")

    result.user =
      if current_info
        User.where(id: current_info[:user_id]).first
      end

    result.name = name
    result.extra_data = { stackexchange_uid: stackexchange_uid }

    result
  end

  def after_create_account(user, auth)
    stackexchange_uid = auth[:extra_data][:stackexchange_uid]
    ::PluginStore.set('stackexchange', "stackexchange_uid_#{stackexchange_uid}", { user_id: user.id })
  end

  def register_middleware(omniauth)
    omniauth.provider :stackexchange, :setup => lambda { |env|
      strategy = env['omniauth.strategy']
      strategy.options[:client_id] = SiteSetting.stackexchange_oauth2_client_id
      strategy.options[:client_secret] = SiteSetting.stackexchange_oauth2_client_secret
      strategy.options[:public_key] = SiteSetting.stackexchange_oauth2_public_key
      strategy.options[:site] = 'stackoverflow'
    }
  end
end


auth_provider :title => 'with StackExchange',
              :message => 'Log in via StackExchange (Make sure pop up blockers are not enabled).',
              :frame_width => 920,
              :frame_height => 800,
              :authenticator => StackexchangeAuthenticator.new

register_css <<CSS

.btn-social.stackexchange:before {
  font-family: 'FontAwesome';
  content: $fa-var-stack-exchange;
}

CSS
