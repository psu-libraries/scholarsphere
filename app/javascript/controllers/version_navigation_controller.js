import { Controller } from 'stimulus'

export default class extends Controller {
  connect () {
    // auto-scroll to the active version so it's visible on initial page load
    const versionNavigation = this.element
    const activeVersion = versionNavigation.querySelector('.active')

    versionNavigation.scrollTop = activeVersion.offsetTop
  }
}
