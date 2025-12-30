# System Tests for Turbo Features

This directory contains comprehensive system tests for Turbo/Stimulus features implemented in the Rails 8 upgrade.

## Test Coverage

### 1. Admin Feedback Management (`admin_feedback_system_spec.rb`)
- **Turbo Frames**: Feedback list pagination without page reload
- **Turbo Streams**: Ham/spam toggle with instant UI updates
- **Filtering**: Spam, ham, and all feedback views

### 2. Article Autosave (`article_autosave_system_spec.rb`)
- **Stimulus Controller**: Autosave functionality every 30 seconds
- **Status Display**: Real-time save status updates
- **Draft Management**: Preview and destroy links

### 3. Stimulus Controllers (`stimulus_controllers_system_spec.rb`)
- **Dropdown Controller**: Menu toggle functionality
- **Flash Controller**: Auto-dismissing messages
- **CKEditor Controller**: Editor lifecycle management

### 4. Turbo Drive Navigation (`turbo_drive_navigation_spec.rb`)
- **Page Navigation**: Full-page navigation without reload
- **Session Persistence**: Maintained across Turbo requests
- **Library Verification**: Confirms Turbo/Stimulus loaded, Prototype removed

## Requirements

System tests require:
- **Google Chrome** or **Chromium** browser
- **ChromeDriver** compatible with installed Chrome version
- **Selenium WebDriver** gem (already in Gemfile)

## Running System Tests

### With Chrome Installed

```bash
# Run all system tests
bundle exec rspec spec/system

# Run specific test file
bundle exec rspec spec/system/turbo_drive_navigation_spec.rb

# Run with visible browser (non-headless)
# Modify spec/support/system_test_helper.rb to use :chrome instead of :headless_chrome
```

### In CI/CD Environments

For environments without a display (GitHub Actions, etc.):

```yaml
# .github/workflows/test.yml example
- name: Install Chrome
  run: |
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
    sudo apt-get update
    sudo apt-get install -y google-chrome-stable

- name: Run System Tests
  run: bundle exec rspec spec/system
```

## HTTP Mock Resolution

System tests require **real HTTP** for Selenium communication. The HTTP mocks in `spec/support/mocks/` are automatically excluded when running system tests.

To manually skip HTTP mocks for any test:

```bash
SKIP_HTTP_MOCKS=1 bundle exec rspec spec/system
```

## Configuration

System test configuration is in `spec/support/system_test_helper.rb`:

```ruby
# Headless Chrome with optimized flags
driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

# Custom helpers
login_as_admin          # Logs in as admin user
wait_for_turbo          # Waits for Turbo to finish loading
wait_for_turbo_frame(id) # Waits for specific frame to load
```

## Known Limitations

- System tests require a browser environment and may fail in minimal containers
- All functional tests (2548 examples) pass without browser requirements
- System tests are supplementary verification of Turbo features
- Manual testing in development is recommended for full UI verification

## Troubleshooting

### Chrome Not Found
```
session not created: Chrome instance exited
```
**Solution**: Install Google Chrome or Chromium browser

### ChromeDriver Version Mismatch
```
session not created: This version of ChromeDriver only supports Chrome version X
```
**Solution**: Update ChromeDriver to match your Chrome version or use webdrivers gem for automatic management

### HTTP Mock Conflicts
```
undefined method 'open_timeout=' for an instance of Net::Request
```
**Solution**: Already resolved - HTTP mocks are excluded from system tests in spec_helper.rb
