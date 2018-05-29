require 'slack-ruby-bot'
require 'rubygems'
require 'yaml'
require 'set'

#### Initialize
$:.unshift(File.join File.dirname(__FILE__), '..', 'lib')
require './bandit/lib/bandit'

CONFIG = YAML.load_file File.join(File.dirname(__FILE__), "config.yml")
###############

class PongBot < SlackRubyBot::Bot
  @userStatus = {}
  @userAlternative = {}

  Bandit.setup do |config|
    config.player = "round_robin"
    config.storage = 'memory'
  end
  
  @storage = Bandit.storage

  def self.new_experiment
    Bandit::Experiment.create(:click_test) { |exp|
      exp.alternatives = [ "nice!", "not bad", "I do not know" ]
      exp.title = "Click Test"
      exp.description = "A test of clicks on purchase page with varying link sizes."
    }
  end

  @myExp = new_experiment

  def self.registerUser(client, data)
    if @userStatus[data.user] == nil
      @userStatus[data.user] = 0
      client.say(text:"You are now registered!", channel: data.channel)
    end
  end
 



  command 'hi' do |client, data, match|
    msg = 'Hi <@' + data.user + '>! Here are a list of questions that I can handle.' + "\n\n" + 
    ' - How old are you?' + "\n" + 
    ' - How is the weather in Daejeon?' + "\n"

    registerUser(client, data)
    client.say(text: msg, channel: data.channel)
  end




  match /^How old are you?/ do |client, data, match|
    client.say(text: "Why do you ask me?", channel: data.channel)
    @userStatus[data.user] = 0
  end




  command 'yes' do |client, data, match| 
    if @userStatus[data.user] == 1
      @userStatus[data.user] = 0
      msg = 'cool! Thank you for your opinion!' 

      alt = @userAlternative[data.user]

      @myExp.convert!(alt)

      @userAlternative.except(data.user)
    else
      @userStatus[data.user] = 0
      msg = 'Please start from a question.' 
    end

    client.say(text: msg, channel: data.channel)
  end




  command 'no' do |client, data, match| 
    if @userStatus[data.user] == 1
      @userStatus[data.user] = 2
      msg = 'What do you think is an appropriate response?' 
    else
      @userStatus[data.user] = 0
      msg = 'Please start from a question.' 
    end

    client.say(text: msg, channel: data.channel)
  end




  match /^How is the weather in (?<location>\w*)\?$/ do |client, data, match|
    alt = @myExp.choose

    msg = '*' + alt + '*' + "\n\n" + 
 
    "Do you think it is an approproate answer? (yes/no)"

    @userStatus[data.user] = 1
    @userAlternative[data.user] = alt

    client.say(text: msg, channel: data.channel)
  end

  command 'ping' do |client, data, match|
    client.say(text: 'pong ', channel: data.channel)

	@myExp.alternatives.each { |alt|
	  conversionRate = @myExp.conversion_rate(alt)
	  participantCount = @myExp.participant_count(alt)
      msg = alt + "\t" + conversionRate.to_s + "\t" + participantCount.to_s
      client.say(text: msg, channel: data.channel)
	}

  end




  match /.*/ do |client, data, matchs|
    if @userStatus[data.user] == 2 
      @userStatus[data.user] = 0
      msg = 'cool! Thank you for your opinion!'
      @myExp.alternatives << data.text

    else
      @userStatus[data.user] = 0
      msg = 'Sorry, I do not understand this command, <@' + data.user + '>' 
    end

    client.say(text: msg, channel: data.channel)
  end
end

PongBot.run

