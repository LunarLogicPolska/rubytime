set :output, "log/cron.log"

job_type :rake, "cd :path && MERB_ENV=:environment bundle exec rake :task :output"

every 1.day, :at => '10:00 am' do
  rake "rubytime:send_timesheet_nagger_emails_for_previous_weekday"
end

every 1.day, :at => '12:00 am' do
  rake "rubytime:send_timesheet_report_email_for_previous_weekday"
end

# ask John/Ewelina/Paul when exactly
# add to deploy.rb:
#   remote_task :update_crontab, :roles => [:app] do
#     run "cd #{current_path}; MERB_ENV=#{merb_env} bundle exec whenever --update-crontab #{application}"
#   end
every :friday do
  rake "rubytime:send_timesheet_summary_emails_for_last_five_days"
end

every 1.day do
  rake "rubytime:send_emails"
end
