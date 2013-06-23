require "simplecov"
require "coveralls"
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require "lita-hipchat"
require "lita/rspec"

RSpec.configure do |config|
  config.before do
    allow(Lita).to receive(:logger).and_return(double("Logger").as_null_object)
  end
end
