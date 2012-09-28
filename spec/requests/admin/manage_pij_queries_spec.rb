require "spec_helper"

describe PijQuery do
  let(:valid_record) { build :pij_query }
  let(:updated_record) { build :pij_query }
  let(:invalid_record) { build :pij_query, headline: "" }
  
  it_behaves_like "managed resource"
  it_behaves_like "versioned model"
  it_behaves_like "front-end routes request"
end
