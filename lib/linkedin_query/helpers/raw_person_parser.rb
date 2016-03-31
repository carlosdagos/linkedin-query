require 'sanitize'
require 'cgi'

module LinkedInQuery
    class Helpers
        # Helper to parse raw person data
        class RawPersonParser
            # This regex will match a string up to the last comma,
            # Is useful to match the city and country
            REGEX_CITY_COUNTRY = /(?<city>[^,]+), (?<country>.*)$/
            # This regex will match the string up until the last 'at'
            # occurrence, and is useful to match position and company
            REGEX_POSITION_COMPANY = /(?<position>.*) (?=(at|bei))(?<company>.*)/
            # Alternative regex when we can't match the previous one
            # It will match up until the last space, and hope for the best
            REGEX_POSITION_COMPANY_ALT = /(?<position>.*) (?<company>\S*)$/

            def initialize(raw_person)
                @raw_person = raw_person
                parse!
            end

            def first_name
                clean_string(
                    @raw_person[:firstName] ||
                    @raw_person[:fmt_name]  ||
                    "User id: #{@raw_person[:id]}"
                )
            end

            def last_name
                clean_string(@raw_person[:lastName] || '')
            end

            def position
                @position || clean_string(@raw_person[:fmt_industry]) || ''
            end

            def company
                @company || ''
            end

            def city
                @city
            end

            def country
                @country
            end

            def picture
                @raw_person[:logo_result_base][:media_picture_link_400]
            end

            private

            def parse!
                parse_city_and_country!
                parse_position_and_company!
            end

            def parse_city_and_country!
                city_country_match = REGEX_CITY_COUNTRY.match(
                    @raw_person[:fmt_location]
                )

                @city    = city_country_match[:city]
                @country = city_country_match[:country]
            end

            def parse_position_and_company!
                position_and_company_match = REGEX_POSITION_COMPANY.match(
                    @raw_person[:fmt_headline]
                ) || REGEX_POSITION_COMPANY_ALT.match(
                    @raw_person[:fmt_headline]
                )

                unless position_and_company_match.nil?
                    @position = clean_string(
                        position_and_company_match[:position].strip
                    )

                    @company  = clean_string(
                        position_and_company_match[:company].gsub(/^(at|bei) /, '').strip
                    )
                end
            end

            def clean_string(str)
                ::CGI::unescapeHTML(Sanitize.clean(str))
            end
        end
    end
end
