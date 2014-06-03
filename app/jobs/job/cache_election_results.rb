module Job
  class CacheElectionResults < Base
    @priority = :low


    GROUP = "election-june2014"
    NOTE = "Percentage; Number Only (no % symbol)"

    CONTEST_XML   = "/web/scprv4/sosxml/X14GP510v7.xml"
    REPORTING_XML = "/web/scprv4/sosxml/X14GP530v7.xml"
    PROP_XML      = "/web/scprv4/sosxml/X14GP510_1900v7.xml"

    RACES = {
      "Governor - Statewide Results"                  => "state.governor",

      "Secretary of State - Statewide Results"        => "state.sos",
      "Attorney General - Statewide Results"          => "state.attorney_general",
      "Insurance Commissioner - Statewide Results"    => "state.insurance_commissioner",
      "Lieutenant Governor - Statewide Results"       => "state.lieutenant_gov",
      "Controller - Statewide Results"                => "state.controller",

      "U.S. House of Representatives District 8 - Districtwide Results"  => "house.d8",
      "U.S. House of Representatives District 11 - Districtwide Results" => "house.d11",
      "U.S. House of Representatives District 23 - Districtwide Results" => "house.d23",
      "U.S. House of Representatives District 24 - Districtwide Results" => "house.d24",
      "U.S. House of Representatives District 25 - Districtwide Results" => "house.d25",
      "U.S. House of Representatives District 26 - Districtwide Results" => "house.d26",
      "U.S. House of Representatives District 27 - Districtwide Results" => "house.d27",
      "U.S. House of Representatives District 28 - Districtwide Results" => "house.d28",
      "U.S. House of Representatives District 29 - Districtwide Results" => "house.d29",
      "U.S. House of Representatives District 30 - Districtwide Results" => "house.d30",
      "U.S. House of Representatives District 31 - Districtwide Results" => "house.d31",
      "U.S. House of Representatives District 32 - Districtwide Results" => "house.d32",
      "U.S. House of Representatives District 33 - Districtwide Results" => "house.d33",
      "U.S. House of Representatives District 34 - Districtwide Results" => "house.d34",
      "U.S. House of Representatives District 35 - Districtwide Results" => "house.d35",
      "U.S. House of Representatives District 36 - Districtwide Results" => "house.d36",
      "U.S. House of Representatives District 37 - Districtwide Results" => "house.d37",
      "U.S. House of Representatives District 38 - Districtwide Results" => "house.d38",
      "U.S. House of Representatives District 39 - Districtwide Results" => "house.d39",
      "U.S. House of Representatives District 40 - Districtwide Results" => "house.d40",
      "U.S. House of Representatives District 41 - Districtwide Results" => "house.d41",
      "U.S. House of Representatives District 42 - Districtwide Results" => "house.d42",
      "U.S. House of Representatives District 43 - Districtwide Results" => "house.d43",
      "U.S. House of Representatives District 44 - Districtwide Results" => "house.d44",
      "U.S. House of Representatives District 47 - Districtwide Results" => "house.d47",
      "U.S. House of Representatives District 50 - Districtwide Results" => "house.d50",

      "State Senate District 18 - Districtwide Results" => "state.senate-d18",
      "State Senate District 20 - Districtwide Results" => "state.senate-d20",
      "State Senate District 22 - Districtwide Results" => "state.senate-d22",
      "State Senate District 24 - Districtwide Results" => "state.senate-d24",
      "State Senate District 26 - Districtwide Results" => "state.senate-d26",
      "State Senate District 28 - Districtwide Results" => "state.senate-d28",
      "State Senate District 30 - Districtwide Results" => "state.senate-d30",
      "State Senate District 32 - Districtwide Results" => "state.senate-d32",
      "State Senate District 34 - Districtwide Results" => "state.senate-d34",

      "State Assembly District 33 - Districtwide Results" => "state.assembly-d33",
      "State Assembly District 36 - Districtwide Results" => "state.assembly-d36",
      "State Assembly District 37 - Districtwide Results" => "state.assembly-d37",
      "State Assembly District 38 - Districtwide Results" => "state.assembly-d38",
      "State Assembly District 39 - Districtwide Results" => "state.assembly-d39",
      "State Assembly District 40 - Districtwide Results" => "state.assembly-d40",
      "State Assembly District 41 - Districtwide Results" => "state.assembly-d41",
      "State Assembly District 42 - Districtwide Results" => "state.assembly-d42",
      "State Assembly District 43 - Districtwide Results" => "state.assembly-d43",
      "State Assembly District 44 - Districtwide Results" => "state.assembly-d44",
      "State Assembly District 45 - Districtwide Results" => "state.assembly-d45",
      "State Assembly District 46 - Districtwide Results" => "state.assembly-d46",
      "State Assembly District 47 - Districtwide Results" => "state.assembly-d47",
      "State Assembly District 48 - Districtwide Results" => "state.assembly-d48",
      "State Assembly District 49 - Districtwide Results" => "state.assembly-d49",
      "State Assembly District 50 - Districtwide Results" => "state.assembly-d50",
      "State Assembly District 51 - Districtwide Results" => "state.assembly-d51",
      "State Assembly District 52 - Districtwide Results" => "state.assembly-d52",
      "State Assembly District 53 - Districtwide Results" => "state.assembly-d53",
      "State Assembly District 54 - Districtwide Results" => "state.assembly-d54",
      "State Assembly District 55 - Districtwide Results" => "state.assembly-d55",
      "State Assembly District 56 - Districtwide Results" => "state.assembly-d56",
      "State Assembly District 57 - Districtwide Results" => "state.assembly-d57",
      "State Assembly District 58 - Districtwide Results" => "state.assembly-d58",
      "State Assembly District 59 - Districtwide Results" => "state.assembly-d59",
      "State Assembly District 60 - Districtwide Results" => "state.assembly-d60",
      "State Assembly District 61 - Districtwide Results" => "state.assembly-d61",
      "State Assembly District 62 - Districtwide Results" => "state.assembly-d62",
      "State Assembly District 63 - Districtwide Results" => "state.assembly-d63",
      "State Assembly District 64 - Districtwide Results" => "state.assembly-d64",
      "State Assembly District 66 - Districtwide Results" => "state.assembly-d66",
      "State Assembly District 67 - Districtwide Results" => "state.assembly-d67",
      "State Assembly District 70 - Districtwide Results" => "state.assembly-d70",
      "State Assembly District 71 - Districtwide Results" => "state.assembly-d71",
      "State Assembly District 75 - Districtwide Results" => "state.assembly-d75",

      "Veterans Housing & Homeless Bond Act of 2014"   => "state.prop-41",
      "Public Records. Open Meetings. Reimbursements." => "state.prop-42"
    }

    class << self
      def perform
        job = new
        job.load_data
        job.update_data
      end
    end


    def load_data
      # Only get the races we care about
      @contests = MultiXml.parse(File.read(CONTEST_XML))["EML"]["Count"]["Election"]["Contests"]["Contest"].select do |c|
        RACES.include?(c["ContestIdentifier"]["ContestName"])
      end

      @props = MultiXml.parse(File.read(PROP_XML))["EML"]["Count"]["Election"]["Contests"]["Contest"].select do |c|
        RACES.include?(c["ContestIdentifier"]["ContestName"])
      end

      @reporting_stats = MultiXml.parse(File.read(REPORTING_XML))["EML"]["Statistics"]["Election"]["Contests"]["Contest"]["TotalVotes"]["CountMetric"]
    end


    def update_data
      reporting_key = "percent_reporting"

      # Get rid of the decimal places
      reporting_percentage = @reporting_stats.find { |m| m["Id"] == "PP" }["__content__"].to_i

      if d = DataPoint.where(data_key: reporting_key, group_name: GROUP).first
        d.update_attribute(:data_value, reporting_percentage)
      else
        DataPoint.create(
          :title        => "Percent Precincts Reporting",
          :data_key     => reporting_key,
          :data_value   => reporting_percentage,
          :group_name   => GROUP,
          :notes        => NOTE
        )
      end

      @props.each do |prop|
        prop_name = prop["ContestIdentifier"]["ContestName"]
        prop_key_prefix = RACES[prop_name]

        yes_key = prop_key_prefix + ":yes"
        no_key  = prop_key_prefix + ":no"

        percent_yes = prop["TotalVotes"]["CountMetric"].find { |m| m["Id"] == "PYV" }["__content__"].to_i
        percent_no = prop["TotalVotes"]["CountMetric"].find { |m| m["Id"] == "PNV" }["__content__"].to_i

        # YES
        if d = DataPoint.where(data_key: yes_key, group_name: GROUP).first
          d.update_attribute(:data_value, percent_yes)
        else
          DataPoint.create(
            :title        => prop_name + ": Yes",
            :data_key     => yes_key,
            :data_value   => percent_yes,
            :group_name   => GROUP,
            :notes        => NOTE
          )
        end

        # NO
        if d = DataPoint.where(data_key: no_key, group_name: GROUP).first
          d.update_attribute(:data_value, percent_no)
        else
          DataPoint.create(
            :title        => prop_name + ": No",
            :data_key     => no_key,
            :data_value   => percent_no,
            :group_name   => GROUP,
            :notes        => NOTE
          )
        end
      end


      @contests.each do |contest|
        contest_name = contest["ContestIdentifier"]["ContestName"]
        contest_key_prefix = RACES[contest_name]

        Array.wrap(contest["TotalVotes"]["Selection"]).each do |candidate|
          candidate_name = candidate["Candidate"]["CandidateFullName"]["PersonFullName"]
          candidate_key = contest_key_prefix + ":" + candidate_name.parameterize.underscore
          percent_votes = candidate["CountMetric"]["__content__"].to_i

          if d = DataPoint.where(data_key: candidate_key, group_name: GROUP).first
            d.update_attribute(:data_value, percent_votes)
          else
            DataPoint.create(
              :title        => candidate_name,
              :data_key     => candidate_key,
              :data_value   => percent_votes,
              :group_name   => GROUP,
              :notes        => NOTE
            )
          end
        end
      end
    end
  end
end