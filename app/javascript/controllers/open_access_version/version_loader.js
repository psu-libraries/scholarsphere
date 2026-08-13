const FETCH_HEADERS = { Accept: 'application/json' }
const FALLBACK_TIMEOUT = 10_000

export default class VersionLoader {
  constructor({ onVersionReceived, onLoadingTimedOut, onFinished }) {
    this.onVersionReceived = onVersionReceived
    this.onLoadingTimedOut = onLoadingTimedOut
    this.onFinished = onFinished
  }

  load(id) {
    fetch(`/dashboard/form/work_versions/${id}/open_access_version`, { headers: FETCH_HEADERS })
      .then((response) => {
        if (!response.ok) throw new Error('Network response was not ok')
        return response.json()
      })
      .then((data) => {
        if (!data) return
        this.onVersionReceived(data.open_access_version)
      })
      .catch(() => void 0)
  }

  start(id) {
    this.timerHandle = setTimeout(() => {
      if (this.onLoadingTimedOut()) {
        this.load(id)
      }

      this.onFinished()
    }, FALLBACK_TIMEOUT)
  }

  stop() {
    if (!this.timerHandle) return

    clearTimeout(this.timerHandle)
    this.timerHandle = null
  }
}