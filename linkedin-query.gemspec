# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "linkedin_query/version"

Gem::Specification.new do | s |
    s.name          = "linkedin-query"
    s.version       = LinkedInQuery::VERSION
    s.homepage      = "https://github.com/charlydagos/linkedin-query"
    s.authors       = ["Carlos D'Agostino"]
    s.email         = "carlos.dagostino@gmail.com"
    s.summary       = "LinkedIn Scraper tool"
    s.licenses      = ["MIT"]
    s.description   = <<END_DESC
This gem will make an executable to scrape and output linkedin search results
END_DESC
    s.files         = `git ls-files`.split("\n")
    s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.executables   = `git ls-files -- bin/*`.split("\n").map do | f |
        File.basename(f)
    end
    s.require_paths = ["lib"]

    s.add_dependency 'mechanize', '~> 2'
    s.add_dependency 'highline', '~> 1.7'
    s.add_dependency 'sanitize', '~> 4'

    s.add_development_dependency 'rake', '~> 10'
end
