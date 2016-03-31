require 'json'
require 'yaml'
require 'csv'

module LinkedInQuery
    class Helpers
        # Helps with the output of query results in an idiomatic way
        class Output
            def initialize(query_results, options)
                @options       = options
                @query_results = query_results
            end

            def csv
                CSV.generate(:col_sep => @options[:csv_separator]) do | csv |
                    @query_results.each do | result |
                         row = [
                            result.first_name,
                            result.last_name,
                            result.position,
                            result.company,
                            result.city,
                            result.country
                        ]

                        if @options[:pictures]
                            row.push(result.profile_picture || '')
                        end

                        csv << row
                    end
                end
            end

            def json
                @query_results.map do | result |
                    r = result.to_h
                    r.delete(:profile_picture) unless @options[:pictures]
                    r
                end.to_json
            end

            def yaml
                @query_results.map do | result |
                    r = result.to_h
                    r.delete(:profile_picture) unless @options[:pictures]
                    r
                end.to_yaml
            end
        end
    end
end
