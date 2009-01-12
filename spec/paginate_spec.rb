require File.dirname(__FILE__) + '/spec_helper'

class TestBuild
  include CouchPotato::Persistence

  property :state
  property :time
  property :revision
end

describe CouchPotato::Persistence::Pagination, 'paginate' do
  before(:each) do
    CouchPotato::Persistence.Db.delete!
    TestBuild.db.save({:state => 'success', :time => '2008-01-01', :revision => "1000"})
    TestBuild.db.save({:state => 'fail',    :time => '2008-01-02', :revision => "1001"})
    TestBuild.db.save({:state => 'success', :time => '2008-01-03', :revision => "1002"})
  end

  it "fetches a first page with length 1" do
    TestBuild.paginate(1, 1, :keys => 'revision').length.should == 1
  end

  it "fetches a first page with length 1 with keys array" do
    TestBuild.paginate(1, 1, :keys => ['time', 'revision']).length.should == 1
  end
end

describe CouchPotato::Persistence::Pagination, 'helper methods' do
  before(:each) do
    CouchPotato::Persistence.Db.delete!
    TestBuild.db.save({:state => 'success', :time => '2008-01-01', :revision => "1000"})
    TestBuild.db.save({:state => 'fail',    :time => '2008-01-02', :revision => "1001"})
    TestBuild.db.save({:state => 'success', :time => '2008-01-03', :revision => "1002"})
  end

  it "paginate_map_funcition" do
    keys = "state"
    TestBuild.paginate_map_function(keys).should == "function(doc) {
              emit([doc.state, doc._id], null);
           }"
  end

  it "can use find_page_ids_ordered_by to get ids of page docs" do
    ids, total = TestBuild.find_page_ids_ordered_by(1, 2, :time, true)
    ids.length.should == 2
    total.should == 3
  end

  it "find_page_ids_ordered_by can use more than one oreder key" do
    ids, total = TestBuild.find_page_ids_ordered_by(1, 2, [:time, :_id], true)
    ids.length.should == 2
    total.should == 3
  end
end
