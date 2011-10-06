#!/usr/bin/env ruby

ENV["BUNDLE_GEMFILE"] = "#{File.dirname(__FILE__)}/Gemfile"

require 'rubygems'
require 'fileutils'
require 'logger'
require 'tempfile'
require 'bundler'
Bundler.require

CONFIG = YAML.load_file(File.expand_path('config.yml', File.dirname(__FILE__))).with_indifferent_access

class Done < Thor

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
    "#{datetime.strftime("%F %T")} #{File.basename(`pwd`.chomp)}  #{msg}\n"
  }

  desc "report", "Daily Report"
  method_options :days_ago => 0
  def report
    date = options.days_ago.days.ago
    logs = `grep '^#{date.strftime("%F")}' #{LOG_FILE}`.split("\n").sort
    t = Tempfile.new(%w(report .txt))
    t << "# Total: 0.0\n"
    t << "# Issue Hours  Comment\n"
    time = nil
    logs.each do |log|
      puts log
      logtime, dir, comment = /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (\S+)  ?(.*)$/.match(log).captures
      logtime = Time.parse(logtime)
      time = logtime and next if time.nil?
      hours = (logtime - time) / 1.hours
      new_time = Time.parse(log[/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/])
      hours = (new_time - time) / 1.hour
      time = new_time
      next if hours.zero? || /^out$/i.match(comment.squish)
      t << "#{hours.round(2).to_s.rjust(5)} #{dir} #{log.split[3..-1].join(' ')}\n"
    end
    t.close
    system "vim -S #{File.expand_path(File.dirname(__FILE__))}/done.vim #{t.path}"
    t.open
    t.rewind
    contents = t.read.split("\n")
    contents.reject! {|l| l.squish.blank? || l =~ /^\s*#/}
    if contents.blank?
      puts "Aborting. Nothing to do."
    else
      puts "Sending time entries to freshbooks..."
      contents.each do |l|
        puts l.inspect
        hours, dir, comment = l.split(" ", 3)
        project_id = CONFIG[:projects][dir]
        if project_id.blank?
          puts "No FreshBooks project found for #{dir}!"
          next
        end
        comment = comment.squish
        comment.gsub!(/refs #\d+/, '')
        comment.gsub!(/closes #\d+/, '')
        # comment.gsub!(/^training:? /i, '')
        # comment.gsub!(/UNBILLABLE/, '')
        task_id =
          case comment
          when /RESEARCH/
            CONFIG[:tasks][:research]
          when /MEETING/
            CONFIG[:tasks][:meetings]
          else
            CONFIG[:tasks][:general]
          end
        builder = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml|
          xml.request(:method => 'time_entry.create') do
            xml.time_entry do
              xml.project_id project_id
              xml.task_id task_id
              xml.hours hours
              xml.notes comment
              xml.date date.strftime("%F")
            end
          end
        end
        begin
          r = Nokogiri::XML(RestClient.post(CONFIG[:url], builder.to_xml))
          puts r
        rescue => e
          puts "FAIL :( #{e.inspect}"
        end
      end
    end
    t.close!
  end

  desc "log [COMMENT]", "log the comment"
  def log(*comments)
    count_of_todays_logs = `grep -c '^#{Time.now.strftime("%F")}' #{LOG_FILE}`.chomp
    if count_of_todays_logs.to_i.zero?
      logged_in_at = Time.parse(`last | grep tty | head -1 | awk '{ print $4,$5,$6,$7 }'`.chomp)
      minutes = (Time.now - logged_in_at) / 60
      LOG.info "#{minutes} ###### #{Time.now.strftime("%A %D")} ######"
    end
    LOG.info comments.join(' ')
  end

  desc "gitlog", "Use the latest git log as the comment"
  def gitlog
    comment = `git log -n1 --pretty=format:%s --no-merges`
    puts comment
    log(comment)
  end

  # desc "browserlog", "Log to the active Redmine issue in Firefox"
  # def browserlog
  #   comment = `wmctrl -l | grep 'Mozilla Firefox'`
  #   a, issue_id, comment = /#(\d+): ([^-]*) -/.match(comment).to_a
  #   if issue_id && comment
  #     puts comment
  #     log("#{comment}. refs ##{issue_id}")
  #   end
  # end

end
Done.start
