source "https://rubygems.org"

gem "rails", "~> 7.0"
gem "puma", "~> 5.5"
gem "pg", "~> 1.2"
gem "turbo-rails", "~> 1.0"

gem "rodauth-rails", "~> 1.3"
gem "rodauth-i18n", "~> 0.3"
gem "rodauth", github: "janko/rodauth", branch: "account-table-ds-method"
gem "rotp", require: false
gem "rqrcode", require: false

gem "omniauth"
gem "omniauth-facebook"
gem "omniauth-rails_csrf_protection"

group :test do
  gem "capybara", "~> 3.33"
end

group :development do
  gem "localhost"
  gem "matrix"
end
