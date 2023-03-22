import { Controller } from "@hotwired/stimulus"
import * as WebAuthnJSON from "@github/webauthn-json"

export default class extends Controller {
  static targets = ["input"]
  static values = { options: Object }

  connect() {
    this.autofill()
  }

  async autofill() {
    const available = await this.available()

    if (!available) return

    const cred = await WebAuthnJSON.get({mediation: "conditional", publicKey: this.optionsValue})

    this.inputTarget.value = JSON.stringify(cred)

    this.element.requestSubmit()
  }

  async available() {
    if (window.PublicKeyCredential && PublicKeyCredential.isConditionalMediationAvailable) {
      return await PublicKeyCredential.isConditionalMediationAvailable()
    }
  }
}
