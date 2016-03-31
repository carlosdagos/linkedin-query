module LinkedInQuery
    # Idiomatic class that represents a query result
    class QueryResult
        attr_accessor :first_name, :last_name, :position, :company
        attr_accessor :city, :country, :profile_picture

        def initialize(data)
            data.each do | k, v |
                instance_variable_set("@#{k}", v)
            end
        end

        def to_h
            {
                :first_name      => @first_name,
                :last_name       => @last_name,
                :position        => @position,
                :company         => @company,
                :city            => @city,
                :country         => @country,
                :profile_picture => @profile_picture
            }
        end

        def to_json(*a)
            to_h.to_json(*a)
        end

        def to_yaml
            to_h.to_yaml
        end
    end
end
