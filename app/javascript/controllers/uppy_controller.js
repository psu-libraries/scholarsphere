import { Controller } from 'stimulus'
import Uppy from '@uppy/core'
import AwsS3Multipart from '@uppy/aws-s3-multipart'
import Dashboard from '@uppy/dashboard'

export default class extends Controller {
  connect() {
    this.uploadSubmit = document.querySelector('.upload-submit')
    this.parentForm = document.getElementById(this.data.get('parentForm'))
    this.blacklist = JSON.parse(this.data.get('blacklist') || '[]')

    this.initializeUppy()
  }

  initializeUppy() {
    const uppy = new Uppy({
      id: 'uppy_' + (new Date().getTime()),
      autoProceed: false,
      allowMultipleUploads: true,
      onBeforeFileAdded: (currentFile, files) => {
        const filename = currentFile.name
        const isBlacklisted = this.blacklist.includes(filename)

        if (isBlacklisted) {
          uppy.info(`Error: ${filename} already exists in this version`, 'error', 10000)
          return false
        }
      },
      onBeforeUpload: (files) => {
        const fileCount = Object.keys(files).length
        const file = Object.values(files)[fileCount - 1]
        const missingAltText = file.type?.startsWith('image/') && !file.meta.alt_text?.trim()

        if (missingAltText) {
          uppy.info('Please provide alt text for all image files before uploading.', 'error')
          const editButton = document.querySelector('.uppy-u-reset')

          if (editButton) {
            // Simulate a click on the edit button
            editButton.click()
            setTimeout(() => {
              document.addEventListener('click', (e) => {
                // Detect "Save changes" button click in Uppy metadata editor
                if (e.target.type === 'submit') {
                  // Wait a tick to let the file card close and upload button render
                  setTimeout(() => {
                    const uploadButton = document.querySelector('.uppy-StatusBar-actionBtn--upload')
                    if (uploadButton) {
                      // Simulate a click on the upload button
                      uploadButton.click()
                      console.log('Upload button clicked successfully after saving changes.')
                    }
                  }, 100) // Adjust timing if needed
                }
              })
            }, 100)
          }
          return false
        }
      }
    })
      .use(Dashboard, {
        id: 'dashboard',
        target: this.element,
        inline: 'true',
        showProgressDetails: true,
        height: 350,
        doneButtonHandler: null,
        metaFields: [
          {
            id: 'alt_text',
            name: 'Alt Text',
            placeholder: 'Describe this image for accessibility',
            required: true
          }
        ]
      })
      .use(AwsS3Multipart, {
        companionUrl: '/'
      })
      .on('file-added', (file) => {
        if (file.type.startsWith('image/')) {
          uppy.pauseResume(file.id)
          setTimeout(() => {
            const editButton = document.querySelector('.uppy-u-reset')

            if (editButton) {
              // Simulate a click on the edit button
              editButton.click()
              setTimeout(() => {
                document.addEventListener('click', (e) => {
                  // Detect "Save changes" button click in Uppy metadata editor
                  if (e.target.type === 'submit') {
                    // Wait a tick to let the file card close and upload button render
                    setTimeout(() => {
                      const uploadButton = document.querySelector('.uppy-StatusBar-actionBtn--upload')
                      if (uploadButton) uploadButton.click()
                    }, 100) // Adjust timing if needed
                  }
                }), 100
              })
            }
          }, 100)
        } else {
          uppy.upload()
        }
      })
      .on('complete', result => this.onUppyComplete(result))
  }

  onUppyComplete(result) {
    // this.uploadSubmit.style.visibility='visible'
    result.successful.forEach(success => {
      this.parentForm.appendChild(this.createHiddenFileInput(success))
    })
  }

  createHiddenFileInput(success) {
    const inputName = this.data.get('inputName')
    const uploadedFileData = JSON.stringify({
      id: success.uploadURL.match(/\/cache\/([^?]+)/)[1],
      storage: 'cache',
      metadata: {
        size: success.data.size,
        filename: success.data.name,
        mime_type: success.data.type,
        alt_text: success.meta.alt_text
      }
    })

    const input = document.createElement('input')
    input.setAttribute('type', 'hidden')
    input.setAttribute('name', inputName)
    input.setAttribute('value', uploadedFileData)

    return input
  }
}
