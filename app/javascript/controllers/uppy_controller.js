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
    var is_thumbnail_form = this.parentForm.attributes.class?.nodeValue === 'edit-thumbnail';

    var info_mssg = (is_thumbnail_form) ? ' has already been uploaded' : ' already exists in this version';

    const shared_uppy_options = {
      id: 'uppy_' + (new Date().getTime()),
      autoProceed: true,
      onBeforeFileAdded: (currentFile, files) => {
        const filename = currentFile.name
        const isBlacklisted = this.blacklist.includes(filename)

        if (isBlacklisted) {
          uppy.info(`Error: ${filename + info_mssg}`, 'error', 10000)
          return false
        }
      }
    };

    const shared_dashboard_options = {
      id: 'dashboard',
      target: this.element,
      inline: 'true',
      showProgressDetails: true,
      doneButtonHandler: null
    };

    var uppy_options =
      (is_thumbnail_form) ?
        uppy_options = Object.assign({ allowMultipleUploads: false }, shared_uppy_options)
      :
        uppy_options = Object.assign({ allowMultipleUploads: true }, shared_uppy_options)
      ;

    var dashboard_options =
      (is_thumbnail_form) ?
        dashboard_options = Object.assign({ height: 250, width: 350 }, shared_dashboard_options)
      :
        dashboard_options = Object.assign({ height: 350 }, shared_dashboard_options)
      ;

    var uppy = Uppy(uppy_options).use(Dashboard, dashboard_options)
        .use(AwsS3Multipart, {
          companionUrl: '/'
        }).on('complete', result => this.onUppyComplete(result));
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
