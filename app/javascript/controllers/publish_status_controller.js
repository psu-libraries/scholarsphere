import { Controller } from 'stimulus'
import consumer from '../channels/consumer'

export default class extends Controller {
  static targets = ['show_buttons', 'help_text'];

  connect () {
    consumer.subscriptions.create(
      { channel: 'PublishStatusChannel' },
      {
        connected: () => {
          this.renderPublishStatus()
        },
        received: (data) => {
          this.updatePublishStatus(data)
        }
      }
    )
  }

  updatePublishStatus (data) {
    this.data.set('allowPublish', data.allow_publish)

    this.renderPublishStatus()
  }

  renderPublishStatus () {
    const primaryAction = this.data.get('primaryAction')
    const allowPublish = this.data.get('allowPublish') === 'true'
    const show = allowPublish || primaryAction === 'save_and_continue'

    this.show_buttonsTarget.classList.toggle('d-none', !show)
    this.help_textTarget.classList.toggle('d-none', show)
  }
}
