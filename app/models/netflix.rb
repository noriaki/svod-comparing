

module Netflix
  @@id = Rails.application.secrets.accounts["netflix"]["id"]
  @@pw = Rails.application.secrets.accounts["netflix"]["pw"]
  mattr_reader :id, :pw

  @display_port = 67
  mattr_reader :display_port

  @@top_page = "http://www.netflix.com/jp/"
  mattr_reader :top_page

  class Crawler < Base::Crawler
    @@top_page = self.parent.top_page

    def login?
      get @@top_page if URI(page.current_url).host != URI(@@top_page).host
      member_info = page.evaluate_script [
        'netflix.contextData',
        'netflix.contextData.userInfo.data.membershipStatus'
      ].join(' && ')
      member_info == "CURRENT_MEMBER"
    end

    def login
      unless login?
        get 'https://www.netflix.com/Login?locale=ja-JP'
        page.first('[name=email]').set self.class.parent.id
        page.first('[name=password]').set self.class.parent.pw
        page.first('button[type=submit]').click
        ## not fire. because of react...?
        #if page.all('.profile-name').size > 0
        #  page.find('a', text: 'Machine').click
        #end
      end
      url = page.current_url
      Rails.logger.debug("[#{self.class}] Logged-in: #{url}")
      url
    end

    def crawl_contents_and_save
      crawl_contents_and_save!(false)
    end

    def crawl_contents_and_save!(force=true)
      binding.pry
    end

    private

    def metadata
      login unless login?
      page.evaluate_script 'netflix && netflix.contextData || reactApp && reactApp.metadata && reactApp.metadata.models'
    end

    def access_token
      login unless login?
      page.evaluate_script 'netflix.contextData.userInfo.data.authURL'
    end

    def api_endpoint
      d = metadata["serverDefs"]["data"]
      d["API_ROOT"] + d["API_BASE_URL"] + '/pathEvaluator/' +
        d["endpointIdentifiers"]["/pathEvaluator"] +
        '?withSize=true&materialize=true&model=harris'
    end

  end

end
