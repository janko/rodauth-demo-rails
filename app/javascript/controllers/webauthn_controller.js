import { Controller } from "@hotwired/stimulus"
import * as WebAuthnJSON from "@github/webauthn-json"

export default class extends Controller {
  static targets = ["result"]
  static values = { data: Object }

  connect() {
    if (!WebAuthnJSON.supported()) {
      alert("WebAuthn is not supported on your operating system or browser version")
    }
  }

  async setup(event) {
    event.preventDefault()

    const result = await WebAuthnJSON.create({ publicKey: this.dataValue })

    this.resultTarget.value = JSON.stringify(result)
    this.element.requestSubmit()
  }

  async auth(event) {
    event.preventDefault()

    const result = await WebAuthnJSON.get({ publicKey: this.dataValue })

    this.resultTarget.value = JSON.stringify(result)
    this.element.requestSubmit()
  }
}
