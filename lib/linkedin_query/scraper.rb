require "uri"
require "json"
require "mechanize"

module LinkedInQuery
    # Scraper class that handles most of the program logic
    class Scraper
        # LinkedIn home page URL
        LINKEDIN_HOME = "https://www.linkedin.com"

        # LinkedIn login submit handle
        LINKEDIN_LOGIN_HANDLE = "https://www.linkedin.com/uas/login-submit"

        # Default user agent for the scraper
        USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) " +
                     "AppleWebKit/537.75.14 (KHTML, like Gecko) " +
                     "Version/7.0.3 Safari/7046A194A"

        # Serves as a selector for the main data dump in JSON on the
        # results page
        VOLTRON_CSS_SELECTOR = "#voltron_srp_main-content"

        def initialize(options)
            @options = options
        end

        # Returns an array of results for a query
        # @param query [String]
        # @return [Array]
        def scrape_query(query)
            scrape_search_page(get_search_page query)
        end

        # Return an array of people from a search page
        # @param search_page [Mechanize::Page]
        # @return [Array]
        def scrape_search_page(search_page)
            voltron = get_voltron search_page

            people_from_voltron(voltron).map do | raw_person |
                parser = Helpers::RawPersonParser.new raw_person

                QueryResult.new({
                    last_name:       parser.last_name,
                    first_name:      parser.first_name,
                    city:            parser.city,
                    country:         parser.country,
                    position:        parser.position,
                    company:         parser.company,
                    profile_picture: parser.picture
                })
            end
        end

        # Given a string query, get the page for the search page of it
        # @param query [String]
        # @return [Mechanize::Page]
        def get_search_page(query)
            @http_client ||= authenticate default_http_client

            search_form = @http_client.page.form_with(:id => "global-search")
            search_form['keywords'] = query

            @http_client.submit(search_form)
            @http_client.page
        end

        # Get the client for the scraper
        # @return [Mechanize]
        def http_client
            @http_client
        end

        # Set the client for the scraper
        # @param client [Mechanize]
        def http_client=(client)
            @http_client = client
        end

        private

        # Helper method to get the people from the "voltron" data dump
        # param voltron [Object]
        # return [Array]j
        def people_from_voltron(voltron)
            search_results = voltron[:content][:page][:voltron_unified_search_json][:search][:results]

            search_results.keep_if do | r |
                not r[:person].nil?
            end.map do | r |
                r[:person]
            end
        end

        # Authenticates the client with the provided options
        # @param client [Mechanize]
        # @return [Mechanize]
        def authenticate(client)
            page = client.get LINKEDIN_HOME

            form = page.form_with(:action => LINKEDIN_LOGIN_HANDLE)
            form['session_key']      = @options[:username]
            form['session_password'] = @options[:password]
            client.submit(form)

            # We're on the same handle, which means that the login
            # step didn't work
            if client.page.uri.to_s == LINKEDIN_LOGIN_HANDLE
                raise Error::LoginFailed.new "Wrong credentials"
            end

            # The client state has now changed
            return client
        end

        # Creates a default HTTP client
        # @return [Mechanize]
        def default_http_client
            Mechanize.new do | agent |
                agent.log          = @options[:log]
                agent.read_timeout = @options[:timeout]
                agent.user_agent   = USER_AGENT
            end
        end

        # Extracts the main JSON dump from the search page
        # @param search_page [Mechanize::Page]
        # @resturn [Object]
        def get_voltron(search_page)
            voltron_node = search_page.search VOLTRON_CSS_SELECTOR
            # The data is dumped on an HTML comment, and it's a JSON
            # that needs to be "fixed back" to utf-8
            voltron = fix_json_string(voltron_node.children.first.text)
            JSON.parse(voltron, {:symbolize_names => true, :allow_nan => true})
        end

        # Helper method to fix the json string from the "voltron"
        # @param json_string [String]
        # @return [String]
        def fix_json_string(json_string)
            json_string.gsub /\\u([0-9a-z]{4})/ do | s |
                [$1.to_i(16)].pack("U")
            end
        end
    end
end
