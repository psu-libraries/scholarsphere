import { Controller } from 'stimulus'
import consumer from '../channels/consumer'

export default class extends Controller {
  static targets = ['score', 'link'];

  connect () {
    const id = this.data.get('id')

    consumer.subscriptions.create(
      { channel: 'FileVersionMembershipChannel', id: id },
      {
        connected: () => {
          this.renderResult()
        },
        received: (data) => {
          this.updateResult(data)
        }
      }
    )
  }

  updateResult (data) {
    this.data.set('mimeType', data.mime_type)
    this.data.set('scorePresent', data.accessibility_score_present)
    this.data.set('errorPresent', data.accessibility_error_present)
    this.data.set('score', data.accessibility_score)
    this.data.set('reportUrl', data.report_download_url)
    this.renderResult()
  }

  renderResult () {
    const mimeType = this.data.get('mimeType') || 'unknown'
    const scorePresent = this.data.get('scorePresent') === 'true'
    const errorPresent = this.data.get('errorPresent') === 'true'
    const score = this.data.get('score') || 'N/A'

    if (mimeType !== 'application/pdf' || errorPresent) {
      this.scoreTarget.textContent = 'Needs manual review'
    } else if (scorePresent) {
      this.scoreTarget.textContent = score
    } else {
      this.scoreTarget.innerHTML = 'Processing <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>'
    }

    this.renderReportUrl()
  }

  renderReportUrl () {
    const reportUrl = this.data.get('reportUrl')

    if (reportUrl) {
      this.linkTarget.innerHTML = '<a href="' + reportUrl + '" target="_blank">View Report</a>'
    }
  }
}
