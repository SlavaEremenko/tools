# frozen_string_literal: true

class FabricatorAuditor
  FabricatorInfo = OptStruct.new(:path, :name, :usage_count)

  FABRICATORS_DIR = Rails.root.join("test/fabricators")
  TEST_DIR = Rails.root.join("test")

  FABRICATOR_REGEX = /Fabricator\(\s*:(\w+)\,?\s*/.freeze

  def perform
    puts "Fabricators with no usage:"

    fabricators_by_file.each do |fabricator_file_path, fabricators|
      fabricators_with_no_usage = fabricators.select do |fabricator_info|
        fabricator_info.usage_count.zero?
      end

      next unless fabricators_with_no_usage.any?

      puts "   #{fabricator_file_path}"

      fabricators_with_no_usage.each do |fabricator_info|
        puts "      #{fabricator_info.name}"
      end

      puts
    end

    true
  end

  def self.perform
    new.perform
  end

  private

  # Scan fabricator files for fabricator definitions
  def fabricators_by_file
    @fabricators_by_file ||= fabricator_file_paths.map do |path|
      [path, fabricators_in_a_file(path)]
    end
  end

  def fabricator_file_paths
    Dir[FABRICATORS_DIR.join("**", "*.rb")]
  end

  def fabricators_in_a_file(path)
    File.read(path).scan(FABRICATOR_REGEX).flatten.map do |fabricator_name|
      FabricatorInfo.new(
        path: path,
        name: fabricator_name,
        usage_count: count_fabricator_usage(fabricator_name, fabricate_regex(fabricator_name)),
      )
    end
  end

  # Scan test files for fabricator calls
  def count_fabricator_usage(fabricator_name, regex)
    test_files.sum do |content|
      content.scan(regex).flatten.count
    end
  end

  def test_files
    @test_files ||= test_file_paths.map do |path|
      File.read(path)
    end
  end

  def test_file_paths
    Dir[TEST_DIR.join("**", "*.rb")]
  end

  def fabricate_regex(fabricator_name)
    /
      Fabricate                      # Fabricate
      (?:\.\w+)?                     # optional method call, including Fabricate.times(n, ...)
      \(\s*(?:\d*,)?\s*:#{fabricator_name}
    /x.freeze
  end
end