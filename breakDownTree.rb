require "rubygems"
require "active_record"

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => File.expand_path("~/Dropbox/BreakDownTree/db_breakDownTree.sqlite3"),
  :timeout => 5000
)

begin
  ActiveRecord::Migration.create_table :break_down_trees do |t|
    t.column :parent_id  , :int
    t.column :name       , :string, :null => false
    t.column :crct       , :int, :default => 0
    t.column :pnexptime  , :datetime, :default => Time.local(2000)
  end
rescue
end


class BreakDownTree < ActiveRecord::Base
  has_many :children, :class_name => "BreakDownTree", :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "BreakDownTree", :foreign_key => "parent_id"

  def expired?
    self.pnexptime < Time.new
  end

  def finished?
    children.all? { |child| !child.expired? }
  end

  def problem?
    !self.children.empty?
  end

  def reset
    self.crct = 0
    self.pnexptime = Time.new
    self.save
    self
  end

  def incr
    delta = (1 << crct) * 60 * 60
    self.pnexptime = Time.new + rand(2*delta)
  end

  def str_as_element
    self.expired? ? " ? " : " * #{self.name}"
  end

  def pwd
    (self.parent_id ? self.parent.pwd + "::" : "") + self.name + "(#{self.children.size})"
  end

  def test_main
    children = self.children
    expireds = children.select{ |child| child.expired? }

    # put question
    total_size = children.size
    puts "#{self.pwd}:: name <#{ expireds.size } out of #{ total_size }> elements"
    children.each { |child| puts child.str_as_element }

    # query answer
    puts "(press RET to continue, 'q' to exit)"
    if gets.chomp == "q"
      $b = self
      raise
    end

    # for each child, query if got that right
    puts 
    expireds.each { |expired|
      puts " ? : #{expired.name}"
      puts "(got right? y/n/q)"
      while true
        ans = gets.chomp
        if ans == "y"
          expired.crct += 1
          expired.incr
          break
        elsif ans == "n"
          expired.crct = 0
          break
        elsif ans == "q"
          $b = expired
          raise
        end
      end
      expired.save
    }
  end

  def test(hint = false)
    # whether to test this problem
    return unless self.problem?

    test_main unless self.finished?

    # if you finish this layer, than lets check children
    if self.finished?
      children.each { |child|
        child.test
      }
    end
  end

end


def test
  seeds = BreakDownTree.all.select { |bdt| bdt.parent_id == nil }
  seeds.each { |bdt| bdt.test }
end


def make(name)
  $b = BreakDownTree.new(:name => name)
  $b.save
  $b
end

def bdts
  BreakDownTree.all
end

def bdt_id(id)
  $b = BreakDownTree.find(id)
end

def reset_all
  bdts.each { |bdt| bdt.reset }
  nil
end


def search(word = nil)
  unless word
    print "Word to search:: "
    word = gets.chomp
  end
  result = BreakDownTree.find(:all, :conditions => ["name like ?", '%' + word + '%'])
  $b = result[0] if result.size == 1
  $search = result
  result
end

def child(name)
  b = $b
  make(name)
  b.children << $b
  created = $b
  $b = b
  created
end

def pwd
  $b.pwd
end

def parents
  BreakDownTree.all.select { |t| t.parent_id == nil }
end


$b = BreakDownTree.all.select { |t| t.parent_id == nil}[0]


