require 'capybara/dsl'
require 'capybara/poltergeist'

require 'digest/md5'

class UriWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app, :js_errors => false)
  end

  Capybara.run_server = false
  Capybara.current_driver = :poltergeist
  include Capybara::DSL

  def perform(uri)
    logger.info "Dequeue: #{uri}"
    file_name = Digest::MD5.hexdigest(uri) + '.png'

    begin
      visit uri
      page.driver.save_screenshot file_name
    rescue Capybara::Poltergeist::TimeoutError => e
      logger.warn e.message
    end
  end
end
