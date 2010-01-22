require File.dirname(__FILE__) + '/../spec_helper'

# This depends on Asset being defined by paperclipped

describe AssetImporter do

  describe "importing assests from a folder" do

    it "should create an Asset for each file in the directory" do
      pending
      files = [
        mock(Pathname, :relative_path_from => 'file1')
      ]
      Pathname.stub!(:new).and_return(mock(Pathanme, :children => files))
    end

    it "should rewrite urls, passing an asset mapping" do
      pending
    end

  end

  describe "rewriting asset urls in content" do

    before do
      @part = PagePart.new(:content => '')
      @part.stub!(:save!)
      @asset = mock_model(Asset, :caption => nil, :title => 'MyAsset', :update_attributes => nil)
      PagePart.stub!(:find_each).and_yield(@part)
    end

    # First element is content path, second is actual path
    test_cases = [
      ['/assets/backgrounds/beach-house-inn.jpg',      '/assets/backgrounds/beach-house-inn.jpg'  ],
      ['/assets/venues/beach-house-inn.jpg',           '/assets/venues/beach-house-inn.jpg'       ],
      ['/assets/images/left_pane_bg.jpg',              '/assets/images/left_pane_bg.jpg'          ],
      ['/assets/reservations/beach%20house%20inn.jpg', '/assets/reservations/beach house inn.jpg' ],
      ['/assets/images/blank.gif',                     '/assets/images/blank.gif'                 ],
      ['/assets/flash/flashaccordion2.swf',            '/assets/flash/flashaccordion2.swf'        ],
      ['../../../assets/Correlation.jpeg',             '/assets/Correlation.jpeg'                 ],
      ['../assets/LolCat.gif',                         '/assets/LolCat.gif'                       ],
    ]

    test_cases.each do |path, realpath|

      it "should rewrite '#{path}' in CSS" do
        @part.content = "background-image: url(#{path});"
        asset_mapping = {realpath.sub(/^\//, '') => @asset}
        new_path = "/new#{realpath}"
        @asset.stub!(:url).and_return(new_path)
        AssetImporter.rewrite_urls(asset_mapping)
        @part.content.should == "background-image: url(#{new_path});"
      end

      it "should rewrite '#{path}' in Flash parameters" do
        @part.content = %Q{<param name="movie" value="#{path}" />}
        asset_mapping = {realpath.sub(/^\//, '') => @asset}
        new_path = "/new#{realpath}"
        @asset.stub!(:url).and_return(new_path)
        AssetImporter.rewrite_urls(asset_mapping)
        @part.content.should == %Q{<param name="movie" value="#{new_path}" />}
      end

      it "should rewrite '#{path}' in image tags" do
        @part.content = %Q{<img alt="The Beach House Inn - New England Maine" src="#{path}" />}
        asset_mapping = {realpath.sub(/^\//, '') => @asset}
        new_path = "/new#{realpath}"
        @asset.stub!(:url).and_return(new_path)
        AssetImporter.rewrite_urls(asset_mapping)
        @part.content.should == %Q{<img alt="The Beach House Inn - New England Maine" src="#{new_path}" />}
      end

      it "should rewrite '#{path}' in mailer tags" do
        @part.content = %Q{<r:mailer:image src="#{path}" class="submit" />}
        asset_mapping = {realpath.sub(/^\//, '') => @asset}
        new_path = "/new#{realpath}"
        @asset.stub!(:url).and_return(new_path)
        AssetImporter.rewrite_urls(asset_mapping)
        @part.content.should == %Q{<r:mailer:image src="#{new_path}" class="submit" />}
      end

      it "should rewrite '#{path}' in javascript" do
        @part.content = %Q{IEPNGFix.blankImg = '#{path}';}
        asset_mapping = {realpath.sub(/^\//, '') => @asset}
        new_path = "/new#{realpath}"
        @asset.stub!(:url).and_return(new_path)
        AssetImporter.rewrite_urls(asset_mapping)
        @part.content.should == %Q{IEPNGFix.blankImg = '#{new_path}';}
      end

      it "should rewrite bare path '#{path}' with trailing whitespace" do
        @part.content = path + ' '
        asset_mapping = {realpath.sub(/^\//, '') => @asset}
        new_path = "/new#{realpath}"
        @asset.stub!(:url).and_return(new_path)
        AssetImporter.rewrite_urls(asset_mapping)
        @part.content.should == new_path + ' '
      end


    end

    [PagePart, Snippet, Layout].each do |clazz|
      it "should process all #{clazz.name}s" do
        resource = clazz.new(:content => '')
        resource.stub!(:save!)
        clazz.should_receive(:find_each).and_yield(resource)
        AssetImporter.rewrite_urls({})
      end
    end

    it "should save the record" do
      @part.should_receive(:save!)
      AssetImporter.rewrite_urls({})
    end

    it "should flag that the content will change" do
      @part.should_receive(:content_will_change!)
      AssetImporter.rewrite_urls({})
    end

    it "should handle assets with the same name in different directories" do
      @part.content = "/assets/venues/beach-house-inn.jpg\n/assets/backgrounds/beach-house-inn.jpg"
      asset_mapping = {
        'assets/backgrounds/beach-house-inn.jpg' => mock_model(Asset, :url => 'asset1'),
        'assets/venues/beach-house-inn.jpg' => mock_model(Asset, :url => 'asset2')
      }
      AssetImporter.rewrite_urls(asset_mapping)
      @part.content.should == "asset2\nasset1"
    end

  end

end