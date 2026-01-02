import { Application } from "@hotwired/stimulus"

// Create application but delay start
const application = new Application()
application.debug = true
window.Stimulus = application

console.log('Stimulus application created (not started yet)')

export { application };
