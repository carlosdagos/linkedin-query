require "optparse"
require "highline"

module LinkedInQuery
    # Command class that does the top-level program execution
    class Command
        # The program name
        # @return [String]
        def self.program_name
            @program_name ||= File.basename $PROGRAM_NAME
        end

        # The program installation path
        # @return [String]
        def self.program_path
            @program_path ||= File.expand_path $PROGRAM_NAME
        end

        # The program usage information
        # @return [String]
        def self.usage
            @usage
        end

        # Parses the program options
        # @param argv [Array]
        # @return [Object]
        def self.parse_options(argv)
            # Default program options
            options = {
                pictures:      false,
                output_format: 'csv',
                timeout:       5,
                username:      nil,
                password:      nil,
                log:           nil,
                csv_separator: ',',
                file:          nil
            }

            op = OptionParser.new do | opts |
                sep = "-" * 80

                opts.banner = "#{program_name} usage:"
                opts.separator sep
                opts.separator "  Perform a single query:"
                opts.separator "    #{program_name} \"query\" -u user"
                opts.separator "\n"
                opts.separator "  Perform a query and return with pictures"
                opts.separator "    #{program_name} \"query\" -u user --pictures"
                opts.separator "\n"
                opts.separator "  Output the result to JSON format"
                opts.separator "    #{program_name} \"query\" -u user --output json"
                opts.separator "\n"
                opts.separator "  Wait very little or fail"
                opts.separator "    #{program_name} \"query\" -u user --timeout 1"
                opts.separator "\n"
                opts.separator "By default the program will output to stdout."
                opts.separator "However if you wish to save to a file, you can"
                opts.separator "redirect the contents"
                opts.separator "\n"
                opts.separator "    #{program_name} query -u user > file.csv"
                opts.separator "\n"
                opts.separator "Or you can use the provided flag option"
                opts.separator "\n"
                opts.separator "    #{program_name} query -u user -f file.csv"
                opts.separator "\n"
                opts.separator "#{program_name} needs, aside from your LinkedIn"
                opts.separator "username, your LinkedIn password, for which it"
                opts.separator "will prompt. If you don't wish to provide it"
                opts.separator "each time, you can always provide it via pipe"
                opts.separator "\n"
                opts.separator "    1pass LinkedIn | #{program_name} query -u user"
                opts.separator "    echo \"passwdr\" | #{program_name} query -u user"
                opts.separator sep

                opts.on("-h", "--help", "Show this message") do
                    puts opts
                    exit
                end

                opts.on("-u", "--username STR", String,
                        "Username to log on (required)") do | username |
                    options[:username] = username
                end

                opts.on("-p", "--[no-]pictures",
                        "Get the results with the picture URL") do | bool |
                    options[:pictures] = bool
                end

                opts.on("-o", "--output STR", String,
                        "Output the result with the specified format: " +
                        "csv (default), json, yaml") do | output_format |
                    options[:output_format] = output_format
                end

                opts.on("-s", "--csv-separator STR", String,
                        "Specify the separator for CSV fields") do | separator |
                    options[:csv_separator] = separator
                end

                opts.on("-f", "--file STR", String,
                        "Specify the output file") do | file |
                    options[:file] = file
                end

                opts.on("-t", "--timeout NUM", Integer,
                        "Specify max HTTP timeout") do | timeout |
                    options[:timeout] = timeout
                end

                opts.on("-d", "--debug",
                        "For debugging purposes") do | debug |
                    log = Logger.new(STDOUT)
                    log.level = Logger::INFO
                    options[:log] = log
                end

                opts.on("-v", "--version", "Show version") do | version |
                    puts LinkedIn::VERSION
                    exit
                end
            end

            begin
                op.parse! argv
                @usage = op.to_s
            rescue
                # Unable to parse options, write to stderr and
                # return error status
                STDERR.puts op
                exit 1
            end

            options
        end

        private_class_method :parse_options

        # Will check stdin for a value, or prompt for it
        # @return [String]
        def self.get_password
            password = nil

            if STDIN.tty?
                cli = HighLine.new
                password = cli.ask("Enter your password:") do | q |
                    q.echo = "*"
                end
            else
                password = STDIN.gets
            end

            return password.strip
        end

        # Will dispatch the program
        # @param argv [Array]
        def self.dispatch(argv)
            options = parse_options argv

            if argv.length != 1
                STDERR.puts "Error: wrong number of arguments. Run with -h for help."
                exit 1
            end

            if options[:username].nil?
                STDERR.puts "Error: no username specified. Run with -h for help."
                exit 1
            end

            options[:password] = get_password

            begin
                scraper = Scraper.new(options)
                results = scraper.scrape_query argv

                output_results(results, options)
            rescue Error::NotFoundError => e
                STDERR.puts "Error: Tried to get an inexistent URL"
                exit 1
            rescue Error::InternalServerError => e
                STDERR.puts "Error: LinkedIn had a problem"
                exit 1
            rescue Error::LoginFailed => e
                STDERR.puts "Error: Login failed. Please try again."
                exit 1
            rescue Error::TimeoutError => e
                STDERR.puts "Error: Timeout! Try setting a longer timeout"
                exit 1
            rescue => e
                STDERR.puts "Error: There was an unknown error"
                STDERR.puts "Details: #{e.class}"
                STDERR.puts e.message
                STDERR.puts e.backtrace.join("\n")
                exit 1
            end
        end

        def self.output_results(results, options)
            output = Helpers::Output.new results, options

            output_content = case options[:output_format]
                when 'csv'  then output.csv
                when 'json' then output.json
                when 'yaml' then output.yaml
                else raise RuntimeError.new "Unrecognized output directive"
            end

            if options[:file].nil?
                puts output_content
            else
                File.open(options[:file], 'w') do | file |
                    file.write output_content
                end
            end
        end
    end
end
