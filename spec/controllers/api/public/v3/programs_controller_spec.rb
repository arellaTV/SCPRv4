require "spec_helper"

describe Api::Public::V3::ProgramsController do
  request_params = {
    :format => :json
  }

  render_views

  describe "GET show" do
    it "finds the object if it exists" do
      program = create :kpcc_program, slug: 'hello'
      get :show, { id: program.slug }.merge(request_params)
      assigns(:program).should eq program.to_program
      response.should render_template "show"
    end

    it "returns a 404 status if it does not exist" do
      get :show, { id: "nonono" }.merge(request_params)
      response.response_code.should eq 404
      JSON.parse(response.body)["error"]["message"].should eq "Not Found"
    end
  end

  describe "GET index" do
    context "with the air_status parameter" do
      it "only selects programs with the requested air statuses" do
        kpcc_program = create :kpcc_program, air_status: "archive"
        external_program = create :external_program, air_status: "online"
        another_program = create :kpcc_program, air_status: "onair"

        get :index, { air_status: "archive,online" }.merge(request_params)
        assigns(:programs).should eq [kpcc_program, external_program].map(&:to_program)
      end
    end

    context "without the air_status parameter" do
      it "returns all KPCC programs and Other Programs combined" do
        kpcc_program       = create :kpcc_program
        external_program   = create :external_program

        get :index, request_params
        assigns(:programs).should eq [kpcc_program, external_program].map(&:to_program)
      end
    end
  end

  describe "GET histogram", :indexing do
    program, parsed_response = nil
    before :each do
      program = create :kpcc_program, slug: 'hello'
      create :show_episode, air_date: Date.parse("2015-02-15"), show: program
      get :histogram, { id: program.slug }.merge(request_params)
      parsed_response = JSON.parse(response.body)["histogram"]
    end
    it "renders a json histogram" do
      assigns(:program).should eq program.to_program
      response.should render_template "histogram"
      parsed_response["years"][0]["episode_count"].should eq 1
      parsed_response["years"][0]["year"].should eq 2015
      parsed_response["years"][0]["months"].count.should eq 1
    end
    it "provides a list of years" do
      parsed_response["years"][0]["year"].should eq 2015
    end
    it "provides an episode count for a year" do
      parsed_response["years"][0]["episode_count"].should eq 1
    end
    it "provides a list of months for a year" do
      parsed_response["years"][0]["months"].count.should eq 1
      parsed_response["years"][0]["months"][0]["name"].should eq "February"
    end
    it "provides an episode count for a month" do
      parsed_response["years"][0]["months"][0]["episode_count"].should eq 1
    end
  end

end
