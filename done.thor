#!/usr/bin/env ruby

ENV['BUNDLE_GEMFILE'] = "#{File.dirname(__FILE__)}/Gemfile"

require 'rubygems'
require 'fileutils'
require 'logger'
require 'tempfile'
require 'bundler'
require 'open-uri'
require 'net/http'
Bundler.require

I18n.enforce_available_locales = false # Avoid warnings.

CONFIG = YAML.load_file(File.expand_path('config.yml', File.dirname(__FILE__))).with_indifferent_access

class Done < Thor

  # External editor
  EDITOR = ENV['EDITOR'] || 'vim'

  # Set up log
  LOG_FILE = File.expand_path('time.log', "#{File.dirname(__FILE__)}/log")
  FileUtils.mkdir_p(File.dirname(LOG_FILE))
  LOG = Logger.new(LOG_FILE, 'weekly')
  LOG.formatter = proc {|severity, datetime, progname, msg|
    offset = msg.split.first.to_i
    if offset > 0
      datetime -= offset.minutes
      msg = msg.split[1..-1].join(' ')
    end
    puts msg
    "#{datetime.strftime("%F %T")} #{File.basename(`pwd`.chomp)}  #{msg}\n"
  }

  desc 'report', 'Daily Report'
  method_options :days_ago => 0
  def report

    if File.exists?(path = File.expand_path('contacts.yml', File.dirname(__FILE__)))
      contacts = YAML.load_file(path)
    else
      contacts = get_from_api('contacts')
      File.write(path, contacts.to_yaml)
    end
    # e.g. contacts = [{"id"=>1, "name"=>"Contact Name", "pinned"=>false, "short_code"=>"contact_name", "default_rate_dollars"=>""}]

    # Parse log file, create report and open it in vim
    date = options.days_ago.days.ago
    logs = `grep '^#{date.strftime("%F")}' #{LOG_FILE}`.split("\n").sort
    directories = []
    t = Tempfile.new(%w(report .txt))
    t.puts "# Total: 0.0"
    t.puts "# Hours Project Comment"
    time = nil
    entries = []
    logs.each do |log|
      puts log
      logtime, dir, comment = /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (\S+)  ?(.*)$/.match(log).captures
      directories << dir unless directories.include?(dir)
      logtime = Time.parse(logtime)
      time = logtime and next if time.nil?
      hours = (logtime - time) / 1.hours
      new_time = Time.parse(log[/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/])
      hours = (new_time - time) / 1.hour
      time = new_time
      next if hours.zero? || /^out$/i.match(comment.squish)
      entries << "#{hours.round(2).to_s.rjust(5)} #{dir} #{log.split[3..-1].join(' ')}\n"
    end
    entries.sort_by { |l| l.split[1] }.each {|e| t << e}
    t.puts
    directories.each do |dir|
      contact_id = CONFIG[:contacts][dir]
      contact = contacts.find { |c| c['id'] == contact_id.to_i }
      if contact
        t.puts "# #{contact_id.to_s.rjust(7)} #{dir} #{contact['name']}"
      else
        t.puts "#     #{dir} WARNING: No project set"
      end
    end
    t.puts
    contacts.sort_by { |c| c['name'] }.each do |contact|
      t.puts "# #{contact['id'].to_s.rjust(7)} #{contact['name']}"
    end
    t.close
    system "vim -S #{File.expand_path(File.dirname(__FILE__))}/done.vim #{t.path}"

    # Reopen editted report, parse and send to API
    t.open
    t.rewind
    contents = t.read.split("\n")
    contents.reject! {|l| l.squish.blank? || l =~ /^\s*#/}
    if contents.blank?
      puts 'Aborting. Nothing to do.'
    else
      puts 'Sending time entries to API...'
      contents.each do |l|
        puts l.inspect
        hours, dir, comment = l.split(' ', 3)
        comment = comment.squish
        contact_id = dir.to_i > 0 ? dir.to_i : CONFIG[:contacts][dir]
        puts "No contact found for #{dir}!" and next if contact_id.blank?
        post_to_api('entries', {
          'entry[contact_id]' => contact_id,
          'entry[logged_at]' => Time.now.to_s,
          'entry[duration]' => hours.to_f.hours.to_i,
          'entry[description]' => comment,
        })
      end
    end
    t.close!

  end

  desc 'log [COMMENT]', 'Create a log entry from the given comment'
  def log(*comments)
    count_of_todays_logs = `grep -c '^#{Time.now.strftime("%F")}' #{LOG_FILE}`.chomp
    if count_of_todays_logs.to_i.zero?
      LOG.info "###### #{Time.now.strftime("%A %D")} ######"
    end
    if comments.present?
      LOG.info comments.join(' ').squish
    end
  end

  desc "gitlog", "Use the latest git log as the comment"
  def gitlog
    comment = `git log -n1 --pretty=format:%s --no-merges`
    log(comment)
  end

  desc "editlog", "edit the current log file"
  def editlog
    system "#{EDITOR} #{LOG_FILE}"
  end

  desc 'githublog', 'Create a log entry from the Github issue description of the latest commit.'
  def githublog
    comment = `git log -n1 --pretty=format:%s --no-merges`
    issue_number = comment.to_s[/#(\d+)/].gsub('#', '')
    repo = `git remote show origin -n | grep Fetch | grep github`.to_s.match(%r{:([^/:]+/.+)\.git}).to_a[1]
    if repo.present?
      issue = JSON.parse(open("https://api.github.com/repos/#{repo}/issues/#{issue_number}?access_token=#{CONFIG[:github_token]}").read)
      comment = issue['title'] if issue['title'].present?
    end
    log(comment)
  end


  private

  def get_from_api(resource, params = {})
    params.merge!(CONFIG[:api_params])
    JSON.parse(open("#{CONFIG[:api_url]}#{resource}.json?#{params.to_param}").read)
  end

  def post_to_api(resource, params = {})
    params.merge!(CONFIG[:api_params])
    url = URI.parse("#{CONFIG[:api_url]}#{resource}.json")
    response, data = Net::HTTP.post_form(url, params)
    puts "#{response.code} #{response.message}"
  end

end
Done.start
