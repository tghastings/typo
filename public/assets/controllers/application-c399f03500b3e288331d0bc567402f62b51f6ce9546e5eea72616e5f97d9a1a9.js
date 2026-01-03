import { Application } from "@hotwired/stimulus"

const application = new Application()
application.debug = false
window.Stimulus = application

export { application };
