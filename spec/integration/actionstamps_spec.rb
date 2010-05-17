require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'


return unless HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES

describe "DataMapper::Actionstamps" do 
  
  describe "Default behaviours" do 
    
    before(:all) do 
      class User 
        include DataMapper::Resource
        property :id, Serial
        property :name, String
        
        provides_actionstamps
      end
      
      class Article 
        include DataMapper::Resource 
        property :id, Serial 
        property :title, String
        
        actionstamps #:by, User 
      end
      
      DataMapper.auto_migrate!
    end
    
    before(:each) do 
      @user = User.create(:name => "Joe", :id => 99)
      # User.current_user = @user
    end
    
    after do 
      User.all.destroy!
      Article.all.destroy!
    end
    
    describe "Provider Model" do 
      
      describe "#self.actionstamps_class" do 
        
        it "should return the constant of the Actionstamps provider class" do 
          User.actionstamps_class.should == User
          
          class Donkey
            include DataMapper::Resource
            property :id, Serial
            property :name, String
            
            provides_actionstamps
          end
          Donkey.actionstamps_class.should == Donkey
        end
        
      end #/ #self.actionstamps_class
      
      describe "#self.current_user=(user)" do 
        
        it "should respond to :current_user=" do 
          User.should respond_to(:current_user=)
        end
        
        it "should allow setting a new user" do 
          lambda { 
            User.current_user = User.create(:id => 77, :name => "Adam")
          }.should_not raise_error(Exception)
        end
        
      end #/ #self.current_user=(user)
      
      
      describe "#self.current_user" do 
        
        it "should respond to :current_user" do 
          User.should respond_to(:current_user)
        end
        
        it "should return the currently assigned User" do 
          User.current_user.id.should == 77
        end
        
      end #/ #self.current_user
      
    end #/ Provider Model
    
    describe "Receiver Model" do 
      
      describe "when there is NO current_user" do 
        
        before(:each) do 
          User.current_user = nil
        end
        
        it "should not set the created_by" do 
          User.current_user.should == nil
          a = Article.create(:title => "This also works")
          a.created_by.should == nil
          a.updated_by.should == nil
        end
        
        it "should not set the updated_by" do 
          User.current_user.should == nil
          a = Article.create(:title => "This also works")
          a.updated_by.should == nil
        end
        
        it "should set :updated_by and NOT set :created_by when touched" do 
          User.current_user.should == nil  # sanity
          a = Article.create(:title => "Absolutely Amazing, it all works" )
          
          a.touch
          
          a.updated_by.should == nil
          a.created_by.should == nil
        end
        
      end #/ when there is NO current_user
      
      describe "when there is a current_user" do 
        
        before(:each) do 
          User.current_user = @user
        end
        
        it "should NOT set if :created_by is already set" do 
          User.current_user.id.should == 99  # sanity
          a = Article.new(:title => "Hell, this works too" )
          a.created_by = 5
          a.save
          a.created_by.should == 5
          a.created_by.should be_a_kind_of(Integer)
        end
        
        it "should set :created_by on creation" do 
          User.current_user.id.should == 99  # sanity
          a = Article.new(:title => "Hell, this works as well!" )
          a.created_by.should == nil
          a.save
          a.created_by.should be_a_kind_of(Integer)
          a.created_by.should == User.current_user.id
        end
        
        it "should NOT alter :created_by on model updates" do 
          User.current_user.id.should == 99  # sanity
          a = Article.new(:title => "Even this works" )
          a.created_by.should == nil
          a.save
          a.created_by.should be_a_kind_of(Integer)
          a.created_by.should == User.current_user.id
          
          u = User.create(:name => "Eve", :id => 88)
          User.current_user = u
          a.title = "Updating things works as well"
          a.save
          a.created_by.should_not == User.current_user.id
          a.updated_by.should == User.current_user.id
        end
        
        it "should set :updated_by on creation and on update" do 
          User.current_user.id.should == 99  # sanity
          a = Article.new(:title => "This is just great, it all works" )
          a.updated_by.should == nil
          a.save
          a.updated_by.should be_a_kind_of(Integer)
          a.updated_by.should == User.current_user.id
          
          u = User.create(:name => "Eve", :id => 88)
          User.current_user = u
          a.title = "Updating things works as well"
          a.save
          a.updated_by.should == User.current_user.id
          a.updated_by.should_not == @user.id
        end
        
        it "should set :updated_by and NOT set :created_by when touched" do 
          User.current_user.id.should == 99  # sanity
          a = Article.create(:title => "Absolutely Amazing, it all works" )
          a.created_by.should be_a_kind_of(Integer)
          a.created_by.should == User.current_user.id
          a.updated_by.should be_a_kind_of(Integer)
          a.updated_by.should == User.current_user.id
          
          User.current_user = User.create(:name => "Eve", :id => 88)
          User.current_user.id.should == 88
          
          a.touch
          
          a.updated_by.should == User.current_user.id
          a.created_by.should_not == User.current_user.id
          a.created_by.should == @user.id
        end
        
      end #/ when there is a current_user
      
    end #/ Receiver Model
    
  end #/ Default behaviours
  
  describe "Error Handling" do 
    
    describe "Provider declarations" do 
      
      it "should raise an ArgumentError when passed an arg" do 
        lambda { 
          class Client
            include DataMapper::Resource 
            property :id, Serial 
            property :name, String
            
            provides_actionstamps :some_value
            
            # actionstamps :by, User
          end
          
        }.should raise_error(ArgumentError)
      end
      
    end #/ Provider declarations
    
    describe "Receiver declarations" do 
      
      it "should raise an ArgumentError when passed a Hash as the 1st arg" do 
        lambda { 
          class Post
            include DataMapper::Resource 
            property :id, Serial 
            property :title, String
            
            actionstamps :model => :user 
          end
          
        }.should raise_error(ArgumentError)
      end
      
      it "should raise an ArgumentError when passed a Hash as the 2nd args" do 
        lambda { 
          class Post
            include DataMapper::Resource 
            property :id, Serial 
            property :title, String
            
            actionstamps :by, :model => :user 
          end
        }.should raise_error(ArgumentError)
      end
      
      it "should raise an ArgumentError when passed a Symbol as the 2nd args" do 
        lambda { 
          class Post
            include DataMapper::Resource 
            property :id, Serial 
            property :title, String
            
            actionstamps :by, :user 
          end
        }.should raise_error(ArgumentError)
      end
      
      it "should raise an ArgumentError when passed a String as the 2nd args" do 
        lambda { 
          class Post
            include DataMapper::Resource 
            property :id, Serial 
            property :title, String
            
            actionstamps :by, "User" 
          end
        }.should raise_error(ArgumentError)
      end
      
      it "should raise an ArgumentError when passed a non-existant model as the 2nd args" do 
        lambda { 
          class Post
            include DataMapper::Resource 
            property :id, Serial 
            property :title, String
            
            actionstamps :by, ::DoesNotExist
          end
        }.should raise_error(NameError)
      end
      
      it "should raise an ArgumentError when declaring a property by the same name" do 
        lambda { 
          class Post
            include DataMapper::Resource 
            property :id, Serial 
            property :title, String
            
            property :created_by_id, Integer
            
            actionstamps :by_id, ::User
          end
        }.should raise_error(ArgumentError)
      end
      
    end #/ Receiver declarations
    
  end #/ Error Handling
  
  describe "Associations" do 
    
    describe "when using :created_by_id" do 
      
      before(:each) do 
        class Author
          include DataMapper::Resource
          property :id, Serial
          property :name, String
          
          provides_actionstamps
          
          has n, :articles, 'Article', :parent_key => [:id], :child_key => [:created_by_id] 
          has n, :authored_articles, 'Article', :parent_key => [:id], :child_key => [:created_by_id] 
          has n, :updated_articles, 'Article', :parent_key => [:id], :child_key => [:updated_by_id] 
        end
        
        class Article 
          include DataMapper::Resource
          property :id, Serial
          property :title, String
          
          actionstamps :by_id, Author
          
          belongs_to :author, 'Author', :parent_key => [:id], :child_key => [:created_by_id]
          belongs_to :updater, 'Author', :parent_key => [:id], :child_key => [:updated_by_id]
        end
        
        DataMapper.auto_migrate!
        
        @author_joe = Author.create(:id => 22, :name => "Joe")
        @author_jane = Author.create(:id => 33, :name => "Jane")
        
        Author.current_author = @author_joe
        
        @article1 = Article.create(:title => "Article 1")
        @article2 = Article.create(:title => "Article 2")
        @article3 = Article.create(:title => "Article 3")
        
        Author.current_author = @author_jane      
        @article4 = Article.create(:title => "Article 4")
        @article5 = Article.create(:title => "Article 5")
        @article6 = Article.create(:title => "Article 6")
        
        # update
        @article3.title = "Article 3 updated"  # set updater to Jane
        @article3.save
        
      end
      
      describe "Author" do 
        
        describe "has n :authored_articles" do 
          
          it "should respond to :authored_articles" do 
            @author_joe.should respond_to(:authored_articles)
          end
          
          it "should return all the articles created by the author" do 
            @author_joe.authored_articles.map(&:id).should == [1,2,3]
            @author_jane.authored_articles.map(&:id).should == [4,5,6]
          end
          
        end #/ has n :authored_articles
        
        describe "has n :updated_articles" do 
          
          it "should respond to :updated_articles" do 
            @author_joe.should respond_to(:updated_articles)
          end
          
          it "should return all the articles updated by author" do 
            @author_joe.updated_articles.map(&:id).should == [1,2]
            @author_jane.updated_articles.map(&:id).should == [3,4,5,6]
          end
          
        end #/ has n :updated_articles
        
        describe "has n :articles" do 
          
          it "should respond to :articles" do 
            @author_joe.should respond_to(:articles)
          end
          
          it "should return all the articles created by the author" do 
            @author_joe.articles.map(&:id).should == [1,2,3]
            @author_jane.articles.map(&:id).should == [4,5,6]
          end
          
        end #/ has n :articles
        
      end #/ Author
      
      describe "Article" do 
        
        describe "belongs_to :author" do 
          
          it "should respond to :author" do 
            @article1.should respond_to(:author)
          end
          
          it "should return the author" do 
            @article1.author.should == @author_joe
            @article4.author.should == @author_jane
          end
          
        end #/ belongs_to :author
        
        describe "belongs_to :updater" do 
          
          it "should respond to :updater" do 
            @article1.should respond_to(:updater)
          end
          
          it "should return the updater" do 
            @article1.updater.should == @author_joe
            @article3.updater.should == @author_jane
          end
          
        end #/ belongs_to :author
        
      end #/ Article
      
    end #/ when using :created_by_id 
    
    describe "when using :created_by" do 
      
      before(:each) do 
        class Author
          include DataMapper::Resource
          property :id, Serial
          property :name, String
          
          provides_actionstamps
          
          has n, :articles, 'Article', :parent_key => [:id], :child_key => [:created_by] 
          has n, :authored_articles, 'Article', :parent_key => [:id], :child_key => [:created_by] 
          has n, :updated_articles, 'Article', :parent_key => [:id], :child_key => [:updated_by] 
        end
        
        class Article 
          include DataMapper::Resource
          property :id, Serial
          property :title, String
          
          actionstamps :by, Author
          
          belongs_to :author, 'Author', :parent_key => [:id], :child_key => [:created_by]
          belongs_to :updater, 'Author', :parent_key => [:id], :child_key => [:updated_by]
        end
        
        DataMapper.auto_migrate!
        
        @author_joe = Author.create(:id => 22, :name => "Joe")
        @author_jane = Author.create(:id => 33, :name => "Jane")
        
        Author.current_author = @author_joe
        
        @article1 = Article.create(:title => "Article 1")
        @article2 = Article.create(:title => "Article 2")
        @article3 = Article.create(:title => "Article 3")
        
        Author.current_author = @author_jane      
        @article4 = Article.create(:title => "Article 4")
        @article5 = Article.create(:title => "Article 5")
        @article6 = Article.create(:title => "Article 6")
        
        # update
        @article3.title = "Article 3 updated"  # set updater to Jane
        @article3.save
        
      end
      
      describe "Author" do 
        
        describe "has n :authored_articles" do 
          
          it "should respond to :authored_articles" do 
            @author_joe.should respond_to(:authored_articles)
          end
          
          it "should return all the articles created by the author" do 
            @author_joe.authored_articles.map(&:id).should == [1,2,3]
            @author_jane.authored_articles.map(&:id).should == [4,5,6]
          end
          
        end #/ has n :authored_articles
        
        describe "has n :updated_articles" do 
          
          it "should respond to :updated_articles" do 
            @author_joe.should respond_to(:updated_articles)
          end
          
          it "should return all the articles updated by author" do 
            @author_joe.updated_articles.map(&:id).should == [1,2]
            @author_jane.updated_articles.map(&:id).should == [3,4,5,6]
          end
          
        end #/ has n :updated_articles
        
        describe "has n :articles" do 
          
          it "should respond to :articles" do 
            @author_joe.should respond_to(:articles)
          end
          
          it "should return all the articles created by the author" do 
            @author_joe.articles.map(&:id).should == [1,2,3]
            @author_jane.articles.map(&:id).should == [4,5,6]
          end
          
        end #/ has n :articles
        
      end #/ Author
      
      describe "Article" do 
        
        describe "belongs_to :author" do 
          
          it "should respond to :author" do 
            @article1.should respond_to(:author)
          end
          
          it "should return the author" do 
            @article1.author.should == @author_joe
            @article4.author.should == @author_jane
          end
          
        end #/ belongs_to :author
        
        describe "belongs_to :updater" do 
          
          it "should respond to :updater" do 
            @article1.should respond_to(:updater)
          end
          
          it "should return the updater" do 
            @article1.updater.should == @author_joe
            @article3.updater.should == @author_jane
          end
          
        end #/ belongs_to :author
        
      end #/ Article
      
    end #/ when using :created_by 
    
  end #/ Associations
  
  
  describe "Client Model" do 
    
    before(:each) do 
      class Client
        include DataMapper::Resource
        property :id, Serial
        property :name, String
        
        provides_actionstamps
      end
      
    end
    %w(current_client current_client=).each do |m|
      it "should respond to :#{m}" do 
        Client.should respond_to(m.to_sym)
      end
    end
    
  end #/ Client Model
  
  
end #/ DataMapper::Actionstamps
