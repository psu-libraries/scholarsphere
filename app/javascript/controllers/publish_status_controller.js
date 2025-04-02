import { Controller } from 'stimulus'
import consumer from "../channels/consumer"

export default class extends Controller {
  static targets = ['show_buttons'];

  connect() {
    consumer.subscriptions.create(
      { channel: "PublishStatusChannel" },
      {
        connected: () => {
            this.renderPublishStatus()
        },
        received: (data) => {
            this.updatePublishStatus(data)
        }
      }
    )
    console.log("TESTING: PublishStatusChannel subscription created");
  }

  updatePublishStatus (data) {
    this.data.set('allowPublish', data.allow_publish)
    
    this.renderPublishStatus()
  }

  renderPublishStatus () {
    const primaryAction = this.data.get('primaryAction')
    const allowPublish = this.data.get('allowPublish') === 'true'
    const show = allowPublish || primaryAction === "save_and_continue"

    console.log("TESTING: PublishStatusController show set as ", show);
    this.show_buttonsTarget.classList.toggle('d-none', !show);
  }
}