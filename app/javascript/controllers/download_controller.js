import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = { content: String, filename: String }

  perform(event) {
    event.preventDefault()

    const content = new Blob([this.contentValue])
    const contentURL = URL.createObjectURL(content)

    this.download(contentURL)
  }

  download(url) {
    const downloadLink = document.createElement('a')
    downloadLink.href = url
    downloadLink.setAttribute('download', this.filenameValue)

    document.body.appendChild(downloadLink)
    downloadLink.click()
    document.body.removeChild(downloadLink)
  }
}
