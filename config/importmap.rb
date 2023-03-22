# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "@github/webauthn-json", to: "https://unpkg.com/@github/webauthn-json@2.1.1/dist/esm/webauthn-json.js"
pin_all_from "app/javascript/controllers", under: "controllers"
