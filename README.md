README
======

LinkedIn query scraper. It will scrape the results page for a specific query
on the default LinkedIn search bar.

# Usage

```bash
$ linkedin-query "my query" --username username
```

You will be then prompted for your password, as you can only search
when you're logged in the website.

#### If you don't want to enter your password

```bash
$ echo "my password" | linkedin-query "my query" --username username
```

This will then allow you to use the program with tools like
[`1pass`](https://github.com/georgebrock/1pass/).

```bash
$ 1pass LinkedIn | linkedin-query "my query" --username username
```

#### Installation

- Clone this repo
- Build the gem
```bash
$ gem build linkedin-query.gemspec
```
- Install the gem (may require sudo privileges)
```bash
$ gem install linkedin-query-1.0.0.gem
```

##### Additional options

```bash
$ linkedin-query "my query" --output yaml \
                            --pictures    \
                            --timeout 5
```

Note: the `timeout` flag is in **seconds**

###### Show help menu

```bash
$ linkedin-query --help
```

###### Show version

```bash
$ linkedin-query --version
```

##### Notes

Built and tested with `ruby 2.0.0p645 (2015-04-13 revision 50299) [universal.x86_64-darwin15]`
