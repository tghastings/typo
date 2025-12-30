require 'spec_helper'

describe Resource do
  describe 'Factory' do
    it 'should create a valid resource' do
      resource = Factory(:resource)
      resource.should be_valid
    end

    it 'should build a valid resource' do
      resource = Factory.build(:resource)
      resource.should be_valid
    end
  end

  describe 'validations' do
    it 'validates uniqueness of filename' do
      allow(File).to receive(:exist?).and_return(false)
      Factory(:resource, filename: 'unique_file.jpg')
      duplicate = Factory.build(:resource, filename: 'unique_file.jpg')
      duplicate.should_not be_valid
      # The error is stored on :upload which is an alias for :filename
      (duplicate.errors[:upload].any? || duplicate.errors[:filename].any?).should be_truthy
    end
  end

  describe 'associations' do
    it 'belongs to an article' do
      resource = Resource.new
      resource.should respond_to(:article)
      resource.should respond_to(:article=)
    end

    it 'can be associated with an article' do
      allow(File).to receive(:exist?).and_return(false)
      article = Factory(:article)
      resource = Factory(:resource, article: article)
      resource.article.should == article
    end

    it 'can exist without an article' do
      allow(File).to receive(:exist?).and_return(false)
      resource = Factory(:resource, article: nil)
      resource.should be_valid
      resource.article.should be_nil
    end
  end

  describe 'alias_attribute' do
    it 'aliases upload to filename' do
      resource = Resource.new
      resource.filename = 'test.jpg'
      resource.upload.should == 'test.jpg'
    end

    it 'aliases filename to upload' do
      resource = Resource.new
      resource.upload = 'test.jpg'
      resource.filename.should == 'test.jpg'
    end
  end

  describe '#fullpath' do
    it 'returns the full path to the file when filename is set' do
      res = Factory.build(:resource, filename: 'a_new_file')
      res.fullpath.should == "#{::Rails.root.to_s}/public/files/a_new_file"
    end

    it 'returns the full path to a different file when passed as argument' do
      res = Factory.build(:resource, filename: 'original_file')
      res.fullpath('different_file').should == "#{::Rails.root.to_s}/public/files/different_file"
    end

    it 'returns the directory path when passed an empty string' do
      res = Factory.build(:resource, filename: 'some_file')
      res.fullpath('').should == "#{::Rails.root.to_s}/public/files/"
    end
  end

  describe 'scopes' do
    before(:each) do
      allow(File).to receive(:exist?).and_return(false)
      Resource.destroy_all
    end

    describe '#without_images' do
      it 'returns resources that are not images (based on mime type)' do
        other_resource = Factory(:resource, mime: 'text/css')
        image_resource = Factory(:resource, mime: 'image/jpeg')
        Resource.without_images.should == [other_resource]
      end

      it 'includes various non-image mime types' do
        css_resource = Factory(:resource, mime: 'text/css')
        pdf_resource = Factory(:resource, mime: 'application/pdf')
        html_resource = Factory(:resource, mime: 'text/html')
        Resource.without_images.should include(css_resource, pdf_resource, html_resource)
      end
    end

    describe '#images' do
      it 'returns only images (based on mime type)' do
        other_resource = Factory(:resource, mime: 'text/css')
        image_resource = Factory(:resource, mime: 'image/jpeg')
        Resource.images.should == [image_resource]
      end

      it 'includes various image mime types' do
        jpeg_resource = Factory(:resource, mime: 'image/jpeg')
        png_resource = Factory(:resource, mime: 'image/png')
        gif_resource = Factory(:resource, mime: 'image/gif')
        Resource.images.should include(jpeg_resource, png_resource, gif_resource)
      end
    end

    describe '#by_filename' do
      it 'sorts resources by filename' do
        b_resource = Factory(:resource, filename: 'b_file')
        a_resource = Factory(:resource, filename: 'a_file')
        c_resource = Factory(:resource, filename: 'c_file')
        Resource.by_filename.should == [a_resource, b_resource, c_resource]
      end
    end

    describe '#by_created_at' do
      it 'sorts resources by created_at DESC' do
        old_resource = Factory(:resource, created_at: DateTime.new(2011, 2, 21))
        new_resource = Factory(:resource, created_at: DateTime.new(2011, 3, 13))
        Resource.by_created_at.should == [new_resource, old_resource]
      end
    end

    describe '#without_images_by_filename' do
      it 'combines without_images and by_filename scopes' do
        image_resource = Factory(:resource, mime: 'image/jpeg')
        b_resource = Factory(:resource, mime: 'text/html', filename: 'b_file')
        a_resource = Factory(:resource, mime: 'text/html', filename: 'a_file')
        Resource.without_images_by_filename.should == [a_resource, b_resource]
      end
    end

    describe '#images_by_created_at' do
      it 'combines images and by_created_at scopes' do
        text_resource = Factory(:resource, mime: 'text/html')
        old_image = Factory(:resource, mime: 'image/jpeg', created_at: DateTime.new(2011, 1, 1))
        new_image = Factory(:resource, mime: 'image/png', created_at: DateTime.new(2011, 2, 1))
        Resource.images_by_created_at.should == [new_image, old_image]
      end
    end
  end

  describe '#uniq_filename_on_disk' do
    it 'keeps the original filename if it does not exist on disk' do
      expect(File).to receive(:exist?).with(%r{public/files/new_file\.jpg$}).and_return(false)
      resource = Factory(:resource, filename: 'new_file.jpg')
      resource.should be_valid
      resource.filename.should == 'new_file.jpg'
    end

    it 'appends a number if the filename already exists on disk' do
      expect(File).to receive(:exist?).with(%r{public/files/me\.jpg$}).and_return(true)
      expect(File).to receive(:exist?).with(%r{public/files/me1\.jpg$}).at_least(:once).and_return(false)

      resource = Factory(:resource, filename: 'me.jpg')
      resource.should be_valid
      resource.filename.should == 'me1.jpg'
    end

    it 'increments until finding an available filename' do
      expect(File).to receive(:exist?).with(%r{public/files/test\.jpg$}).and_return(true)
      expect(File).to receive(:exist?).with(%r{public/files/test1\.jpg$}).and_return(true)
      expect(File).to receive(:exist?).with(%r{public/files/test2\.jpg$}).and_return(false)

      resource = Factory(:resource, filename: 'test.jpg')
      resource.should be_valid
      resource.filename.should == 'test2.jpg'
    end

    it 'raises error if filename is empty' do
      expect {
        Factory(:resource, filename: '')
      }.to raise_error(RuntimeError)
    end

    it 'sanitizes filename by replacing special characters with underscores' do
      expect(File).to receive(:exist?).and_return(false)
      resource = Factory(:resource, filename: 'my file@#$.jpg')
      resource.filename.should == 'my_file___.jpg'
    end

    it 'handles backslashes in filenames (Windows paths)' do
      expect(File).to receive(:exist?).and_return(false)
      resource = Factory(:resource, filename: 'C:\\Users\\test\\file.jpg')
      resource.filename.should == 'file.jpg'
    end
  end

  describe '#delete_filename_on_disk' do
    it 'deletes the associated file when resource is destroyed' do
      expect(File).to receive(:exist?).and_return(false)
      resource = Factory(:resource, filename: 'file_to_delete')

      expect(File).to receive(:exist?).with(resource.fullpath).and_return(true)
      expect(File).to receive(:unlink).with(resource.fullpath).and_return(true)
      resource.destroy
    end

    it 'does not attempt to delete if file does not exist' do
      expect(File).to receive(:exist?).and_return(false)
      resource = Factory(:resource, filename: 'nonexistent_file')

      expect(File).to receive(:exist?).with(resource.fullpath).and_return(false)
      expect(File).not_to receive(:unlink)
      resource.destroy
    end
  end

  describe '#write_to_disk' do
    let(:resource) { Factory.build(:resource, filename: 'test_file.jpg', mime: 'image/jpeg') }

    before do
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:directory?).and_return(true)
      allow(File).to receive(:chmod)
      allow(File).to receive(:stat).and_return(double(size: 1024))
      allow(FileUtils).to receive(:mkdir)
      allow(FileUtils).to receive(:copy)
      allow(resource).to receive(:create_thumbnail)
      allow(resource).to receive(:update)
    end

    it 'creates the public/files directory if it does not exist' do
      allow(File).to receive(:directory?).with(resource.fullpath('')).and_return(false)
      expect(FileUtils).to receive(:mkdir).with(resource.fullpath(''))
      resource.write_to_disk('test data')
    end

    it 'does not create directory if it already exists' do
      allow(File).to receive(:directory?).with(resource.fullpath('')).and_return(true)
      expect(FileUtils).not_to receive(:mkdir)
      resource.write_to_disk('test data')
    end

    it 'handles Tempfile with local_path' do
      tempfile = double('Tempfile')
      allow(tempfile).to receive(:kind_of?).with(Tempfile).and_return(true)
      allow(tempfile).to receive(:kind_of?).with(ActionDispatch::Http::UploadedFile).and_return(false)
      allow(tempfile).to receive(:kind_of?).with(StringIO).and_return(false)
      allow(tempfile).to receive(:local_path).and_return('/tmp/test_file')
      allow(File).to receive(:exist?).with('/tmp/test_file').and_return(true)

      expect(File).to receive(:chmod).with(0600, '/tmp/test_file')
      expect(FileUtils).to receive(:copy).with('/tmp/test_file', resource.fullpath)

      resource.write_to_disk(tempfile)
    end

    it 'handles ActionDispatch::Http::UploadedFile' do
      uploaded_file = double('UploadedFile')
      allow(uploaded_file).to receive(:kind_of?).with(Tempfile).and_return(false)
      allow(uploaded_file).to receive(:kind_of?).with(ActionDispatch::Http::UploadedFile).and_return(true)
      allow(uploaded_file).to receive(:kind_of?).with(StringIO).and_return(false)
      allow(uploaded_file).to receive(:path).and_return('/tmp/uploaded_file')

      expect(File).to receive(:chmod).with(0600, '/tmp/uploaded_file')
      expect(FileUtils).to receive(:copy).with('/tmp/uploaded_file', resource.fullpath)

      resource.write_to_disk(uploaded_file)
    end

    it 'handles StringIO by reading and writing bytes' do
      string_io = StringIO.new('test content')
      allow(string_io).to receive(:kind_of?).and_call_original
      allow(string_io).to receive(:kind_of?).with(Tempfile).and_return(false)
      allow(string_io).to receive(:kind_of?).with(ActionDispatch::Http::UploadedFile).and_return(false)

      file_double = double('File')
      expect(File).to receive(:open).with(resource.fullpath, 'wb').and_yield(file_double)
      expect(file_double).to receive(:write).with('test content')

      resource.write_to_disk(string_io)
    end

    it 'handles plain bytes by writing directly' do
      bytes = 'raw bytes content'

      file_double = double('File')
      expect(File).to receive(:open).with(resource.fullpath, 'wb').and_yield(file_double)
      expect(file_double).to receive(:write).with(bytes)

      resource.write_to_disk(bytes)
    end

    it 'sets file permissions to 0644 after writing' do
      expect(File).to receive(:chmod).with(0644, resource.fullpath)
      resource.write_to_disk('test data')
    end

    it 'updates the size attribute from the file stat' do
      allow(File).to receive(:stat).with(resource.fullpath).and_return(double(size: 2048))
      resource.write_to_disk('test data')
      resource.size.should == 2048
    end

    it 'calls create_thumbnail after writing' do
      expect(resource).to receive(:create_thumbnail)
      resource.write_to_disk('test data')
    end

    it 'calls update after writing' do
      expect(resource).to receive(:update)
      resource.write_to_disk('test data')
    end

    it 'returns self after successful write' do
      result = resource.write_to_disk('test data')
      result.should == resource
    end

    it 'handles stat errors by setting size to 0' do
      allow(File).to receive(:stat).and_raise(Errno::ENOENT)
      resource.write_to_disk('test data')
      resource.size.should == 0
    end
  end

  describe '#create_thumbnail' do
    let(:blog) { Factory(:blog) }
    let(:resource) { Factory.build(:resource, filename: 'image.jpg', mime: 'image/jpeg') }

    before do
      allow(File).to receive(:exist?).and_return(false)
      allow(Blog).to receive(:default).and_return(blog)
    end

    it 'does nothing if mime type is not an image' do
      resource.mime = 'text/plain'
      expect(MiniMagick::Image).not_to receive(:from_file)
      resource.create_thumbnail
    end

    it 'does nothing if the original file does not exist' do
      resource.mime = 'image/jpeg'
      allow(File).to receive(:exist?).with(resource.fullpath('image.jpg')).and_return(false)
      expect(MiniMagick::Image).not_to receive(:from_file)
      resource.create_thumbnail
    end

    it 'creates medium and thumb thumbnails when original exists' do
      resource.mime = 'image/jpeg'
      allow(File).to receive(:exist?).with(resource.fullpath('image.jpg')).and_return(true)
      allow(File).to receive(:exist?).with(resource.fullpath('medium_image.jpg')).and_return(false)
      allow(File).to receive(:exist?).with(resource.fullpath('thumb_image.jpg')).and_return(false)

      img_mock = double('MiniMagick::Image')
      allow(MiniMagick::Image).to receive(:from_file).and_return(img_mock)
      allow(blog).to receive(:image_medium_size).and_return(600)
      allow(blog).to receive(:image_thumb_size).and_return(125)
      allow(img_mock).to receive(:resize).and_return(img_mock)
      allow(img_mock).to receive(:write)

      expect(img_mock).to receive(:resize).with('600x600').and_return(img_mock)
      expect(img_mock).to receive(:write).with(resource.fullpath('medium_image.jpg'))
      expect(img_mock).to receive(:resize).with('125x125').and_return(img_mock)
      expect(img_mock).to receive(:write).with(resource.fullpath('thumb_image.jpg'))

      resource.create_thumbnail
    end

    it 'skips creating thumbnail if it already exists' do
      resource.mime = 'image/jpeg'
      allow(File).to receive(:exist?).with(resource.fullpath('image.jpg')).and_return(true)
      allow(File).to receive(:exist?).with(resource.fullpath('medium_image.jpg')).and_return(true)
      allow(File).to receive(:exist?).with(resource.fullpath('thumb_image.jpg')).and_return(true)

      img_mock = double('MiniMagick::Image')
      allow(MiniMagick::Image).to receive(:from_file).and_return(img_mock)
      expect(img_mock).not_to receive(:resize)
      expect(img_mock).not_to receive(:write)

      resource.create_thumbnail
    end

    it 'handles errors gracefully and returns nil' do
      resource.mime = 'image/jpeg'
      allow(File).to receive(:exist?).with(resource.fullpath('image.jpg')).and_return(true)
      allow(MiniMagick::Image).to receive(:from_file).and_raise(StandardError)

      result = resource.create_thumbnail
      result.should be_nil
    end
  end

  describe 'callbacks' do
    it 'runs uniq_filename_on_disk before validation on create' do
      allow(File).to receive(:exist?).and_return(false)
      resource = Resource.new(filename: 'test.jpg', mime: 'image/jpeg', size: 100)
      resource.save
      resource.should be_persisted
    end

    it 'runs delete_filename_on_disk after destroy' do
      allow(File).to receive(:exist?).and_return(false)
      resource = Factory(:resource, filename: 'to_delete.jpg')

      allow(File).to receive(:exist?).with(resource.fullpath).and_return(false)
      resource.destroy
      resource.should be_destroyed
    end
  end
end
