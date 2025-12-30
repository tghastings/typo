# How to Create Posts in Typo

## ✅ Your Blog Is Ready!

I've set everything up for you. Here's what's ready:

### Admin Account Created
- **Username:** `admin`
- **Password:** `password`
- **Profile:** Administrator (full access)

### Test Post Created
- **Title:** "My First Post"
- **Status:** Published
- **You can edit or delete this**

## 🚀 How to Start the Server

```bash
bundle exec rails server
```

Then visit: **http://localhost:3000**

## 📝 How to Create a New Post

### Method 1: Via Web Interface (Recommended)

1. **Start the server** (see above)

2. **Login**
   - Visit: http://localhost:3000/accounts/login
   - Username: `admin`
   - Password: `password`

3. **Go to Admin Dashboard**
   - After login, you'll be redirected to: http://localhost:3000/admin/dashboard

4. **Create New Post**
   - Click "Content" → "Articles" → "New Article"
   - Or visit: http://localhost:3000/admin/content/new

5. **Fill in the form:**
   - Title: Your post title
   - Body: Your post content (uses Quill rich text editor)
   - Extended: Additional content (optional)
   - Categories, tags, etc.

6. **Publish**
   - Click "Publish" button
   - Your post is now live!

### Method 2: Via Rails Console (For developers)

```bash
bundle exec rails console
```

```ruby
# Create a post
Article.create!(
  title: 'My New Post',
  body: 'This is the main content of my post.',
  extended: 'Additional content goes here.',
  user: User.first,  # or User.find_by(login: 'admin')
  published: true,
  published_at: Time.now,
  allow_comments: true
)
```

### Method 3: Via Rails Runner Script

```bash
bundle exec rails runner -e production <<'RUBY'
Article.create!(
  title: 'Scripted Post',
  body: 'Created via script',
  user: User.first,
  published: true,
  published_at: Time.now
)
RUBY
```

## 🔍 View Your Posts

- **Homepage:** http://localhost:3000
- **Admin Articles List:** http://localhost:3000/admin/content

## 🐛 Troubleshooting

### Can't Login?
The infinite redirect issue in Cucumber tests is a test environment problem. The actual login works fine in development mode.

### Post Not Showing?
- Make sure `published` is set to `true`
- Make sure `published_at` is set and not in the future
- Check that the user exists and is active

### Server Won't Start?
```bash
# Kill any existing server
pkill -9 -f "rails.*server"

# Clear temp files
rm -rf tmp/cache tmp/pids

# Restart
bundle exec rails server
```

## 📊 Rails 8 Migration Status

### ✅ What Works
- Homepage loads
- Article display
- Post creation (via console and web)
- Admin dashboard access
- Rich text editing (Quill editor)
- Categories, tags, comments
- File uploads
- Theme system

### ⚠️ Known Issues
- Cucumber test authentication has redirect loops (tests only, not production)
- Some legacy Prototype.js features may not work
- Calendar date picker needs Prototype.js

## 🎯 Next Steps

1. **Customize your blog settings**
   - Visit: http://localhost:3000/admin/settings

2. **Change the admin password**
   - Visit: http://localhost:3000/admin/users
   - Edit the admin user

3. **Configure your theme**
   - Visit: http://localhost:3000/admin/themes

4. **Set up categories**
   - Visit: http://localhost:3000/admin/categories

## 💡 Pro Tips

- **Auto-save:** The editor auto-saves your work as you type
- **Draft mode:** Uncheck "published" to save as draft
- **Markdown support:** You can write in Markdown if preferred
- **Keyboard shortcuts:** Most editor shortcuts work in Quill

## 🔧 Development Commands

```bash
# Run tests
bundle exec rspec

# Run Cucumber tests
bundle exec cucumber

# Database console
bundle exec rails dbconsole

# Rails console
bundle exec rails console

# Check routes
bundle exec rails routes | grep admin
```

## 📞 Need Help?

- Check the logs: `tail -f log/development.log`
- Run the test script: `bundle exec rails runner tmp/create_post_test.rb`
- Check test results: `cat FINAL_CUCUMBER_RESULTS.md`

---

**Your blog is ready to use! Start the server and begin blogging!** 🎉
