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

  describe 'Active Storage' do
    it 'has one attached file' do
      resource = Resource.new
      resource.should respond_to(:file)
    end

    it 'can attach a file' do
      resource = Factory(:resource)
      resource.file.attach(
        io: StringIO.new('PDF content'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
      resource.file.should be_attached
    end

    it 'can check if file is attached' do
      resource = Factory(:resource)
      resource.file.attached?.should be_falsey

      resource.file.attach(
        io: StringIO.new('content'),
        filename: 'test.txt',
        content_type: 'text/plain'
      )
      resource.file.attached?.should be_truthy
    end
  end

  describe '#url' do
    it 'returns nil when no file is attached' do
      resource = Factory(:resource)
      resource.url.should be_nil
    end

    it 'returns the blob path when file is attached' do
      resource = Factory(:resource)
      resource.file.attach(
        io: StringIO.new('content'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
      resource.url.should be_present
      resource.url.should include('/rails/active_storage/blobs')
    end
  end

  describe '#variant_url' do
    it 'returns nil when no file is attached' do
      resource = Factory(:resource)
      resource.variant_url(:thumb).should be_nil
    end

    it 'returns nil for non-image files' do
      resource = Factory(:resource, mime: 'application/pdf')
      resource.file.attach(
        io: StringIO.new('PDF content'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
      resource.variant_url(:thumb).should be_nil
    end

    it 'returns variant URL for image files' do
      resource = Factory(:resource, mime: 'image/png')
      # Create a minimal valid PNG
      png_data = "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82"
      resource.file.attach(
        io: StringIO.new(png_data),
        filename: 'test.png',
        content_type: 'image/png'
      )
      # For non-variable images, it should fall back to url
      url = resource.variant_url(:thumb)
      url.should be_present
    end
  end

  describe '#file_exists?' do
    it 'returns false when no file is attached' do
      resource = Factory(:resource)
      resource.file_exists?.should be_falsey
    end

    it 'returns true when file is attached' do
      resource = Factory(:resource)
      resource.file.attach(
        io: StringIO.new('content'),
        filename: 'test.txt',
        content_type: 'text/plain'
      )
      resource.file_exists?.should be_truthy
    end
  end

  describe 'associations' do
    it 'belongs to an article' do
      resource = Resource.new
      resource.should respond_to(:article)
      resource.should respond_to(:article=)
    end

    it 'can be associated with an article' do
      article = Factory(:article)
      resource = Factory(:resource, article: article)
      resource.article.should == article
    end

    it 'can exist without an article' do
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

  describe '#fullpath (legacy support)' do
    it 'returns the full path to the file when filename is set' do
      res = Factory.build(:resource, filename: 'a_new_file')
      res.fullpath.should == "#{::Rails.root.to_s}/public/files/a_new_file"
    end

    it 'returns the full path to a different file when passed as argument' do
      res = Factory.build(:resource, filename: 'original_file')
      res.fullpath('different_file').should == "#{::Rails.root.to_s}/public/files/different_file"
    end
  end

  describe 'scopes' do
    before(:each) do
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
  end
end
