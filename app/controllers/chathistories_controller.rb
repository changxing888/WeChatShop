class ChathistoriesController < ApplicationController
  
  def index
    @chathistories = Chathistory.all
  end
end
