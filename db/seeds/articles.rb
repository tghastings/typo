# Seed file for blog articles from tom.hastings.dev
# Run with: rails db:seed

puts "Creating blog articles..."

articles_data = [
  {
    title: "Spring 2025 Student Project Reflections",
    published_at: DateTime.new(2025, 5, 10),
    permalink: "spring-2025-student-project-reflections",
    body: <<~BODY
      We just finished the Spring 25 semester at UCCS, and I am proud of my students who built some excellent applications in our Advanced Software Engineering course. Students shipped production-ready, AI-enhanced web apps—from a smart to-do list to a plant-ID game—using Django, external APIs, and CI/CD pipelines to identify code coverage metrics, code smells, and security vulnerabilities. Each team acted as a customer group for one group and a development group for another. They learned about full-stack development, cloud deployment solutions, agile methodologies, and teamwork, turning real-world problems into user-focused solutions.
    BODY
  },
  {
    title: "DevEdu... Edtech Cloud Development Environment",
    published_at: DateTime.new(2025, 1, 18),
    permalink: "devedu-edtech-cloud-development-enviroment",
    body: <<~BODY
      Educators can create an account, create a course, and assign development environments to the course. Students access containerized development environments through their web browsers, featuring VSCode with integrated terminal access.

      Instructors can configure specific environments—I use Django in my UCCS courses—where they specify the version of Python and Django each student gets. Students enroll using course links and launch containers matching the instructor's specifications.

      For students unable to purchase licenses, the platform offers docker images as open-source software so they can host the environments locally. The service also partners with bookstores to provide bulk licensing through textbook affordability programs.

      The platform has proven successful at UCCS with over 100 students, eliminating the need for individual technical support on personal devices while maintaining flexibility for different programming stacks.
    BODY
  },
  {
    title: "New Year, New Blog, Welcome Rails 8!",
    published_at: DateTime.new(2024, 12, 1),
    permalink: "new-year-new-blog-welcome-rails-8",
    body: <<~BODY
      I love this time of year. Things at work slowdown and I have time to learn new tools and techniques. This year, I've spent my time moving my blog over from Rails 6 with React and Devise to native Rails 8. Rails 8 provides an authentication mechanism and many new improvements.
    BODY
  },
  {
    title: "Graduated 2024! Ph.D.",
    published_at: DateTime.new(2024, 11, 9),
    permalink: "graduated-2024-ph-d",
    body: <<~BODY
      I finally made it. After six years studying at the University of Colorado Colorado Springs, I graduated in May with my Ph.D. in Engineering. I'm excited to be done and focus on my family and professional career that still includes teaching occasionally.
    BODY
  },
  {
    title: "New Paper in IEEE: Continuous Verification of Open Source Components in a World of Weak Links",
    published_at: DateTime.new(2023, 1, 16),
    permalink: "new-paper-in-ieee-continuous-verification-of-open-source",
    body: <<~BODY
      I published a research paper titled "Continuous Verification of Open Source Components in a World of Weak Links" available through IEEE.

      The paper addresses security risks in open source software, noting that 99% of today's software utilizes open source. These next-generation supply chain attacks have increased 430% in the last year.

      The work presents six continuous verification controls that enable organizations to make data-driven decisions and mitigate breaches. In case studies, the controls identified high levels of risk immediately even though the package is widely used and has over 7 million downloads a week.
    BODY
  },
  {
    title: "ARM Processors... Dev The Future... w/ a new platform",
    published_at: DateTime.new(2022, 1, 9),
    permalink: "arm-processors-dev-the-future-w-a-new-platform",
    body: <<~BODY
      I believe ARM processors will be the future for SaaS based applications.
    BODY
  },
  {
    title: "1st Docker Multi-Platform Build",
    published_at: DateTime.new(2021, 10, 31),
    permalink: "1st-docker-multi-platform-build",
    body: <<~BODY
      Built my first multi-platform Docker project for students who are utilizing Apple's M1 processor...

      My 1st #multiplatform #Docker build. My students are starting to jump on the #M1 train w/ #Apple.
    BODY
  },
  {
    title: "Engineering Software as a Service. 2nd Edition Beta.",
    published_at: DateTime.new(2021, 4, 22),
    permalink: "engineering-software-as-a-service-2nd-edition-beta",
    body: <<~BODY
      Three years ago, my advisor, Prof. Kristen Walcott, introduced me to an excellent set of software engineering curriculum. The curriculum was developed at UC Berkley by Prof. Armando Fox and Prof. David Patterson in partnership with EdX.

      More than 20,000 students earned certificates from these online courses since 2012, and more than 100,000 have completed parts of the course.

      Over the summer, I had the opportunity to collaborate with Dr. Fox and review/update the JavaScript chapter for the 2nd edition. Today, I received the new beta edition of the book in the mail. Thankful for the opportunity.
    BODY
  },
  {
    title: "Knocking Down Barriers for CS Education",
    published_at: DateTime.new(2021, 4, 17),
    permalink: "knocking-down-barriers-for-cs-education",
    body: <<~BODY
      Students deserve the best education regardless of socioeconomic factors and the pandemic has been widening the equity gaps.

      Last semester I found many of my CS students relied heavily on school computers to do their assignments.

      I've spent the last two weeks working nights and weekends to build a platform which can run as a #SaaS or on-prem.

      Students will be able to dev using a web browser on a platform that scales using #Kubernetes.

      Teachers can create #dev #environments for their students with a few clicks and schools can use their existing infrastructure (yes, even behind a firewall as long as the nodes can reach the internet) with the self hosted application.
    BODY
  },
  {
    title: "Back to Ruby on Rails w/ a React Twist",
    published_at: DateTime.new(2020, 12, 11),
    permalink: "back-to-ruby-on-rails-w-a-react-twist",
    body: <<~BODY
      Once again, I moved my blog to Ruby on Rails, but this time with a front-end written in React. I love it (minus the mass dependency list)! I still have a big place in my heart for Go, though, and VueJS.
    BODY
  },
  {
    title: "K8s & Docker",
    published_at: DateTime.new(2020, 12, 11),
    permalink: "k8s-docker",
    body: <<~BODY
      Enjoying Microk8s, Docker, and the TICK Stack.

      All the metrics. Monitoring #k8s, #docker, and #baremetal using the #TICK stack. Hosting #RocketChat, #GitLab, #Artifactory, #Nginx (reverse proxy), & #Keyclock (for SSO across all) in #Docker. Spinning dev containers on-demand running #RoR and #Cloud9 using #MicroK8s & #MetalLB.
    BODY
  },
  {
    title: "Dissertation Proposal Defended",
    published_at: DateTime.new(2020, 11, 10),
    permalink: "dissertation-proposal-defended",
    body: <<~BODY
      I defended my dissertation proposal at the University of Colorado at Colorado Springs. My research focuses on supply chain security threats in open source software.

      We are heading for a perfect storm, making open source software poisoning and next-generation supply chain attacks much easier to execute, which could have major implications for organizational security postures.

      99% of modern software contains open source components, and supply chain attacks have increased 430% annually according to Sonatype.
    BODY
  },
  {
    title: "To Catch a Scammer",
    published_at: DateTime.new(2019, 12, 31),
    permalink: "to-catch-a-scammer",
    body: <<~BODY
      Dan's written English was rough for being a consultant, with things like misspelled words, words in the wrong order, and wrong words.

      The letter had excellent English and grammar. I grew suspicious and copied a few lines from the letter and Googled it.

      Almost 800 search results appeared with the words verbatim. It would appear that Dan was forwarding love letters to my mom, which he did not write.

      I pulled his geographic data, showing that he was not in Washington, D.C. but in Nigeria. When my mom asked Dan about this, he ghosted her.

      Thankfully, we could identify Dan as a scammer before she lost any money. Some are not so lucky.
    BODY
  },
  {
    title: "My Top 5 Research Tools for Computer Science",
    published_at: DateTime.new(2019, 1, 13),
    permalink: "my-top-5-research-tools-for-computer-science",
    body: <<~BODY
      1. Zotero - Zotero provides an easy way to manage bibliographies and includes easy export for Bibtex.

      2. Overleaf - Overleaf is a great tool for working with LaTex. It provides a web based editor for individuals or teams to work on documents.

      3. GitHub - GitHub provides Git repositories for team collaboration.

      4. Student Developer Pack - The student developer pack from GitHub provides tons of goodies from companies like Amazon Web Services, Data Dog, Digital Ocean and others.

      5. Google Scholar - Google Scholar provides great resources for researchers. Everything from research papers to H-index and conference rankings.
    BODY
  },
  {
    title: "New Year with JAMstack",
    published_at: DateTime.new(2019, 1, 12),
    permalink: "new-year-with-jamstack",
    body: <<~BODY
      The JAMstack is a relativity new concept in web development, and it caught my attention because of the simplicity and speed at which pages load.

      I developed a simple service that provides a headless RESTful API to create, read, update, and delete blog posts.

      I also wrote a user authentication package that uses bcrypt for password hashing and JSON Web Tokens for API authentication.

      The front-end uses basic HTML and CSS along with vue.js and vanilla JavaScript.

      The front-end is hosted for free with SSL on GitHub Pages.

      The API and front-end source code are all open source, and you can see the roadmap for the API in the README on GitHub.
    BODY
  },
  {
    title: "Software Supply Chain Open Source Issues. Part 1.",
    published_at: DateTime.new(2018, 9, 18),
    permalink: "software-supply-chain-open-source-issues-part-1",
    body: <<~BODY
      With the rise of languages that provide package management tools, developers and software engineers are spending more time integrating than coding.

      Open source packages save developers hundreds of hours by providing functionality that the developer does not have to write herself.

      The code is now part of the developer's software.

      What dependencies did the open source project bring in? Do those dependencies have known vulnerabilities?

      These are all risks associated with using open source projects.
    BODY
  },
  {
    title: "User Interaction Metrics for Hybrid Mobile Applications",
    published_at: DateTime.new(2018, 7, 24),
    permalink: "user-interaction-metrics-for-hybrid-mobile-applications",
    body: <<~BODY
      Understanding user behavior and interactions in mobile applications are critical for developers to understand where to spend limited resources when adding, updating, and testing features.

      User behavior insights can provide value to the developer when it's time to code and implement new features.

      Google Analytics and New Relic provide user insights, but they fall short when it comes to identifying user interactions and behaviors pertaining to mobile applications' individual features.

      We have developed a framework with middleware that provides user interaction insights, using time-series analysis for hybrid mobile applications and an empirical study to showcase the value of the framework.
    BODY
  },
  {
    title: "What's In Your Container?",
    published_at: DateTime.new(2018, 4, 30),
    permalink: "what-s-in-your-container",
    body: <<~BODY
      I'm excited to be speaking at JFrog's swampUP conference in May.

      I'll be speaking on using Xray and Artifactory to produce secure containers.

      Avoiding known security vulnerability in prod, providing the US Gov with a complete Bill or Materials and ensuring compliance with copyright laws does not need to be scary.

      A brief case study in how to use JFrog products to support missions and developers around the globe.
    BODY
  },
  {
    title: "Ad-hoc Ansible Commands",
    published_at: DateTime.new(2017, 12, 20),
    permalink: "ad-hoc-ansible-commands",
    body: <<~BODY
      Sometimes I like to stash commands that I use regularly. Below is a snippet of code that I find helpful from time to time.
    BODY
  },
  {
    title: "Docker Catch Sigterm",
    published_at: DateTime.new(2017, 12, 18),
    permalink: "docker-catch-sigterm",
    body: <<~BODY
      Sometimes I like to stash commands that I use regularly. Below is a snippet of code that I find helpful from time to time.
    BODY
  },
  {
    title: "Cost of Securing IEEE 802.11s Mesh Networks Using CJDNS",
    published_at: DateTime.new(2017, 5, 10),
    permalink: "cost-of-securing-ieee-802-11s-mesh-networks-using-cjdns",
    body: <<~BODY
      The Internet is weak, it is broken, and we are not doing anything to fix it.

      The Internet can be affected by natural disasters, wars, governments, and surveillance.

      It is running out of address space and the internet service providers are not incentivized to fix it.

      Mesh networks, using the IEEE standard 802.11s, may one day provide a more robust and resilient infrastructure.

      IEEE 802.11s makes mesh networks a reality for users who otherwise would never have been able to setup such a distributed network.

      Applications like cjdns are making it easier than ever to create secure wireless mesh network among communities.

      This paper will look at the system costs associated with using cjdns.

      How much performance are we willing to sacrifice for ease of use and security?
    BODY
  },
  {
    title: "SailsJS Error on Install: npm ERR! enoent ENOENT",
    published_at: DateTime.new(2017, 3, 18),
    permalink: "sailsjs-error-on-install-npm-err-enoent-enoent",
    body: <<~BODY
      npm ERR! enoent ENOENT: no such file or directory, chmod '/node_modules/sails/node_modules/anchor/node_modules/geojsonhint/node_modules/jsonlint-lines/node_modules/nomnom/node_modules/chalk/node_modules/strip-ansi/cli.js'

      A temporary solution is to modify the package.json file to use a GitHub fork instead of the standard npm package:

      'sails': 'github:tghastings/sails#hastings-fix',

      Following this change, users should clear their node_modules directory and npm cache before reinstalling dependencies. I submitted a pull request to the anchor project on GitHub that adds the geojsonhint dependency back into package.json.
    BODY
  },
  {
    title: "DisplayLink Video - Ubuntu 16.10 - 1 FPS Issue: Fixed",
    published_at: DateTime.new(2017, 3, 12),
    permalink: "displaylink-video-ubuntu-16-10-1-fps-issue-fixed",
    body: <<~BODY
      I ran into an issue using my Dell USB 3.0 dock when I upgraded to Ubuntu 16.10 on my Dell XPS-13. I was getting ~1 FPS using the DisplayLink driver. I ended up having to turn off VSync. Hopefully DisplayLink releases an update soon to fix this.

      Section 'Device'
      Identifier 'Intel Graphics'
      Driver 'intel'
      Option 'VSync' 'false'
      EndSection
    BODY
  },
  {
    title: "What I learned developing real-time web applications",
    published_at: DateTime.new(2016, 12, 29),
    permalink: "what-i-learned-developing-real-time-web-applications",
    body: <<~BODY
      I developed a system that processes approximately 29 messages per second, averaging 3KB each.

      It's optimal to update the DOM all at once with one function if you can. Target specific elements rather than broad updates by wrapping changeable values in spans with IDs.

      Do NOT rely heavily on the front-end for logical reasoning. Data validation and state management should occur server-side before reaching the view layer.

      Google Chrome limits the number of open sockets to 6. Using Chrome's developer tools, we noticed that the event source, for every message, continued to grow in size.

      We implemented two event sources running in parallel on the client. The first event source listens for critical status messages while the other listens for applicable data based on the user's page.

      This was the most challenging and most fun project that I've worked on to date.
    BODY
  },
  {
    title: "Welcome",
    published_at: DateTime.new(2016, 12, 10),
    permalink: "welcome",
    body: <<~BODY
      Welcome. I just updated my blog and moved it on to Heroku. Stay tuned for new updates.
    BODY
  }
]

articles_data.each do |article_attrs|
  article = Article.find_or_initialize_by(permalink: article_attrs[:permalink])
  article.assign_attributes(
    title: article_attrs[:title],
    body: article_attrs[:body].strip,
    published_at: article_attrs[:published_at],
    published: true,
    state: "published",
    allow_comments: true,
    allow_pings: true,
    text_filter_id: 2 # Markdown
  )
  article.save!
  puts "  Created/Updated: #{article.title}"
end

puts "Created #{articles_data.length} articles!"
