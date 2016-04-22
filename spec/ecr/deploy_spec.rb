require 'spec_helper'

require "ecr_deploy/version"

describe EcrDeploy do
  it 'has a version number' do
    expect(EcrDeploy::VERSION).not_to be nil
  end
end
