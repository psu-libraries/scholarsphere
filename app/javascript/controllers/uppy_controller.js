import { Controller } from 'stimulus'
import Uppy from '@uppy/core'
import AwsS3Multipart from '@uppy/aws-s3-multipart'
import Dashboard from '@uppy/dashboard'

export default class extends Controller {
  connect () {
    this.uploadSubmit = document.querySelector('.upload-submit')
    this.parentForm = document.getElementById(this.data.get('parentForm'))
    this.blacklist = JSON.parse(this.data.get('blacklist') || '[]')

    this.initializeUppy()
  }

  initializeUppy () {
    var isThumbnailForm = this.parentForm.attributes.class?.nodeValue === 'edit-thumbnail'

    var infoMssg = (isThumbnailForm) ? ' has already been uploaded' : ' already exists in this version'

    const sharedUppyOptions = {
      id: 'uppy_' + (new Date().getTime()),
      autoProceed: true,
      onBeforeFileAdded: (currentFile, files) => {
        const filename = currentFile.name
        const isBlacklisted = this.blacklist.includes(filename)

        if (isBlacklisted) {
          uppy.info(`Error: ${filename + infoMssg}`, 'error', 10000)
          return false
        }
      }
    }

    const sharedDashboardOptions = {
      id: 'dashboard',
      target: this.element,
      inline: 'true',
      showProgressDetails: true,
      doneButtonHandler: null
    }

    var uppyOptions = (isThumbnailForm)
      ? Object.assign({ allowMultipleUploads: false }, sharedUppyOptions)
      : Object.assign({ allowMultipleUploads: true }, sharedUppyOptions)

    var dashboardOptions = (isThumbnailForm)
      ? Object.assign({ height: 250, width: 350 }, sharedDashboardOptions)
      : Object.assign({ height: 350 }, sharedDashboardOptions)

    var uppy = Uppy(uppyOptions).use(Dashboard, dashboardOptions)
      .use(AwsS3Multipart, {
        companionUrl: '/'
      }).on('complete', result => this.onUppyComplete(result))
  }

  onUppyComplete (result) {
    // this.uploadSubmit.style.visibility='visible'
    result.successful.forEach(success => {
      this.parentForm.appendChild(this.createHiddenFileInput(success))
    })
  }

  createHiddenFileInput (success) {
    const inputName = this.data.get('inputName')
    const uploadedFileData = JSON.stringify({
      id: success.uploadURL.match(/\/cache\/([^?]+)/)[1],
      storage: 'cache',
      metadata: {
        size: success.data.size,
        filename: success.data.name,
        mime_type: success.data.type
      }
    })

    const input = document.createElement('input')
    input.setAttribute('type', 'hidden')
    input.setAttribute('name', inputName)
    input.setAttribute('value', uploadedFileData)

    return input
  }
}
