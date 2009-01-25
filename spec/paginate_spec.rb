require File.dirname(__FILE__) + '/spec_helper'

class TestBuild
  include CouchPotato::Persistence

  property :time
  property :revision
  property :state
end

describe CouchPotato::Persistence::Pagination, 'paginate' do
  before(:each) do
    CouchPotato::Persistence.Db.delete!
    TestBuild.create!({:state => 'success', :time => '2008-01-01', :revision => "1000"})
    TestBuild.create!({:state => 'fail',    :time => '2008-01-02', :revision => "1001"})
    TestBuild.create!({:state => 'success', :time => '2008-01-03', :revision => "1002"})
  end

  it "fetches a first page with length 1" do
    TestBuild.paginate(1, 1, :order => 'revision').length.should == 1
  end

  it "fetches a first page with length 1 with keys array" do
    TestBuild.paginate(1, 1, :order => ['time', 'revision']).length.should == 1
  end

  it "fetches a second page with length 2, but finds only 1" do
    TestBuild.paginate(2, 2, :order => ['time', 'revision']).length.should == 1
  end

  it "fetches a first page with length 2" do
    TestBuild.paginate(1, 2, :order => ['time', 'revision']).length.should == 2
  end

  it "orders ascending by default" do
    TestBuild.paginate(1, 3, :order => :revision).map{|build| build.revision }.should == ["1000", "1001", "1002"] 
  end

  it "orders descending when option :descending is true" do
    TestBuild.paginate(1, 3, :order => :revision, :descending => true).map{|build| build.revision }.should == ["1002", "1001", "1000"] 
  end
end

describe CouchPotato::Persistence::Pagination, 'instantiates objects' do
  before(:each) do
    CouchPotato::Persistence.Db.delete!
    @hash_id = TestBuild.db.save({:time => '2008-01-02', :revision => "1000"})
    @object_id = TestBuild.create!({:time => '2008-01-01', :revision => "1001"})
  end

  describe "with default instantiation class" do
    before do
      @result = TestBuild.paginate(1, 1, :order => 'time')
    end
    
    it "of the saved class, but not the other" do
      @result.size.should == 1
    end
    
    it "of the saved class, but not the other" do
      @result.first.class.should == TestBuild
    end
  end

  describe "using :class option explicitly" do
    before do
      @result = TestBuild.paginate(1, 2, :order => 'time', :class => TestBuild)
    end
    
    it "finds the same one docs" do
      @result.size.should == 1
    end
  end

  describe "using :class option of nil" do
    before do
      @result = TestBuild.paginate(1, 2, :order => 'time', :class => nil)
    end
    
    it "finds both type-tagged and untagged docs" do
      @result.map{|row| row.class}.should == [Hash, Hash]
      @result.size.should == 2
    end
  end
end

describe TestBuild, "instantiate?" do
  it "is true if :class option is a class object" do
    TestBuild.instantiate?(:class => Object).should be_true
  end

  it "is true if :class option is absent, falling back to default true (using 'self' as value)" do
    TestBuild.instantiate?({}).should be_true
  end

  it "is false if :class option present and of value nil" do
    TestBuild.instantiate?(:class => nil).should be_false
  end

  it "is false if :class option present and of value :none" do
    TestBuild.instantiate?(:class => :none).should be_false
  end
end

describe CouchPotato::Persistence::Pagination, 'helper methods' do
  before(:each) do
    CouchPotato::Persistence.Db.delete!
    TestBuild.create!({:state => 'success', :time => '2008-01-01', :revision => "1000"})
    TestBuild.create!({:state => 'fail',    :time => '2008-01-02', :revision => "1001"})
    TestBuild.create!({:state => 'success', :time => '2008-01-03', :revision => "1002"})
  end

  describe "paginate_map_function" do
    it "main success case" do
      order = :state
      TestBuild.paginate_map_function(order, String).should == "function(doc) {
              if(doc.ruby_class == 'String') emit([doc.state, doc._id], null);
           }"
    end

    it "with multiple order properties" do
      order = [:state, :name]
      TestBuild.paginate_map_function(order, String).should == "function(doc) {
              if(doc.ruby_class == 'String') emit([doc.state, doc.name, doc._id], null);
           }"
    end

    it "without class predicate" do
      order = [:state, :name]
      TestBuild.paginate_map_function(order, nil).should == "function(doc) {
               emit([doc.state, doc.name, doc._id], null);
           }"
    end
  end

  describe "find_page_ids_ordered_by" do
    it "can get ids of page docs" do
      ids, total = TestBuild.find_page_ids_ordered_by(1, 2, :time, true, TestBuild)
      ids.length.should == 2
      total.should == 3
    end

    it "find_page_ids_ordered_by can use more than one oreder key" do
      ids, total = TestBuild.find_page_ids_ordered_by(1, 2, [:time, :_id], true, TestBuild)
      ids.length.should == 2
      total.should == 3
    end
  end

  describe "type_predicate" do
    it "generates if statement" do
      TestBuild.type_predicate('String', 'ruby_class').should == "if(doc.ruby_class == 'String')"
    end

    it "generates empty string if clazz argument is nil" do
      TestBuild.type_predicate(nil, 'ruby_class').should == ""
    end
  end
end
