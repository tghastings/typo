require 'spec_helper'

describe TrackbacksController do
  before do
    Factory(:blog)
  end

  describe "#index" do
    before do
      @article = Factory(:article)
      @trackback1 = Factory(:trackback, :article => @article, :published => true, :published_at => Time.now - 1.day)
      @trackback2 = Factory(:trackback, :article => @article, :published => true, :published_at => Time.now - 2.days)
    end

    describe "with :format => atom" do
      before do
        get :index, :format => :atom
      end

      it "is succesful" do
        expect(response).to be_success
      end

      it "passes the trackbacks to the template" do
        expect(assigns(:trackbacks)).not_to be_empty
        expect(assigns(:trackbacks)).to include(@trackback1, @trackback2)
      end

      it "renders the atom template" do
        expect(response).to render_template("index_atom_feed")
      end
    end

    describe "with :format => rss" do
      before do
        get :index, :format => :rss
      end

      it "is succesful" do
        expect(response).to be_success
      end

      it "passes the trackbacks to the template" do
        expect(assigns(:trackbacks)).not_to be_empty
        expect(assigns(:trackbacks)).to include(@trackback1, @trackback2)
      end

      it "renders the rss template" do
        expect(response).to render_template("index_rss_feed")
      end
    end
  end
end

