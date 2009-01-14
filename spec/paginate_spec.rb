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
    TestBuild.paginate(1, 1, :keys => 'revision').length.should == 1
  end

  it "fetches a first page with length 1 with keys array" do
    TestBuild.paginate(1, 1, :keys => ['time', 'revision']).length.should == 1
  end
end

describe CouchPotato::Persistence::Pagination, 'instantiates objects' do
  before(:each) do
    CouchPotato::Persistence.Db.delete!
    @hash_id = TestBuild.db.save({:time => '2008-01-02', :revision => "1000"})
    @object_id = TestBuild.create!({:time => '2008-01-01', :revision => "1001"})
  end
  
  it "of the saved class" do
    TestBuild.paginate(1, 1, :keys => "time")
  end
end

describe CouchPotato::Persistence::Pagination, 'helper methods' do
  before(:each) do
    CouchPotato::Persistence.Db.delete!
    TestBuild.create!({:state => 'success', :time => '2008-01-01', :revision => "1000"})
    TestBuild.create!({:state => 'fail',    :time => '2008-01-02', :revision => "1001"})
    TestBuild.create!({:state => 'success', :time => '2008-01-03', :revision => "1002"})
  end

  it "paginate_map_function" do
    keys = "state"
    TestBuild.paginate_map_function(keys, String).should == "function(doc) {
              if(doc.ruby_class == 'String')
                emit([doc.state, doc._id], null);
           }"
  end

  it "can use find_page_ids_ordered_by to get ids of page docs" do
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
