require "spec_helper"

describe "crowdfunder sql" do
  before do
    @db = SQLite3::Database.new(':memory:')
    @sql_runner = SQLRunner.new(@db)
  end

  describe "create.sql" do
    before do
      @sql_runner.execute_create_sql
    end

    it "creates a user table with a name field" do
      expect{@db.execute("SELECT name FROM users;")}.to_not raise_exception
    end

    it "creates a user table with an age field" do
      expect{@db.execute("SELECT age FROM users;")}.to_not raise_exception
    end

    it "creates a user table with an id as a primary key" do
      expect(@db.execute("PRAGMA table_info(users);").detect { |arr| arr[-1] == 1 && arr[2] == "INTEGER" }.length).to eq(6)
    end

    it "creates a pledge table with an amount field" do
      expect{@db.execute("SELECT amount FROM pledges;")}.to_not raise_exception
    end

    it "creates a pledge table with a user_id field" do
      expect{@db.execute("SELECT user_id FROM pledges;")}.to_not raise_exception
    end

    it "creates a pledge table with a project_id field" do
      expect{@db.execute("SELECT project_id FROM pledges;")}.to_not raise_exception
    end

    it "creates a pledge table with an id as a primary key" do
      expect(@db.execute("PRAGMA table_info(pledges);").detect { |arr| arr[-1] == 1 && arr[2] == "INTEGER" }.length).to eq(6)
    end

    it "creates a project table with a title field" do
      expect{@db.execute("SELECT title FROM projects;")}.to_not raise_exception
    end

    it "creates a project table with a category field" do
      expect{@db.execute("SELECT category FROM projects;")}.to_not raise_exception
    end

    it "creates a project table with a funding_goal field" do
      expect{@db.execute("SELECT funding_goal FROM projects;")}.to_not raise_exception
    end

    it "creates a project table with a start_date field" do
      expect{@db.execute("SELECT start_date FROM projects;")}.to_not raise_exception
    end

    it "creates a project table with a end_date field" do
      expect{@db.execute("SELECT end_date FROM projects;")}.to_not raise_exception
    end

    it "creates a project table with an id as a primary key" do
      expect(@db.execute("PRAGMA table_info(projects);").detect { |arr| arr[-1] == 1 && arr[2] == "INTEGER" }.length).to eq(6)
    end

  end

  describe "insert.sql" do
    before do
      @sql_runner.execute_create_sql
      @sql_runner.execute_insert_sql
    end

    it "has 20 users" do
      expect(@db.execute("SELECT COUNT(*) FROM users;").flatten[0]).to eq(20)
    end

    it "has 10 projects" do
      expect(@db.execute("SELECT COUNT(*) FROM projects;").flatten[0]).to eq(10)
    end

    it "has 30 pledges" do
      expect(@db.execute("SELECT COUNT(*) FROM pledges;").flatten[0]).to eq(30)
    end

  end

  describe "questions" do
    before do
      @sql_runner.execute_create_sql
      @sql_runner.execute_encoded_data
    end
    after do
      File.open('lib/decoded_data.sql', 'w'){ |f| f.truncate(0) }
    end

    it 'selects the titles of all projects and their pledge amounts' do
      expect(@db.execute("SELECT projects.title, SUM(pledges.amount) FROM projects INNER JOIN pledges ON projects.id = pledges.project_id GROUP BY projects.title;")).to eq([["Animal shelter needs dog food", 210], ["Help me buy a guitar", 98], ["Help save birds of paradise", 170], ["I have bed bugs!", 740], ["I want to teach English in China", 200], ["Iguana needs tail operation", 1035.5], ["My book on SQL", 20], ["The next Harry Potter", 120], ["The next Inna-Gadda-Davida", 342], ["Voldement needs a body", 489]])
    end

    it 'selects the user name, age, and pledge amount for all pledges' do
      expect(@db.execute("SELECT users.name, users.age, SUM(pledges.amount) FROM users INNER JOIN pledges ON users.id = pledges.user_id GROUP BY users.name;")).to eq([["Albus", 113, 470], ["Alex", 33, 20], ["Amanda", 24, 40], ["Bear", 6, 50], ["Ena", 24, 100], ["Finnebar", 17, 70], ["Franz", 100, 90], ["Hermione", 30, 50], ["Iguana", 4, 10], ["Katie", 24, 170], ["Marisa", 24, 24], ["Pacha", 5, 60], ["Rosey", 9, 50], ["Sirius", 36, 19], ["Sophie", 24, 60], ["Squid", 5, 270], ["Swizzle", 4, 12], ["Victoria", 23, 1700], ["Voldemort", 90, 34], ["Whale", 6, 125.5]])
    end

    it 'selects the titles of all projects that have met their funding goal' do
      expect(@db.execute("SELECT projects.title, (projects.funding_goal - SUM(pledges.amount)) FROM projects JOIN pledges ON projects.id = pledges.project_id GROUP BY projects.title HAVING (projects.funding_goal - SUM(pledges.amount)) <= 0;")).to eq([["My book on SQL", 0], ["The next Inna-Gadda-Davida", -142]])
    end

    it 'selects user names and amounts of all pledges then orders them by the amount' do
      expect(@db.execute("SELECT users.name, SUM(pledges.amount) FROM users JOIN pledges ON pledges.user_id = users.id GROUP BY users.name ORDER BY SUM(pledges.amount);")).to eq([["Iguana", 10], ["Swizzle", 12], ["Sirius", 19], ["Alex", 20], ["Marisa", 24], ["Voldemort", 34], ["Amanda", 40], ["Bear", 50], ["Hermione", 50], ["Rosey", 50], ["Pacha", 60], ["Sophie", 60], ["Finnebar", 70], ["Franz", 90], ["Ena", 100], ["Whale", 125.5], ["Katie", 170], ["Squid", 270], ["Albus", 470], ["Victoria", 1700]])
    end

    it 'selects the category names, and pledge amounts of all pledges in the music category' do
      expect(@db.execute("SELECT projects.category, pledges.amount FROM projects JOIN pledges ON pledges.project_id = projects.id WHERE projects.category = 'music';")).to eq([["music", 40], ["music", 24], ["music", 34], ["music", 12], ["music", 40], ["music", 40], ["music", 20], ["music", 230]])
    end

    it 'selects the category name and the sum total of the all its pledges for the book category' do
      expect(@db.execute("SELECT projects.category, SUM(pledges.amount) FROM projects JOIN pledges ON projects.id = pledges.project_id WHERE projects.category = 'books';")).to eq([["books", 140]])
    end
  end
end
